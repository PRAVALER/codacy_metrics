defmodule CodacyMetrics.CodacyClient do
  alias Finch.Response
  use Memoize
  use CodacyMetrics.Secrets

  @moduledoc """
    Query Codacy API and summarize metrics
  """

  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       "https://app.codacy.com" => [size: 100]
     }}
  end

  defmemo repositories_response do
    :get
    |> Finch.build(
      "https://app.codacy.com/api/v3/organizations/gh/#{@organization}/repositories?limit=100",
      [{"api-token", @api_token}]
    )
    |> Finch.request(__MODULE__)
  end

  def handle_repositories_response({:ok, %Response{body: body}}) do
    body
    |> Jason.decode!()
    |> case do
      %{"data" => data} -> Enum.map(data, & &1["name"])
      _ -> ""
    end
  end

  def repo_names do
    repositories_response() |> handle_repositories_response
  end

  defmemo repository_stats_response(repo_name) do
    IO.puts("Processing #{repo_name}...")

    :get
    |> Finch.build(
      "https://app.codacy.com/api/v3/analysis/organizations/gh/#{@organization}/repositories/#{
        repo_name
      }/commit-statistics?branch=master&days=360",
      [{"api-token", @api_token}]
    )
    |> Finch.request(__MODULE__)
  end

  def handle_repository_stats_response({:ok, %Response{body: body}}) do
    body
    |> Jason.decode!()
    |> case do
      %{"data" => data} -> data
      _ -> []
    end
  end

  def first_and_last(data) do
    [List.first(data), List.last(data)]
  end

  def reduce_by_month([]), do: []

  def reduce_by_month([d1 | rest]) do
    Enum.reduce(rest, [d1], fn item, [head | tail] ->
      if same_timestamp(item, head), do: [head | tail], else: [item | [head | tail]]
    end)
  end

  # s = CodacyMetrics.CodacyClient.all_repo_stats(& &1)
  # {:ok, %{"stats" => stat}} = List.first(s)
  # CodacyMetrics.CodacyClient.reduce_by_month(stat)

  def same_timestamp(%{"commitTimestamp" => d1}, %{"commitTimestamp" => d2}) do
    month(d1) === month(d2)
  end

  def month(commit_timestamp), do: String.slice(commit_timestamp, 0, 7)

  def all_repo_stats(list_agg_function \\ &reduce_by_month/1) do
    Task.async_stream(
      Enum.take(repo_names(), 1000),
      &repo_stats(&1, list_agg_function),
      timeout: 10_000
    )
    |> Enum.to_list()
  end

  def repo_stats(repo_name, agg_function \\ &reduce_by_month/1) do
    %{
      "stats" =>
        agg_function.(
          repository_stats_response(repo_name)
          |> handle_repository_stats_response
        ),
      "repo_name" => repo_name
    }
  end

  def repo_stats_evolution(metric) do
    Enum.map(all_repo_stats(), &metric_evolution(&1, metric))
  end

  def metric_evolution({:ok, data}, metric) do
    %{
      "repo_name" => data["repo_name"],
      "stats" =>
        Enum.into(
          Enum.map(data["stats"], fn d ->
            {month(d["commitTimestamp"]), d[metric]}
          end),
          %{}
        )
    }
  end

  def all_repos_evolution(metric) do
    IO.puts("Processing metric" <> metric <> "\n===============================")

    Enum.reduce(repo_stats_evolution(metric), %{}, fn repo, result ->
      Enum.reduce(repo["stats"], result, fn {month, value}, acc ->
        Map.update(acc, month, value, &((&1 || 0) + (value || 0)))
      end)
    end)
  end

  def coverage_evolution() do
    all_repos_coverage = repo_stats_evolution("coveragePercentage")
    all_repos_loc = repo_stats_evolution("numberLoc")

    Enum.reduce(all_repos_coverage, %{}, fn repo, final_result ->
      Enum.reduce(repo["stats"], final_result, coverage_reducer(repo, all_repos_loc))
    end)
  end

  def coverage_reducer(repo, all_repos_loc) do
    fn {month, coverage}, acc ->
      month_loc = Enum.find(all_repos_loc, fn item -> item["repo_name"] == repo["repo_name"] end)

      Map.update(
        acc,
        month,
        cov_map(coverage, month, month_loc),
        &%{
          "linesCovered" => &1["linesCovered"] + (coverage || 0) * month_loc["stats"][month],
          "loc" => &1["loc"] + month_loc["stats"][month]
        }
      )
    end
  end

  def cov_map(coverage, month, month_loc) do
    %{
      "linesCovered" => (coverage || 0) * month_loc["stats"][month],
      "loc" => month_loc["stats"][month]
    }
  end

  def all_metrics_evolution do
    Enum.map(all_metric_names(), &{&1, all_repos_evolution(&1)})
  end

  def all_metric_names,
    do: [
      "duplicationPercentage",
      "issuePercentage",
      "numberIssues",
      "numberFilesUncovered",
      "numberLoc",
      "techDebt",
      "totalComplexity",
      "coveragePercentage"
    ]
end

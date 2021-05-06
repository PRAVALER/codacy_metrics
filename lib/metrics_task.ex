defmodule Mix.Tasks.Metrics do
  use Mix.Task
  alias CodacyMetrics.CodacyClient

  @moduledoc """
    Task to print individual metrics
  """

  @shortdoc "MetricsTask prints the metric evolution, summing all projects"
  def run([arg1 | _]) do
    Mix.Task.run("run")
    IO.inspect(CodacyClient.all_repos_evolution(arg1))
  end
end

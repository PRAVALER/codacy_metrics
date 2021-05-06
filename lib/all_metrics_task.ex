defmodule Mix.Tasks.AllMetrics do
  use Mix.Task
  alias CodacyMetrics.CodacyClient
  @moduledoc """
    Task to print all metrics
  """
  @shortdoc "MetricsTask prints the metric evolution, summing all projects"
  def run(_) do
    Mix.Task.run("run")
    IO.inspect(CodacyClient.all_metrics_evolution())
  end
end

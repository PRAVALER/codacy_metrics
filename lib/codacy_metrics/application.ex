defmodule CodacyMetrics.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias CodacyMetrics.CodacyClient

  def start(_type, _args) do
    children = [CodacyClient.child_spec()]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CodacyMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

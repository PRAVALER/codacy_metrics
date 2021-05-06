defmodule CodacyMetrics.Secrets do
  @moduledoc """
    Put your secrets here!
  """
  defmacro __using__(_) do
    quote do
      @api_token ""
      @organization ""
    end
  end
end

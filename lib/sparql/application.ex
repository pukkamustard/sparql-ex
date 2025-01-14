defmodule SPARQL.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {SPARQL.ExtensionFunction.Registry, []}
    ]

    opts = [strategy: :one_for_one, name: SPARQL.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

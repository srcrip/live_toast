Mix.install([
  {:bandit, "~> 1.1"}
])

defmodule Router do
  @moduledoc false

  use Plug.Router

  def port, do: 8000
  def origin, do: "http://localhost:#{port()}"

  plug(Plug.Logger)

  plug(:match)
  plug(:dispatch)

  plug Plug.Static, at: "/docs", from: "doc", gzip: false

  match _ do
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header("location", "#{origin()}/docs/readme.html")
  end
end

bandit = {Bandit, plug: Router, scheme: :http, port: Router.port()}
{:ok, _} = Supervisor.start_link([bandit], strategy: :one_for_one)

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end

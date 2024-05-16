defmodule DemoWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use DemoWeb, :verified_routes

      import DemoWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn

      @endpoint DemoWeb.Endpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

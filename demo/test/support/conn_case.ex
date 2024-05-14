defmodule DemoWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint DemoWeb.Endpoint

      use DemoWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import DemoWeb.ConnCase
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

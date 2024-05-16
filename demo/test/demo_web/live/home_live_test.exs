defmodule DemoWeb.HomeLiveTest do
  @moduledoc false

  use DemoWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Demo Page" do
    test "renders correctly", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Live Toast"
      assert html =~ "A beautiful drop-in replacement for the Phoenix Flash system."
    end
  end

  describe "LiveToast.send_toast/7" do
    test "renders correctly", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      refute html =~ "This is a toast event."

      view
      |> element("button", "Info Toast")
      |> render_click() =~ "This is a toast event."
    end
  end
end

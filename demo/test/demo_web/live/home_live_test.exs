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

    # Note: This test tracks an issue I found after 0.6.2 with streams.
    # On this and prior versions, the flashes lived next to the toasts in the stream container.
    # This is invalid, and for some reason tests catch it but no runtime errors happen.
    # After this version they've been moved into their own container with display contents.
    test "clicking the flash button", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      refute html =~ "This is a flash message."

      assert view
             |> element("button", "Info Flash")
             |> render_click() =~
               "This is a flash message."
    end
  end

  describe "Localized demo page" do
    test "renders error toasts in English", %{conn: conn} do
      assert conn
             |> get(~p"/")
             |> html_response(200) =~
               "We can&#39;t find the internet"
    end

    test "renders error toasts in Spanish", %{conn: conn} do
      assert conn
             |> get(~p"/?locale=es")
             |> html_response(200) =~
               "Nosotros no podemos encontrar internet"
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

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
               Plug.HTML.html_escape("We can't find the internet")
    end

    test "renders error toasts in Spanish", %{conn: conn} do
      assert conn
             |> get(~p"/?locale=es")
             |> html_response(200) =~
               Plug.HTML.html_escape("Nosotros no podemos encontrar internet")
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

  describe "Recipes page" do
    test "renders dismiss by UUID recipe", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/recipes")

      assert html =~ "Dismiss Programmatically"
      assert html =~ "LiveToast.dismiss_toast/2"
      assert html =~ "LiveToast.dismiss/1"
      assert html =~ "Show Dismissible Toast"
      assert html =~ "Dismiss From Server"
    end

    test "renders pause timed toast recipe", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/recipes")

      assert html =~ "Pause Timed Toast"
      assert html =~ "Show 8-Second Toast"
      assert html =~ "View the demo source"

      view
      |> element("button", "Show 8-Second Toast")
      |> render_click()

      assert render(view) =~ "data-live-toast-remaining"
    end

    test "renders and exercises centered position recipe", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/recipes")

      assert html =~ "Centered Positions"
      assert html =~ "Show Top-Center Stack"
      assert html =~ "Show Bottom-Center Stack"

      view
      |> element("button", "Show Top-Center Stack")
      |> render_click()

      assert render(view) =~ ~s(data-corner="top_center")
      assert render(view) =~ "Top center stack item 4"

      view
      |> element("button", "Show Bottom-Center Stack")
      |> render_click()

      assert render(view) =~ ~s(data-corner="bottom_center")
      assert render(view) =~ "Bottom center stack item 4"
    end

    test "renders the custom connection notice recipe", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/recipes")

      assert html =~ "Customize Connection Notices"
      assert html =~ "Preview Custom Notice"
      assert html =~ ~s(data-live-toast-connection="client_error")
      assert html =~ ~s(data-connection-notice-id="client-error")
      assert html =~ "Connection interrupted"
      refute has_element?(view, "#client-error button[aria-label=close]")
    end

    test "supports both persistent duration forms", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/recipes")

      assert html =~ "Persistent Toasts"

      view
      |> element("button", "Show duration: 0")
      |> render_click()

      assert render(view) =~ ~s(id="toast-persistent-zero")
      assert render(view) =~ ~s(data-duration="0")

      view
      |> element("button", "Show :infinity")
      |> render_click()

      assert render(view) =~ ~s(id="toast-persistent-infinity")
      assert render(view) =~ ~s(data-duration="Infinity")

      view
      |> element("button", "Replace Persistent")
      |> render_click()

      assert render(view) =~ "Persistent toast replaced"

      view
      |> element("button", "Dismiss Persistent")
      |> render_click()

      assert_push_event(view, "live-toast-dismiss", %{
        id: "toast-persistent-infinity",
        uuid: "persistent-infinity"
      })
    end

    test "renders section links in the side navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/recipes")

      assert html =~ ~s(href="/#what-is-live-toast")
      assert html =~ ~s(href="/#duration")
      assert html =~ ~s(href="/recipes#showing-progress")
      assert html =~ ~s(href="/recipes#dismiss-programmatically")
      assert html =~ ~s(href="/recipes#pause-timed-toast")
      assert html =~ ~s(href="/recipes#centered-positions")
      assert html =~ ~s(href="/recipes#persistent-toasts")
      assert html =~ ~s(href="/recipes#connection-notifications")
    end
  end
end

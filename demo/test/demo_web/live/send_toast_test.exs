defmodule DemoWeb.SendToastTest do
  use DemoWeb.ConnCase

  import Phoenix.LiveViewTest

  defmodule TestLive do
    @moduledoc false

    use Phoenix.LiveView

    def mount(_params, _session, socket) do
      {:ok, socket}
    end

    def handle_event("send_info", _, socket) do
      LiveToast.send_toast(:info, "Info toast message", title: "Info Test")

      {:noreply, socket}
    end

    def handle_event("send_error", _, socket) do
      LiveToast.send_toast(:error, "Error toast message", title: "Error Test")

      {:noreply, socket}
    end

    def render(assigns) do
      ~H"""
      <LiveToast.toast_group
        flash={@flash}
        toasts_sync={assigns[:toasts_sync]}
        connected={assigns[:socket] != nil}
      />
      <div>
        <button phx-click="send_info">Send Info Toast</button>
        <button phx-click="send_error">Send Error Toast</button>
      </div>
      """
    end
  end

  describe "LiveToast.send_toast/3" do
    test "renders info toast", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLive)

      view
      |> element("button", "Send Info Toast")
      |> render_click() =~ "Success info message"
    end

    test "renders error toast", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLive)

      view
      |> element("button", "Send Error Toast")
      |> render_click() =~ "Error error message"
    end
  end
end

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

    def handle_event("send_persistent", _, socket) do
      uuid = LiveToast.send_toast(:info, "Persistent toast message", duration: 0)

      {:noreply, Phoenix.Component.assign(socket, :last_toast_uuid, uuid)}
    end

    def handle_event("dismiss_persistent", _, socket) do
      LiveToast.dismiss_toast(socket.assigns.last_toast_uuid)

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
        <button phx-click="send_persistent">Send Persistent Toast</button>
        <button phx-click="dismiss_persistent">Dismiss Persistent Toast</button>
      </div>
      """
    end
  end

  describe "LiveToast.send_toast/3" do
    test "renders info toast", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLive)

      view
      |> element("button", "Send Info Toast")
      |> render_click() =~ "Info toast message"
    end

    test "renders error toast", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLive)

      view
      |> element("button", "Send Error Toast")
      |> render_click() =~ "Error toast message"
    end

    test "dismisses a toast by UUID", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLive)

      view
      |> element("button", "Send Persistent Toast")
      |> render_click()

      view
      |> element("button", "Dismiss Persistent Toast")
      |> render_click()

      assert_push_event(view, "live-toast-dismiss", %{
        id: "toast-" <> uuid,
        uuid: uuid
      })

      assert uuid =~ ~r/^[0-9a-f-]{36}$/
    end
  end
end

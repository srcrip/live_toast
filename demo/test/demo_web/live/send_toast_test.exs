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
        connection_notifications={
          %{
            client_error: %{
              kind: :error,
              title: "Custom connection title",
              body: "Custom connection body"
            }
          }
        }
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

  defmodule CenteredPositionLive do
    @moduledoc false

    use Phoenix.LiveView

    def mount(_params, session, socket) do
      {:ok, Phoenix.Component.assign(socket, :corner, centered_corner(session["corner"]))}
    end

    def render(assigns) do
      ~H"""
      <LiveToast.toast_group
        flash={@flash}
        corner={@corner}
        toasts_sync={assigns[:toasts_sync]}
        connected={assigns[:socket] != nil}
      />
      """
    end

    defp centered_corner("bottom_center"), do: :bottom_center
    defp centered_corner(_corner), do: :top_center
  end

  describe "LiveToast.send_toast/3" do
    test "renders a persistent, non-dismissible configured connection notice", %{conn: conn} do
      {:ok, view, html} = live_isolated(conn, TestLive)

      assert html =~ ~s(data-live-toast-connection="client_error")
      assert html =~ ~s(data-duration="0")
      assert html =~ "Custom connection title"
      assert html =~ "Custom connection body"
      refute has_element?(view, "#client-error button[aria-label=close]")
    end

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

  describe "centered positioning" do
    for corner <- [:top_center, :bottom_center] do
      test "renders a live host at #{corner}", %{conn: conn} do
        {:ok, _view, html} =
          live_isolated(conn, CenteredPositionLive, session: %{"corner" => unquote(Atom.to_string(corner))})

        assert html =~ ~s(data-corner="#{unquote(Atom.to_string(corner))}")
        assert html =~ "left-1/2"
        assert html =~ unquote(if corner == :top_center, do: "top-0", else: "bottom-0")
      end
    end

    test "renders dead-view hosts at both centered positions" do
      Enum.each([:top_center, :bottom_center], fn corner ->
        html =
          render_component(&LiveToast.toast_group/1,
            flash: %{},
            connected: false,
            toasts_sync: [],
            corner: corner
          )

        assert html =~ ~s(data-corner="#{corner}")
        assert html =~ "left-1/2"
        assert html =~ if(corner == :top_center, do: "top-0", else: "bottom-0")
      end)
    end
  end
end

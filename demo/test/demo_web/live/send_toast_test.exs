defmodule DemoWeb.SendToastTest do
  use DemoWeb.ConnCase
  use Phoenix.Component

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

    def handle_event("send_metadata_toast", %{"has_icon" => has_icon}, socket) do
      LiveToast.send_toast(
        :info,
        "Metadata controls this custom component.",
        title: "Custom metadata",
        component: &metadata_toast/1,
        metadata: %{has_icon: has_icon == "true", reference: "receipt-123"},
        uuid: "metadata-toast"
      )

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
        <button phx-click="send_metadata_toast" phx-value-has_icon="true">
          Send Metadata Toast With Icon
        </button>
        <button phx-click="send_metadata_toast" phx-value-has_icon="false">
          Send Metadata Toast Without Icon
        </button>
      </div>
      """
    end

    defp metadata_toast(assigns) do
      ~H"""
      <div>
        <span :if={Map.get(@metadata, :has_icon, true)} data-metadata-icon>Icon</span>
        <p data-part="title">{@title}</p>
        <p>{@body}</p>
        <span data-reference={@metadata.reference}></span>
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

  defmodule DefaultComponentLive do
    @moduledoc false

    use Phoenix.LiveView

    def mount(_params, _session, socket), do: {:ok, socket}

    def handle_event("send_default", _, socket) do
      LiveToast.send_toast(:info, "Rendered by the host default.", uuid: "component-precedence")

      {:noreply, socket}
    end

    def handle_event("send_override", _, socket) do
      LiveToast.send_toast(:info, "Rendered by the per-toast override.",
        component: &override_toast/1,
        uuid: "component-precedence"
      )

      {:noreply, socket}
    end

    def render(assigns) do
      ~H"""
      <LiveToast.toast_group
        flash={@flash}
        toasts_sync={assigns[:toasts_sync]}
        connected={assigns[:socket] != nil}
        toast_component_fn={&default_toast/1}
      />
      <button phx-click="send_default">Send Default Component Toast</button>
      <button phx-click="send_override">Send Override Component Toast</button>
      """
    end

    defp default_toast(assigns) do
      ~H"""
      <p data-toast-renderer="default">{@body}</p>
      """
    end

    defp override_toast(assigns) do
      ~H"""
      <p data-toast-renderer="override">{@body}</p>
      """
    end
  end

  defmodule ConnectionNotificationLive do
    @moduledoc false

    use Phoenix.LiveView

    def mount(_params, _session, socket), do: {:ok, socket}

    def render(assigns) do
      ~H"""
      <LiveToast.toast_group
        flash={@flash}
        connected={assigns[:socket] != nil}
        toasts_sync={assigns[:toasts_sync]}
        connection_notifications={
          %{
            client_error: %{kind: :info, title: "Custom title", body: "Custom body"}
          }
        }
      >
        <:client_error :let={notice}>
          <div id="custom-client-notice" data-notice-id={notice.id} data-notice-kind={notice.kind}>
            <span>{notice.title}</span>
            <span>{notice.body}</span>
          </div>
        </:client_error>
      </LiveToast.toast_group>
      """
    end
  end

  attr :flash, :map, required: true
  attr :toasts_sync, :list, required: true

  defp dead_connection_notification_host(assigns) do
    ~H"""
    <LiveToast.toast_group
      flash={@flash}
      connected={false}
      toasts_sync={@toasts_sync}
      connection_notifications={%{server_error: %{title: "Offline", body: "Trying again"}}}
    >
      <:server_error :let={notice}>
        <div id="custom-server-notice" data-notice-id={notice.id}>
          <span>{notice.title}</span>
          <span>{notice.body}</span>
        </div>
      </:server_error>
    </LiveToast.toast_group>
    """
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

    test "passes application metadata to a custom toast component", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLive)

      view
      |> element("button", "Send Metadata Toast With Icon")
      |> render_click()

      html = render(view)

      assert html =~ ~s(data-metadata-icon)
      assert html =~ ~s(data-reference="receipt-123")

      view
      |> element("button", "Send Metadata Toast Without Icon")
      |> render_click()

      html = render(view)

      refute html =~ ~s(data-metadata-icon)
      assert html =~ ~s(data-reference="receipt-123")
    end

    test "uses the host default component unless a toast supplies an override", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, DefaultComponentLive)

      view
      |> element("button", "Send Default Component Toast")
      |> render_click()

      html = render(view)

      assert html =~ ~s(data-toast-renderer="default")
      assert html =~ "Rendered by the host default."

      view
      |> element("button", "Send Override Component Toast")
      |> render_click()

      html = render(view)

      assert html =~ ~s(data-toast-renderer="override")
      assert html =~ "Rendered by the per-toast override."
      refute html =~ ~s(data-toast-renderer="default")
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

  describe "connection notification slots" do
    test "renders custom client notice content in a live host", %{conn: conn} do
      {:ok, view, html} = live_isolated(conn, ConnectionNotificationLive)

      assert html =~ ~s(data-live-toast-connection="client_error")
      assert html =~ ~s(data-notice-id="client-error")
      assert html =~ ~s(data-notice-kind="info")
      assert html =~ "Custom title"
      assert html =~ "Custom body"
      refute has_element?(view, "#client-error button[aria-label=close]")
    end

    test "renders custom server notice content in a dead host" do
      html =
        render_component(&dead_connection_notification_host/1,
          flash: %{},
          toasts_sync: []
        )

      assert html =~ ~s(data-live-toast-connection="server_error")
      assert html =~ ~s(data-notice-id="server-error")
      assert html =~ "Offline"
      assert html =~ "Trying again"
      refute html =~ ~s(aria-label="close")
    end
  end
end

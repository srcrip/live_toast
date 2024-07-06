defmodule LiveToast.LiveComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  alias LiveToast.Components

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> stream_configure(:toasts,
        dom_id: fn %LiveToast{uuid: id} ->
          "toast-#{id}"
        end
      )
      |> stream(:toasts, [])
      |> assign(:toast_count, 0)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {toasts, assigns} = Map.pop(assigns, :toasts)
    toasts = toasts || []

    socket =
      socket
      |> assign(assigns)
      |> stream(:toasts, toasts)
      |> assign(:toast_count, socket.assigns.toast_count + length(toasts))

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    default_classes =
      "fixed z-50 max-h-screen w-full p-4 md:max-w-[420px] pointer-events-none grid origin-center"

    class =
      case assigns[:corner] do
        :bottom_left ->
          "#{default_classes} items-end bottom-0 left-0 flex-col-reverse sm:top-auto"

        :bottom_right ->
          "#{default_classes} items-end bottom-0 right-0 flex-col-reverse sm:top-auto"

        :top_left ->
          "#{default_classes} items-start top-0 left-0 flex-col sm:bottom-auto"

        :top_right ->
          "#{default_classes} items-start top-0 right-0 flex-col sm:bottom-auto"
      end

    assigns = assign(assigns, :class, class)

    ~H"""
    <div
      id={assigns[:id] || "toast-group"}
      class={[
        @class
      ]}
    >
      <div class="contents" id="toast-group-stream" phx-update="stream">
        <Components.toast
          :for={
            {dom_id,
             %LiveToast{
               kind: k,
               msg: body,
               title: title,
               icon: icon,
               action: action,
               duration: duration,
               component: component
             }} <- @streams.toasts
          }
          id={dom_id}
          data-count={@toast_count}
          duration={duration}
          kind={k}
          class_fn={@toast_class_fn}
          component={component}
          icon={icon}
          action={action}
          corner={@corner}
          title={
            if title do
              title
            else
              nil
            end
          }
          target={@myself}
        >
          <%= body %>
        </Components.toast>
      </div>

      <Components.flashes f={@f} corner={@corner} toast_class_fn={@toast_class_fn} kinds={@kinds} />
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear", %{"id" => "toast-" <> uuid}, socket) do
    socket =
      socket
      |> stream_delete_by_dom_id(:toasts, "toast-#{uuid}")
      |> assign(:toast_count, socket.assigns.toast_count - 1)

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear", _payload, socket) do
    # non matches are not unexpected, because the user may
    # have dismissed the toast before the animation ended.
    {:noreply, socket}
  end
end

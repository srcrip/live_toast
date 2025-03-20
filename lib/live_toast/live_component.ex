defmodule LiveToast.LiveComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  alias LiveToast.Components
  alias LiveToast.Utility

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
    # todo: make sure this works when doing multiple toasts at once. even tho thats unlikely.
    # handling of synchronous toasts when calling put_toast
    # basically, we need to read assigns["toasts_sync"], to see if there was a new toast popped on from put_toast.
    # If there was, we need to look for a corresponding flash message (with the same kind and message) and remove it.
    sync_toasts = Map.get(assigns, :toasts_sync, [])

    sync_toast =
      if sync_toasts && sync_toasts != [] do
        List.first(sync_toasts)
      else
        %{}
      end

    flash_map = assigns[:f]

    sync_toast_kind = Map.get(sync_toast, :kind, nil)

    sync_toast_kind =
      if is_atom(sync_toast_kind) do
        Atom.to_string(sync_toast_kind)
      end

    f =
      flash_map[sync_toast_kind]

    socket =
      if f && f == Map.get(sync_toast, :msg) do
        {toasts, assigns} = Map.pop(assigns, :toasts)
        toasts = toasts || []
        toasts = [sync_toast | toasts]

        new_f = put_in(assigns[:f][sync_toast_kind], nil)
        assigns = Map.put(assigns, :f, new_f)

        socket
        |> assign(assigns)
        |> stream(:toasts, toasts)
        |> assign(:toast_count, socket.assigns.toast_count + length(toasts))
        # instead of clearing flash here, we jsut send a message to the frontend to do it.
        #  The advantage is this makes it work properly even across a navigation.
        |> push_event("clear-flash", %{key: sync_toast.kind})
      else
        {toasts, assigns} = Map.pop(assigns, :toasts)
        toasts = toasts || []

        socket
        |> assign(assigns)
        |> stream(:toasts, toasts)
        |> assign(:toast_count, socket.assigns.toast_count + length(toasts))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={assigns[:id] || "toast-group"} class={@group_class_fn.(assigns)}>
      <div class="contents" id="toast-group-stream" phx-update="stream">
        <Components.toast
          :for={
            {dom_id,
             %LiveToast{
               kind: k,
               msg: msg,
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
          toast_class_fn={@toast_class_fn}
          component={component}
          icon={icon}
          action={action}
          corner={@corner}
          title={if title, do: Utility.translate(title), else: nil}
          target={@myself}
        >
          {Utility.translate(msg)}
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

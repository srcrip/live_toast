defmodule LiveToast.LiveComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  alias LiveToast.Components
  alias LiveToast.Utility

  @client_toast_option_keys ~w(duration metadata title)

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
    dismiss_uuid = Map.get(assigns, :dismiss_uuid)

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

    sync_toast_kind = Map.get(sync_toast, :kind)

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

    socket =
      if dismiss_uuid do
        push_event(socket, "live-toast-dismiss", %{
          id: "toast-#{dismiss_uuid}",
          uuid: dismiss_uuid
        })
      else
        socket
      end

    {:ok, socket}
  end

  # todo: if someone really wants it, we can implement the internally used `delay` option here.

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div
      id={assigns[:id] || "toast-group"}
      phx-hook="LiveToast"
      phx-target={@myself}
      data-live-toast-group="true"
      class={@group_class_fn.(assigns)}
    >
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
               metadata: metadata,
               duration: duration,
               uuid: uuid,
               component: component
             }} <- @streams.toasts
          }
          id={dom_id}
          uuid={uuid}
          data-count={@toast_count}
          duration={duration}
          kind={k}
          toast_class_fn={@toast_class_fn}
          component={component || @toast_component_fn}
          icon={icon}
          action={action}
          metadata={metadata}
          corner={@corner}
          title={if title, do: Utility.translate(title), else: nil}
          target={@myself}
        >
          {Utility.translate(msg)}
        </Components.toast>
      </div>

      <Components.flashes
        f={@f}
        corner={@corner}
        flash_duration={@flash_duration}
        toast_class_fn={@toast_class_fn}
        client_error_delay={@client_error_delay}
        connection_notifications={@connection_notifications}
        client_error={@client_error}
        server_error={@server_error}
        kinds={@kinds}
      />
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

  @impl Phoenix.LiveComponent
  def handle_event("add_toast", %{"kind" => kind, "message" => message} = payload, socket) do
    with {:ok, toast_kind} <- client_toast_kind(kind, socket.assigns.kinds),
         {:ok, toast_message} <- client_toast_message(message),
         {:ok, toast_options} <- client_toast_options(Map.get(payload, "options", %{})) do
      LiveToast.send_toast(toast_kind, toast_message, Keyword.put(toast_options, :container_id, socket.assigns.id))
    end

    {:noreply, socket}
  end

  def handle_event("add_toast", _payload, socket), do: {:noreply, socket}

  defp client_toast_kind(kind, kinds) when is_binary(kind) do
    case Enum.find(kinds, &(Atom.to_string(&1) == kind)) do
      nil -> :error
      toast_kind -> {:ok, toast_kind}
    end
  end

  defp client_toast_kind(_kind, _kinds), do: :error

  defp client_toast_message(message) when is_binary(message), do: {:ok, message}
  defp client_toast_message(_message), do: :error

  defp client_toast_options(options) when is_map(options) do
    options
    |> Map.take(@client_toast_option_keys)
    |> Enum.reduce_while({:ok, []}, fn
      {"title", title}, {:ok, parsed_options} when is_binary(title) ->
        {:cont, {:ok, [{:title, title} | parsed_options]}}

      {"metadata", metadata}, {:ok, parsed_options} when is_map(metadata) ->
        {:cont, {:ok, [{:metadata, metadata} | parsed_options]}}

      {"duration", duration}, {:ok, parsed_options} when is_integer(duration) and duration >= 0 ->
        {:cont, {:ok, [{:duration, duration} | parsed_options]}}

      {"duration", "infinity"}, {:ok, parsed_options} ->
        {:cont, {:ok, [{:duration, :infinity} | parsed_options]}}

      _option, _result ->
        {:halt, :error}
    end)
  end

  defp client_toast_options(_options), do: :error
end

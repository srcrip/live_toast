defmodule LiveToast do
  @moduledoc """
  LiveComponent for displaying toast messages.
  """

  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  @enforce_keys [:kind, :msg]
  defstruct [
    :kind,
    :msg,
    :title,
    :icon,
    :action,
    :component,
    :duration,
    :container_id,
    :uuid
  ]

  @typedoc "Instance of a toast message."
  @type t() :: %__MODULE__{
          kind: atom(),
          msg: binary(),
          title: binary() | nil,
          icon: (map() -> binary()) | nil,
          action: (map() -> binary()) | nil,
          component: (map() -> binary()) | nil,
          duration: non_neg_integer() | nil,
          container_id: binary() | nil,
          uuid: Ecto.UUID.t() | nil
        }

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
  def handle_event("clear", %{"id" => "toast-" <> uuid}, socket) do
    socket =
      socket
      |> stream_delete_by_dom_id(:toasts, "toast-#{uuid}")
      |> assign(:toast_count, socket.assigns.toast_count - 1)

    {:noreply, socket}
  end

  def handle_event("clear", _payload, socket) do
    # non matches are not unexpected, because the user may
    # have dismissed the toast before the animation ended.
    {:noreply, socket}
  end

  @doc "Merges a new toast message into the current toast list."
  @spec send_toast(LiveToast.t()) :: Ecto.UUID.t()
  def send_toast(kind, msg) do
    send_toast(%LiveToast{kind: kind, msg: msg})
  end

  def send_toast(%LiveToast{} = toast) do
    container_id = toast.container_id || "toast-group"
    uuid = toast.uuid || Ecto.UUID.generate()

    toast =
      struct!(toast, container_id: container_id, uuid: uuid)

    Phoenix.LiveView.send_update(__MODULE__, id: container_id, toasts: [toast])

    uuid
  end

  def put_toast(%Plug.Conn{} = conn, kind, msg) do
    Phoenix.Controller.put_flash(conn, kind, msg)
  end

  def put_toast(%Plug.Conn{} = conn, %LiveToast{kind: kind, msg: msg}) do
    Phoenix.Controller.put_flash(conn, kind, msg)
  end

  def put_toast(%Socket{} = socket, %LiveToast{} = toast) do
    send_toast(toast)

    socket
  end

  def put_toast(%Socket{} = socket, kind, msg) do
    send_toast(%LiveToast{kind: kind, msg: msg})

    socket
  end

  @doc """
  Implement your own function to override the class of the toasts.

  Example:
  ```elixir
  defmodule MyModule do
    def toast_class_fn(assigns) do
      [
        "group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-4 shadow-lg border col-start-1 col-end-1 row-start-1 row-end-2",
        if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
        assigns[:kind] == :info && " bg-white text-black",
        assigns[:kind] == :error && "!text-red-700 !bg-red-100 border-red-200"
      ]
    end
  end

  # use it in your layout:
  # <LiveToast.toast_group flash={@flash} connected={assigns[:socket] != nil} toast_class_fn={MyModule.toast_class_fn/1} />
  ```
  """
  def toast_class_fn(assigns) do
    [
      "group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-4 shadow-lg border col-start-1 col-end-1 row-start-1 row-end-2",
      if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
      assigns[:kind] == :info && " bg-white text-black",
      assigns[:kind] == :error && "!text-red-700 !bg-red-100 border-red-200"
    ]
  end

  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "toast-group", doc: "the optional id of flash container")
  attr(:connected, :boolean, default: false, doc: "whether we're in a liveview or not")

  attr(:corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :top_right,
    doc: "the corner to display the toasts"
  )

  attr(:toast_class_fn, :any,
    default: &__MODULE__.toast_class_fn/1,
    doc: "function to override the look of the toasts"
  )

  @doc """
  toast_group/1 is just a small Phoenix.Component wrapper around the LiveComponent for toasts.
  You can use the LiveComponent directly if you prefer, this is just a convenience.
  """
  def toast_group(assigns) do
    ~H"""
    <.live_component
      :if={@connected}
      id={@id}
      module={__MODULE__}
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      f={@flash}
    />
    <.flash_group
      :if={!@connected}
      id={@id}
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      flash={@flash}
    />
    """
  end

  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "toast-group", doc: "the optional id of flash container")

  attr(:corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :top_right,
    doc: "the corner to display the toasts"
  )

  attr(:toast_class_fn, :any,
    default: &__MODULE__.toast_class_fn/1,
    doc: "function to override the look of the toasts"
  )

  # Used to render flashes-only on regular non-LV pages.
  defp flash_group(assigns) do
    # todo: move this to a common implementation
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
    <div id={assigns[:id] || "flash-group"} class={@class}>
      <.flashes f={@flash} corner={@corner} toast_class_fn={@toast_class_fn} />
    </div>
    """
  end

  attr(:f, :map, required: true, doc: "the map of flash messages")

  attr(:corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :top_right,
    doc: "the corner to display the toasts"
  )

  attr(:toast_class_fn, :any,
    default: &__MODULE__.toast_class_fn/1,
    doc: "function to override the look of the toasts"
  )

  defp flashes(assigns) do
    ~H"""
    <.toast
      corner={@corner}
      class_fn={@toast_class_fn}
      duration={0}
      kind={:info}
      title="Info"
      phx-update="ignore"
      flash={@f}
    />
    <.toast
      corner={@corner}
      class_fn={@toast_class_fn}
      duration={0}
      kind={:error}
      title="Error"
      phx-update="ignore"
      flash={@f}
    />

    <.toast
      corner={@corner}
      class_fn={@toast_class_fn}
      id="client-error"
      kind={:error}
      title="We can't find the internet"
      phx-update="ignore"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Attempting to reconnect
      <.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
    </.toast>

    <.toast
      corner={@corner}
      class_fn={@toast_class_fn}
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-update="ignore"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
    </.toast>
    """
  end

  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")
  attr(:target, :any, default: nil, doc: "the target for the phx-click event")

  attr(:duration, :integer,
    default: 6000,
    doc: "the time in milliseconds before the message is automatically dismissed"
  )

  attr(:class_fn, :any,
    required: true,
    doc: "function to override the look of the toasts"
  )

  attr(:corner, :atom, required: true, doc: "the corner to display the toasts")

  attr(:icon, :any, default: nil, doc: "the optional icon to render in the flash message")
  attr(:action, :any, default: nil, doc: "the optional action to render in the flash message")
  attr(:component, :any, default: nil, doc: "the optional component to render the flash message")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  defp toast(assigns) do
    assigns =
      assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      phx-hook="LiveToast"
      data-duration={@duration}
      data-corner={@corner}
      class={@class_fn.(assigns)}
      {@rest}
    >
      <%= if @component do %>
        <%= @component.(Map.merge(assigns, %{body: msg})) %>
      <% else %>
        <div class="grow flex flex-col items-start justify-center">
          <p
            :if={@title}
            data-part="title"
            class={[
              if(@icon, do: "mb-2", else: ""),
              "flex items-center text-sm font-semibold leading-6"
            ]}
          >
            <%= if @icon do %>
              <%= @icon.(assigns) %>
            <% end %>
            <%= @title %>
          </p>
          <p class="text-sm leading-5">
            <%= msg %>
          </p>
        </div>

        <%= if @action do %>
          <%= @action.(assigns) %>
        <% end %>
      <% end %>
      <!--
        todo
        just get rid of close button?
      -->
      <button
        type="button"
        class="
        group-has-[[data-part='title']]/toast:absolute
        right-[5px] top-[5px] rounded-md p-[5px] text-black/50 transition-opacity  hover:text-black focus:opacity-100 focus:outline-none focus:ring-1 group group-hover:opacity-100"
        aria-label="close"
        {
        if Phoenix.Flash.get(@flash, @kind),
        do: ["phx-click": 
          JS.dispatch("flash-leave", to: "##{@id}")
          |> JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")],
        else: [
          "phx-target": @target,
          "phx-click": "clear",
          "phx-value-id": @id
        ]
          }
      >
        <.svg name="hero-x-mark-solid" class="h-[14px] w-[14px] opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  # todo: fix bug where refreshing causes the disconnected toast to show

  @impl Phoenix.LiveComponent
  def render(assigns) do
    # flex
    # "fixed z-50 max-h-screen w-full p-4 md:max-w-[420px] pointer-events-auto z-50 pointer-events-none fixed gap-2"
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
      phx-update="stream"
    >
      <.toast
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
      </.toast>

      <.flashes f={@f} corner={@corner} toast_class_fn={@toast_class_fn} />
    </div>
    """
  end

  attr(:name, :string, required: true, doc: "the name of the icon")
  attr(:rest, :global, doc: "other html attributes")

  defp svg(%{name: "hero-x-mark-solid"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
      data-slot="icon"
      {@rest}
    >
      <path
        fill-rule="evenodd"
        d="M5.47 5.47a.75.75 0 0 1 1.06 0L12 10.94l5.47-5.47a.75.75 0 1 1 1.06 1.06L13.06 12l5.47 5.47a.75.75 0 1 1-1.06 1.06L12 13.06l-5.47 5.47a.75.75 0 0 1-1.06-1.06L10.94 12 5.47 6.53a.75.75 0 0 1 0-1.06Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  defp svg(%{name: "hero-arrow-path"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
      data-slot="icon"
      {@rest}
    >
      <path
        fill-rule="evenodd"
        d="M4.755 10.059a7.5 7.5 0 0 1 12.548-3.364l1.903 1.903h-3.183a.75.75 0 1 0 0 1.5h4.992a.75.75 0 0 0 .75-.75V4.356a.75.75 0 0 0-1.5 0v3.18l-1.9-1.9A9 9 0 0 0 3.306 9.67a.75.75 0 1 0 1.45.388Zm15.408 3.352a.75.75 0 0 0-.919.53 7.5 7.5 0 0 1-12.548 3.364l-1.902-1.903h3.183a.75.75 0 0 0 0-1.5H2.984a.75.75 0 0 0-.75.75v4.992a.75.75 0 0 0 1.5 0v-3.18l1.9 1.9a9 9 0 0 0 15.059-4.035.75.75 0 0 0-.53-.918Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  defp show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      display: "flex",
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  defp hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end

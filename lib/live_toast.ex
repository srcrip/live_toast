defmodule LiveToast do
  @moduledoc """
  LiveComponent for displaying toast messages.
  """

  use Phoenix.Component

  alias LiveToast.Components
  alias Phoenix.LiveView

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

  @typedoc "Instance of a toast message. Mainly used internally."
  @opaque t() :: %__MODULE__{
            kind: atom(),
            msg: binary(),
            title: binary() | nil,
            icon: component_fn() | nil,
            action: component_fn() | nil,
            component: component_fn() | nil,
            duration: non_neg_integer() | nil,
            container_id: binary() | nil,
            uuid: Ecto.UUID.t() | nil
          }

  @typedoc "`Phoenix.Component` that renders a part of the toast message."
  @type component_fn() :: (map() -> Phoenix.LiveView.Rendered.t())

  @typedoc "Set of public options to augment the default toast behavior."
  @type option() ::
          {:title, binary() | nil}
          | {:icon, component_fn() | nil}
          | {:action, component_fn() | nil}
          | {:component, component_fn() | nil}
          | {:duration, non_neg_integer() | nil}
          | {:container_id, binary() | nil}
          | {:uuid, Ecto.UUID.t() | nil}

  @doc """
  Send a new toast message to the LiveToast component.

  Returns the UUID of the new toast message. This UUID can be passed back
  to another call to `send_toast/3` to update the properties of an existing toast.

  ## Examples

      iex> send_toast(:info, "Thank you for logging in!", title: "Welcome")
      "00c90156-56d1-4bca-a9e2-6353d49c974a"

  """
  @spec send_toast(atom(), binary(), [option()]) :: Ecto.UUID.t()
  def send_toast(kind, msg, options \\ []) do
    container_id = options[:container_id] || "toast-group"
    uuid = options[:uuid] || Ecto.UUID.generate()

    toast = %LiveToast{
      kind: kind,
      msg: msg,
      title: options[:title],
      icon: options[:icon],
      action: options[:action],
      component: options[:component],
      duration: options[:duration],
      container_id: container_id,
      uuid: uuid
    }

    LiveView.send_update(LiveToast.LiveComponent, id: container_id, toasts: [toast])

    uuid
  end

  @doc """
  Helper function around `send_toast/3` that is useful in pipelines.
  Can be used in a pipeline with either Plug.Conn or LiveView.Socket.

  Unlike `send_toast/3`, this function does not expose the UUID of the
  new toast, so if you need to update the toast after popping it onto
  the list, you should use `send_toast/3` directly.

  ## Examples

      iex> put_toast(conn, :info, "Thank you for logging in!")
      %Plug.Conn{...}

      iex> put_toast(socket, :info, "Thank you for logging in!")
      %LiveView.Socket{...}

  """
  def put_toast(conn_or_socket, kind, msg, options \\ [])

  @spec put_toast(Plug.Conn.t(), atom(), binary(), [option()]) :: Plug.Conn.t()
  def put_toast(%Plug.Conn{} = conn, kind, msg, _options) do
    Phoenix.Controller.put_flash(conn, kind, msg)
  end

  @spec put_toast(LiveView.Socket.t(), atom(), binary(), [option()]) :: LiveView.Socket.t()
  def put_toast(%LiveView.Socket{} = socket, kind, msg, options) do
    send_toast(kind, msg, options)

    socket
  end

  @doc """
  Implement your own function to override the class of the toasts.

  ## Examples:

      defmodule MyModule do
        def toast_class_fn(assigns) do
          [
            # base classes
            "group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-4 shadow-lg border col-start-1 col-end-1 row-start-1 row-end-2",
            # start hidden if javascript is enabled
            "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled){[data-phx-main]_&}]:opacity-100",
            # used to hide the disconnected flashes
            if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
            # override styles per severity
            assigns[:kind] == :info && "bg-white text-black",
            assigns[:kind] == :error && "!text-red-700 !bg-red-100 border-red-200"
          ]

        end
      end

  Then use it in your layout:

      <LiveToast.toast_group flash={@flash} connected={assigns[:socket] != nil} toast_class_fn={MyModule.toast_class_fn/1} />
  """
  def toast_class_fn(assigns) do
    [
      # base classes
      "bg-white group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-4 shadow-lg border col-start-1 col-end-1 row-start-1 row-end-2",
      # start hidden if javascript is enabled
      "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled){[data-phx-main]_&}]:opacity-100",
      # used to hide the disconnected flashes
      if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
      # override styles per severity
      assigns[:kind] == :info && "text-black",
      assigns[:kind] == :error && "!text-red-700 !bg-red-100 border-red-200"
    ]
  end

  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "toast-group", doc: "the optional id of flash container")
  attr(:connected, :boolean, default: false, doc: "whether we're in a liveview or not")
  attr(:kinds, :list, default: [:info, :error], doc: "the valid severity level kinds")

  attr(:corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :bottom_right,
    doc: "the corner to display the toasts"
  )

  attr(:toast_class_fn, :any,
    default: &__MODULE__.toast_class_fn/1,
    doc: "function to override the look of the toasts"
  )

  @doc """
  Renders a group of toasts and flashes.

  Replace your `flash_group` with this component in your layout.
  """
  def toast_group(assigns) do
    ~H"""
    <.live_component
      :if={@connected}
      id={@id}
      module={LiveToast.LiveComponent}
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      f={@flash}
      kinds={@kinds}
    />
    <Components.flash_group
      :if={!@connected}
      id={@id}
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      flash={@flash}
      kinds={@kinds}
    />
    """
  end
end

defmodule LiveToast do
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS

  @moduledoc """
  LiveComponent for displaying toast messages.
  """

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(:toasts, [])

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {toasts, assigns} = Map.pop(assigns, :toasts)
    toasts = toasts || []

    socket =
      socket
      |> assign(assigns)
      |> update(:toasts, fn ts -> ts ++ toasts end)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear", %{"id" => "toast-" <> index}, socket) do
    index = String.to_integer(index)

    toasts =
      socket.assigns.toasts
      |> Enum.with_index()
      |> Enum.reject(fn {_, i} -> index == i end)
      |> Enum.map(fn {t, _} -> t end)

    socket =
      socket
      |> assign(:toasts, toasts)

    {:noreply, socket}
  end

  def handle_event("clear", _payload, socket) do
    # non matches are not unexpected, because the user may
    # have dismissed the toast before the animation ended.
    {:noreply, socket}
  end

  def handle_event("add_toast", _params, socket) do
    socket =
      socket
      |> assign(
        :toasts,
        socket.assigns.toasts ++ [{:info, "Welcome to Elixir Courses"}]
      )

    {:noreply, socket}
  end

  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "toast-group", doc: "the optional id of flash container")

  def toast_group(assigns) do
    ~H"""
    <.live_component id={@id} module={__MODULE__} f={@flash} />
    """
  end

  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")
  attr(:target, :any, required: false, doc: "the target for the phx-click event")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def toast(assigns) do
    assigns =
      assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      phx-hook="LiveToast"
      class={[
        "mt-2 mr-2 w-80 sm:w-96 z-50 p-2 rounded-md shadow origin-center overflow-hidden",
        assigns.rest[:hidden] != true && "flex",
        @kind == :info && "text-gray-800 bg-gray-50 dark:bg-gray-800 dark:text-gray-300",
        @kind == :success && "text-green-800 bg-green-50 dark:bg-gray-800 dark:text-green-400",
        @kind == :error && "text-red-800 bg-red-50 dark:bg-gray-800 dark:text-red-400"
      ]}
      {@rest}
    >
      <div class="pl-2 grow flex flex-col gap-1 items-start justify-center">
        <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
          <%= @title %>
        </p>
        <p class="text-sm leading-5">
          <%= msg %>
        </p>
      </div>
      <button
        type="button"
        class="flex place-self-start group p-1"
        aria-label="close"
        {
    if Phoenix.Flash.get(@flash, @kind),
    do: ["phx-click": JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")],
    else: [
    "phx-target": assigns[:target],
    "phx-click": "clear",
    "phx-value-id": @id
    ]
    }
      >
        <.svg name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={assigns[:id] || "toast-group"} class="z-50 fixed right-2 top-2 ">
      <.toast kind={:info} title="Success!" flash={@f} />
      <.toast kind={:error} title="Error!" flash={@f} />

      <.toast
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        Attempting to reconnect
        <.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
      </.toast>

      <.toast
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        Hang in there while we get back on track
        <.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
      </.toast>

      <.toast
        :for={{{k, t}, index} <- Enum.with_index(@toasts)}
        kind={k}
        title={
          case k do
            :info -> "Info"
            :success -> "Success"
            :error -> "Error"
          end
        }
        target={@myself}
        id={"toast-#{index}"}
      >
        <%= t %>
      </.toast>
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
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  defp hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end

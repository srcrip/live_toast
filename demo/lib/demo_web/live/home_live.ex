defmodule DemoWeb.HomeLive do
  use DemoWeb, :live_view

  alias Phoenix.LiveView.JS

  require Logger

  embed_templates("tabs/*")

  @default_settings %{
    "corner" => "bottom_right",
    "icon" => nil,
    "action" => nil
  }

  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:settings, @default_settings)
      |> apply_action(socket.assigns.live_action)

    Logger.info("Mounted")

    {:noreply, socket}
  end

  def handle_event("change_settings", payload, socket) do
    socket =
      socket
      |> assign(:settings, Map.merge(socket.assigns.settings, payload))

    {:noreply, socket}
  end

  def handle_event("update_toast", _payload, socket) do
    body = [
      "This is a toast event.",
      "Different toast event.",
      "This is another toast event.",
      "Hello, world!"
    ]
    |> Enum.random()

    uuid = "this-is-a-uuid"

    %LiveToast{
      kind: :info,
      msg: body,
      title: nil,
      icon: nil,
      action: nil,
      duration: nil,
      component: nil,
      container_id: "toast-group",
      uuid: uuid
    }
    |> LiveToast.send_toast()

    {:noreply, socket}
  end

  def handle_event("show_progress", _payload, socket) do
    uuid = "show-progress"

    %LiveToast{
      kind: :info,
      msg: "Uploading...",
      title: "Show Progress",
      icon: &loading_icon/1,
      action: nil,
      duration: nil,
      component: nil,
      container_id: "toast-group",
      uuid: uuid
    }
    |> LiveToast.send_toast()

    Process.send_after(self(), :progress, 3000)

    {:noreply, socket}
  end

  def handle_event("toast", payload, socket) do
    kind = Map.get(payload, "kind", "info")
    title = Map.get(payload, "title")
    body = Map.get(payload, "body", "This is a toast event.")

    component =
      case Map.get(payload, "component") do
        "custom" -> &custom_toast/1
        "congrats" -> &congrats_toast/1
        "everything" -> &everything_toast/1
        _ -> nil
      end

    icon =
      case Map.get(socket.assigns.settings, "icon") do
        "example" -> &example_icon/1
        nil -> nil
      end

    action =
      case Map.get(socket.assigns.settings, "action") do
        "example" -> &example_action/1
        nil -> nil
      end

    duration =
      case Map.get(payload, "duration", nil) do
        d when is_integer(d) -> d
        d when is_binary(d) -> String.to_integer(d)
        _ -> nil
      end

    %LiveToast{
      kind: case kind do
        "info" -> :info
        "error" -> :error
      end,
      msg: body,
      title: title,
      icon: icon,
      action: action,
      duration: duration,
      component: component,
      container_id: "toast-group"
    }
    |> LiveToast.send_toast()

    {:noreply, socket}
  end

  def handle_event("flash", %{"kind" => kind}, socket) do
    socket =
      socket
      |> put_flash(
        case kind do
          "info" -> :info
          "error" -> :error
        end,
        "this is  a flash"
      )

    {:noreply, socket}
  end

  def handle_event(event, _payload, socket) do
    IO.puts("Unhandled event: #{event}")
    {:noreply, socket}
  end

  def handle_info(:progress, socket) do
    uuid = "show-progress"

    %LiveToast{
      kind: :info,
      msg: "Still going, please wait a little longer...",
      title: "Show Progress",
      icon: &loading_icon/1,
      action: nil,
      duration: nil,
      component: nil,
      container_id: "toast-group",
      uuid: uuid
    }
    |> LiveToast.send_toast()

    Process.send_after(self(), :done, 2000)

    {:noreply, socket}
  end

  def handle_info(:done, socket) do
    uuid = "show-progress"

    %LiveToast{
      kind: :info,
      msg: "Upload complete!",
      title: "Show Progress",
      icon: nil,
      action: nil,
      duration: nil,
      component: nil,
      container_id: "toast-group",
      uuid: uuid
    }
    |> LiveToast.send_toast()

    {:noreply, socket}
  end

  def loading_icon(assigns) do
    ~H"""
    <span class="mr-1.5 inline-grid">
      <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
        data-slot="icon"
        class="inline-block h-3 w-3 animate-spin"
      >
        <path
          fill-rule="evenodd"
          d="M4.755 10.059a7.5 7.5 0 0 1 12.548-3.364l1.903 1.903h-3.183a.75.75 0 1 0 0 1.5h4.992a.75.75 0 0 0 .75-.75V4.356a.75.75 0 0 0-1.5 0v3.18l-1.9-1.9A9 9 0 0 0 3.306 9.67a.75.75 0 1 0 1.45.388Zm15.408 3.352a.75.75 0 0 0-.919.53 7.5 7.5 0 0 1-12.548 3.364l-1.902-1.903h3.183a.75.75 0 0 0 0-1.5H2.984a.75.75 0 0 0-.75.75v4.992a.75.75 0 0 0 1.5 0v-3.18l1.9 1.9a9 9 0 0 0 15.059-4.035.75.75 0 0 0-.53-.918Z"
          clip-rule="evenodd"
        />
      </svg>
    </span>
    """
  end

  def example_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="text-zinc-900 w-4 h-4 mr-1"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
      />
    </svg>
    """
  end

  def example_action(assigns) do
    ~H"""
    <button class="my-4 mr-4 text-sm font-medium bg-zinc-900 text-zinc-100 px-2 py-1 rounded-md hover:bg-zinc-800 hover:text-zinc-200">
      Undo
    </button>
    """
  end

  def congrats_toast(assigns) do
    ~H"""
    <div class="grid grid-row-2 gap-2">
      <div class="flex place-items-center">
        <div class="grow flex flex-col items-start justify-center">
          <p
            :if={@title}
            data-part="title"
            class="mb-2 flex items-center text-base font-semibold leading-6"
          >
            <%= @title %>
          </p>
          <p class="text-sm leading-5">
            <%= @body %>
          </p>
        </div>
      </div>

      <p class="w-full mt-2 text-xs font-medium text-gray-500 flex">
        <span class="grow text-indigo-600">
          <.link href={"https://github.com/srcrip/live_toast"}>
            Star it on GitHub
          </.link>
        </span>
      </p>
    </div>
    """
  end

  def custom_toast(assigns) do
    ~H"""
    <div class="grow flex flex-col items-start justify-center">
      <h1 class="mb-2 text-lg font-bold text-zinc-900">
        <%= @title %>
      </h1>
      <p class="text-sm font-medium text-indigo-500">
        <%= @body %>
      </p>
    </div>
    """
  end

  def everything_toast(assigns) do
    ~H"""
    <div class="grid grid-row-2 gap-2">
      <div class="flex place-items-center">
        <div class="grow flex flex-col items-start justify-center">
          <p
            :if={@title}
            data-part="title"
            class="mb-2 flex items-center text-sm font-semibold leading-6"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="text-green-500 w-4 h-4 mr-1"
            >
              <path
                fill-rule="evenodd"
                d="M7.502 6h7.128A3.375 3.375 0 0 1 18 9.375v9.375a3 3 0 0 0 3-3V6.108c0-1.505-1.125-2.811-2.664-2.94a48.972 48.972 0 0 0-.673-.05A3 3 0 0 0 15 1.5h-1.5a3 3 0 0 0-2.663 1.618c-.225.015-.45.032-.673.05C8.662 3.295 7.554 4.542 7.502 6ZM13.5 3A1.5 1.5 0 0 0 12 4.5h4.5A1.5 1.5 0 0 0 15 3h-1.5Z"
                clip-rule="evenodd"
              />
              <path
                fill-rule="evenodd"
                d="M3 9.375C3 8.339 3.84 7.5 4.875 7.5h9.75c1.036 0 1.875.84 1.875 1.875v11.25c0 1.035-.84 1.875-1.875 1.875h-9.75A1.875 1.875 0 0 1 3 20.625V9.375Zm9.586 4.594a.75.75 0 0 0-1.172-.938l-2.476 3.096-.908-.907a.75.75 0 0 0-1.06 1.06l1.5 1.5a.75.75 0 0 0 1.116-.062l3-3.75Z"
                clip-rule="evenodd"
              />
            </svg>
            <%= @title %>
          </p>
          <p class="text-sm leading-5">
            <%= @body %>
          </p>
        </div>

        <button class="mt-2 text-sm font-medium bg-zinc-900 text-zinc-100 px-2 py-1 rounded-md hover:bg-zinc-800 hover:text-zinc-200">
          Confirm
        </button>
      </div>

      <p class="w-full mt-2 text-xs font-medium text-gray-500 flex">
        <span class="grow text-indigo-600">View details</span>
        <span><%= DateTime.utc_now() |> DateTime.to_iso8601() %></span>
      </p>
    </div>
    """
  end

  defp navbar(assigns) do
    ~H"""
    <div class="container fixed top-0 z-20 w-dvw max-w-full -ml-3 md:-ml-6 bg-transparent">
      <div class="nextra-nav-container-blur pointer-events-none absolute z-[-1] h-full w-full bg-white shadow-[0_2px_4px_rgba(0,0,0,.02),0_1px_0_rgba(0,0,0,.06)]">
      </div>
      <nav class="mx-auto flex h-[50px] max-w-[90rem] items-center justify-end gap-2 pl-[max(env(safe-area-inset-left),1.5rem)] pr-[max(env(safe-area-inset-right),1.5rem)]">
        <a class="flex items-center hover:opacity-75 font-semibold" href="/">
          Live Toast
        </a>
        <div class="grow"></div>
        <a
          href="https://github.com/srcrip/live_toast"
          target="_blank"
          rel="noreferrer"
          class="p-2 text-current"
        >
          <svg width="24" height="24" fill="currentColor" viewBox="3 3 18 18">
            <title>GitHub</title>
            <path d="M12 3C7.0275 3 3 7.12937 3 12.2276C3 16.3109 5.57625 19.7597 9.15374 20.9824C9.60374 21.0631 9.77249 20.7863 9.77249 20.5441C9.77249 20.3249 9.76125 19.5982 9.76125 18.8254C7.5 19.2522 6.915 18.2602 6.735 17.7412C6.63375 17.4759 6.19499 16.6569 5.8125 16.4378C5.4975 16.2647 5.0475 15.838 5.80124 15.8264C6.51 15.8149 7.01625 16.4954 7.18499 16.7723C7.99499 18.1679 9.28875 17.7758 9.80625 17.5335C9.885 16.9337 10.1212 16.53 10.38 16.2993C8.3775 16.0687 6.285 15.2728 6.285 11.7432C6.285 10.7397 6.63375 9.9092 7.20749 9.26326C7.1175 9.03257 6.8025 8.08674 7.2975 6.81794C7.2975 6.81794 8.05125 6.57571 9.77249 7.76377C10.4925 7.55615 11.2575 7.45234 12.0225 7.45234C12.7875 7.45234 13.5525 7.55615 14.2725 7.76377C15.9937 6.56418 16.7475 6.81794 16.7475 6.81794C17.2424 8.08674 16.9275 9.03257 16.8375 9.26326C17.4113 9.9092 17.76 10.7281 17.76 11.7432C17.76 15.2843 15.6563 16.0687 13.6537 16.2993C13.98 16.5877 14.2613 17.1414 14.2613 18.0065C14.2613 19.2407 14.25 20.2326 14.25 20.5441C14.25 20.7863 14.4188 21.0746 14.8688 20.9824C16.6554 20.364 18.2079 19.1866 19.3078 17.6162C20.4077 16.0457 20.9995 14.1611 21 12.2276C21 7.12937 16.9725 3 12 3Z">
            </path>
          </svg>
          <span class="sr-only">GitHub</span><span class="sr-only select-none"> (opens in a new tab)</span>
        </a>
        <button
          type="button"
          aria-label="Menu"
          class="-mr-2 rounded p-2 active:bg-gray-400/20 md:hidden"
          phx-click={
            JS.toggle_class(
              "max-md:block",
              to: "aside#main-navigation"
            )
            |> JS.toggle_class(
              "max-md:block",
              to: "#backdrop"
            )
          }
        >
          <svg fill="none" width="24" height="24" viewBox="0 0 24 24" stroke="currentColor" class="">
            <g>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16">
              </path>
            </g>
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 12h16"></path>
            <g>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 18h16">
              </path>
            </g>
          </svg>
        </button>
      </nav>
    </div>
    """
  end

  def tab(%{action: :why} = assigns), do: why(assigns)
  def tab(%{action: :recipes} = assigns), do: recipes(assigns)
  def tab(%{action: :customization} = assigns), do: customization(assigns)
  def tab(assigns), do: demo(assigns)

  def apply_action(socket, :why) do
    socket
    |> assign(:page_title, "Live Toast — Why Live Toast?")
  end

  def apply_action(socket, :recipes) do
    socket
    |> assign(:page_title, "Live Toast — Recipes")
  end

  def apply_action(socket, :customization) do
    socket
    |> assign(:page_title, "Live Toast — Customization")
  end

  def apply_action(socket, _) do
    socket
    |> assign(:page_title, "Live Toast — Demo")
  end
end

defmodule LiveToast.Components do
  @moduledoc """
  This module defines the components used in the rendering of the default toast messages.
  You can use this as a reference to create your own version of these components.
  """

  use Phoenix.Component

  alias LiveToast.Utility
  alias Phoenix.LiveView.JS

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"
  attr :target, :any, default: nil, doc: "the target for the phx-click event"

  attr :duration, :integer,
    default: 6000,
    doc: "the time in milliseconds before the message is automatically dismissed"

  attr :class_fn, :any,
    required: true,
    doc: "function to override the look of the toasts"

  attr :corner, :atom, required: true, doc: "the corner to display the toasts"

  attr :icon, :any, default: nil, doc: "the optional icon to render in the flash message"
  attr :action, :any, default: nil, doc: "the optional action to render in the flash message"
  attr :component, :any, default: nil, doc: "the optional component to render the flash message"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  @doc """
  Default toast function. Based on the look and feel of [Sonner](https://sonner.emilkowal.ski/).

  You can use this as a reference to create your own toast component, that can be passed to the `component` option of `LiveToast.send_toast/3`.
  """
  def toast(assigns) do
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
      <button
        type="button"
        class={[
          "group-has-[[data-part='title']]/toast:absolute",
          "right-[5px] top-[5px] rounded-md p-[5px] text-black/50 transition-opacity hover:text-black focus:opacity-100 focus:outline-none focus:ring-1 group group-hover:opacity-100"
        ]}
        aria-label="close"
        {
        if Phoenix.Flash.get(@flash, @kind),
          do: ["phx-click": JS.dispatch("flash-leave", to: "##{@id}") |> JS.push("lv:clear-flash", value: %{key: @kind}) |> Utility.hide("##{@id}")],
          else: [
            "phx-target": @target,
            "phx-click": "clear",
            "phx-value-id": @id
          ]
        }
      >
        <Utility.svg
          name="hero-x-mark-solid"
          class="h-[14px] w-[14px] opacity-40 group-hover:opacity-70"
        />
      </button>
    </div>
    """
  end

  attr :f, :map, required: true, doc: "the map of flash messages"

  attr :corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :bottom_right,
    doc: "the corner to display the toasts"

  attr :toast_class_fn, :any,
    default: &LiveToast.toast_class_fn/1,
    doc: "function to override the look of the toasts"

  @doc false
  def flashes(assigns) do
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
      phx-disconnected={Utility.show(".phx-client-error #client-error")}
      phx-connected={Utility.hide("#client-error")}
      hidden
    >
      Attempting to reconnect
      <Utility.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
    </.toast>

    <.toast
      corner={@corner}
      class_fn={@toast_class_fn}
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-update="ignore"
      phx-disconnected={Utility.show(".phx-server-error #server-error")}
      phx-connected={Utility.hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <Utility.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
    </.toast>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "toast-group", doc: "the optional id of flash container"

  attr :corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :bottom_right,
    doc: "the corner to display the toasts"

  attr :toast_class_fn, :any,
    default: &LiveToast.toast_class_fn/1,
    doc: "function to override the look of the toasts"

  attr :class, :any,
    default: "fixed z-50 max-h-screen w-full p-4 md:max-w-[420px] pointer-events-none grid origin-center",
    doc: "classes for the toast group"

  # Used to render flashes-only on regular non-LV pages.
  @doc false
  def flash_group(assigns) do
    assigns =
      assign(assigns, :position_class, Utility.group_toast_class(assigns[:corner]))

    ~H"""
    <div
      id={assigns[:id] || "flash-group"}
      class={[
        @position_class,
        @class
      ]}
    >
      <.flashes f={@flash} corner={@corner} toast_class_fn={@toast_class_fn} />
    </div>
    """
  end
end

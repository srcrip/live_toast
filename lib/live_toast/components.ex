defmodule LiveToast.Components do
  @moduledoc """
  This module defines the components used in the rendering of the default toast messages.
  You can use this as a reference to create your own version of these components.
  """

  use Phoenix.Component

  alias LiveToast.Utility
  alias Phoenix.LiveView.JS

  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")
  attr(:target, :any, default: nil, doc: "the target for the phx-click event")

  attr(:delay, :integer,
    default: 0,
    doc: "adds a delay before being shown. not exposed by default, used only for 'client-error' and 'server-error'"
  )

  attr(:duration, :integer,
    default: 6000,
    doc: "the time in milliseconds before the message is automatically dismissed"
  )

  attr(:toast_class_fn, :any,
    required: true,
    doc: "function to override the toast classes"
  )

  attr(:corner, :atom, required: true, doc: "the corner to display the toasts")

  attr(:icon, :any, default: nil, doc: "the optional icon to render in the flash message")
  attr(:action, :any, default: nil, doc: "the optional action to render in the flash message")
  attr(:component, :any, default: nil, doc: "the optional component to render the flash message")

  attr(:flash_duration, :integer, default: 0, doc: "if provided clears flash after provided milliseconds")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

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
      data-kind={@kind}
      data-flash-duration={@flash_duration}
      data-duration={@duration}
      data-delay={@delay}
      data-corner={@corner}
      class={@toast_class_fn.(assigns)}
      {@rest}
    >
      <%= if @component do %>
        {@component.(Map.merge(assigns, %{body: msg}))}
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
              {@icon.(assigns)}
            <% end %>
            {@title}
          </p>
          <p class="text-sm leading-5">
            {msg}
          </p>
        </div>

        <%= if @action do %>
          {@action.(assigns)}
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

  attr(:f, :map, required: true, doc: "the map of flash messages")

  attr(:client_error_delay, :integer, default: 3000, doc: "adds a delay before the disconnected client error is shown")

  attr(:corner, :atom,
    values: [:top_left, :top_center, :top_right, :bottom_left, :bottom_center, :bottom_right],
    default: :bottom_right,
    doc: "the corner to display the toasts"
  )

  attr(:toast_class_fn, :any,
    default: &LiveToast.toast_class_fn/1,
    doc: "function to override the toast classes"
  )

  attr(:kinds, :list, required: true, doc: "the valid severity level kinds")

  attr(:flash_duration, :integer, default: 0, doc: "if provided clears flash after provided milliseconds")

  @doc false
  def flashes(assigns) do
    ~H"""
    <.toast
      :for={level <- @kinds}
      data-component="flash"
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      flash_duration={@flash_duration}
      duration={0}
      kind={level}
      title={Utility.translate(String.capitalize(to_string(level)))}
      phx-update="ignore"
      flash={@f}
    />
    <.toast
      data-component="flash"
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      id="client-error"
      kind={:error}
      title={Utility.translate("We can't find the internet")}
      delay={@client_error_delay}
      phx-update="ignore"
      phx-disconnected={Utility.show_error(".phx-client-error #client-error")}
      phx-connected={Utility.hide_error("#client-error")}
      data-disconnected={Utility.show(".phx-client-error #client-error")}
      data-connected={Utility.hide("#client-error")}
      hidden
    >
      {Utility.translate("Attempting to reconnect")}
      <Utility.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
    </.toast>

    <.toast
      data-component="flash"
      corner={@corner}
      toast_class_fn={@toast_class_fn}
      id="server-error"
      kind={:error}
      title={Utility.translate("Something went wrong!")}
      phx-update="ignore"
      phx-disconnected={Utility.show_error(".phx-server-error #server-error")}
      phx-connected={Utility.hide_error("#server-error")}
      data-disconnected={Utility.show(".phx-server-error #server-error")}
      data-connected={Utility.hide("#server-error")}
      delay={@client_error_delay}
      hidden
    >
      {Utility.translate("Hang in there while we get back on track")}
      <Utility.svg name="hero-arrow-path" class="inline-block ml-1 h-3 w-3 animate-spin" />
    </.toast>
    """
  end

  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "toast-group", doc: "the optional id of flash container")
  attr(:kinds, :list, required: true, doc: "the valid severity level kinds")

  attr(:corner, :atom,
    values: [:top_left, :top_right, :bottom_left, :bottom_right],
    default: :bottom_right,
    doc: "the corner to display the toasts"
  )

  attr(:group_class_fn, :any,
    default: &LiveToast.group_class_fn/1,
    doc: "function to override the container classes"
  )

  attr(:toast_class_fn, :any,
    default: &LiveToast.toast_class_fn/1,
    doc: "function to override the toast classes"
  )

  attr(:client_error_delay, :integer, default: 3000, doc: "adds a delay before the disconnected client error is shown")

  attr(:flash_duration, :integer, default: 0, doc: "if provided clears flash after provided milliseconds")

  # Used to render flashes-only on regular non-LV pages.
  @doc false
  def flash_group(assigns) do
    ~H"""
    <div id={assigns[:id] || "flash-group"} class={@group_class_fn.(assigns)}>
      <.flashes
        f={@flash}
        corner={@corner}
        flash_duration={@flash_duration}
        toast_class_fn={@toast_class_fn}
        kinds={@kinds}
      />
    </div>
    """
  end
end

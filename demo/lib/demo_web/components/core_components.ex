defmodule DemoWeb.CoreComponents do
  @moduledoc false

  use Phoenix.Component

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium border border-zinc-200/50 transition-colors bg-zinc-100 text-zinc-900 shadow-sm hover:bg-zinc-200 phx-submit-loading:opacity-75 active:text-zinc-800 h-9 px-4 py-2",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

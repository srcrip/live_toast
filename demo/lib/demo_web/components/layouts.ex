defmodule DemoWeb.Layouts do
  @moduledoc false
  use DemoWeb, :html

  embed_templates("layouts/*")

  def demo_toast_class_fn(assigns) do
    [
      # base classes
      "bg-white group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-4 shadow-lg border col-start-1 col-end-1 row-start-1 row-end-2",
      # start hidden if javascript is enabled
      "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled){[data-phx-main]_&}]:opacity-100",
      # used to hide the disconnected flashes
      if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
      # override styles per severity
      assigns[:kind] == :info && "text-black",
      assigns[:kind] == :error && "!text-red-700 !bg-red-100 border-red-200",
      assigns[:kind] == :warn && "!text-amber-700 !bg-amber-100 border-amber-200"
    ]
  end

  def demo_group_class_fn(assigns) do
    [
      # base classes
      "fixed z-50 max-h-screen w-full p-4 md:max-w-[420px] pointer-events-none grid origin-center",
      # classes to set container positioning
      assigns[:corner] == :bottom_left && "items-end bottom-0 left-0 flex-col-reverse sm:top-auto",
      assigns[:corner] == :bottom_right && "items-end bottom-0 right-0 flex-col-reverse sm:top-auto",
      assigns[:corner] == :top_left && "items-start top-0 left-0 flex-col sm:bottom-auto",
      assigns[:corner] == :top_right && "items-start top-0 right-0 flex-col sm:bottom-auto"
    ]
  end
end

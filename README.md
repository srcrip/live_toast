# Live Toast

![CI](https://github.com/srcrip/live_toast/actions/workflows/tests.yml/badge.svg) [![Hex](https://img.shields.io/hexpm/v/live_toast)](https://hex.pm/packages/live_toast)

Live Toast is a drop-in replacement for the flash system in Phoenix/LiveView.

## Installation

Add `live_toast` to your list of dependencies in the `mix.exs` of your Phoenix
application:

```elixir
def deps do
  [
    {:live_toast, "~> 0.4.3"}
  ]
end
```

Next open up your `app.js` and import/setup the hook:

```javascript
import { createLiveToastHook } from 'live_toast'

let liveSocket = new LiveSocket('/live', Socket, {
  hooks: {
    LiveToast: createLiveToastHook()
  }
})
```

Then, add `'../deps/live_toast/lib/**/*.*ex'` to your list of paths Tailwind will look for class names, in your
`tailwind.config.js`:

```javascript
// assets/tailwind.config.js

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/your_app_web.ex',
    '../lib/your_app_web/**/*.*ex',
    '../deps/live_toast/lib/**/*.*ex',
  ]
}
```

Your particular file will look different but all you need to do is make sure the last line is there.

Note that the classes are currently hardcoded. Configuration of the toast components, and therefore there styling, are
on the roadmap. But the default styles should look pretty good in the mean time.

Finally, replace your `<.flash_group />` component with the new `<LiveToast.toast_group />`. It's most likely in your
`app.html.heex`:

```heex
<!-- Remove this! -->
<.flash_group flash={@flash} />

<!-- And replace it with this: -->
<LiveToast.toast_group flash={@flash} connected={assigns[:socket] != nil} />

<%= @inner_content %>
```

And you're done! Note that it's very important to set `connected` based on whether we're in a LiveView or not. This
controls toast/flash display on non-LiveView pages.

## Usage

`LiveToast` will hijack the usual display of your flash messages, so they will continue to work as normal. You can
continue to use flashes as normal, if you want to.

However, one of the reasons to *not* use flash messages, is the Phoenix flash system only allows one message for each
kind of flash. The toast pattern, alternatively, generally allows for multiple messages displayed to the user at at time.

From a LiveView, you can now use `send_toast`:

```elixir
defmodule YourApp.SomeLiveView do
  def handle_event("submit", _payload, socket) do
    # you do some thing with the payload, then you want to show a toast, so:
    LiveToast.send_toast(:info, "Upload successful.")

    {:noreply, socket}
  end
end
```

Or you can use the helper function, `put_toast`, similar to how you may use `put_flash`:

```elixir
defmodule YourApp.SomeLiveView do
  def handle_event("submit", _payload, socket) do
    socket = socket
    |> put_toast(:info, "Upload successful.")

    {:noreply, socket}
  end
end
```

`put_toast` can take a `Phoenix.LiveView.Socket` or a `Plug.Conn`, so you can use the same thing in your live and
non-live pages.

```elixir
defmodule YourApp.SomeController do
  def create(conn, _params) do
    conn
    |> put_toast(:info, "Upload successful.")
    |> render(:whatever)
  end
end
```

## Configuration

### Function Options

`send_toast` takes a number of arguments to control it's behavior. They are currently:

- `kind`: The 'level' of this toast. The default setup supports `:info`, and `:error`.
- `body`: The primary text of the message. 
- `title`: The optional title of the toast displayed at the top.
- `icon`: An optional function component that renders next to the title. You can use this with the default toast to display an icon.
- `action`: An optional function component that renders to the side. You can use this with the default toast to display an action, like a button.
- `component`: Use this to totally override rendering of the toast. This is expected to be a function component that
    will receive all of the above options. See [this part of the demo]() as an example.

Note that if you use more than just `:info` and `:error` in your codebase for flashes, you can augment Livetoast using
some of the methods below to support that.

### Custom Classes

You can define a custom toast class function, like so:

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

```

And then use it to override the default styles:

```heex
<LiveToast.toast_group flash={@flash} connected={assigns[:socket] != nil} toast_class_fn={MyModule.toast_class_fn/1} />
```

### JavaScript Options

You can also change some options about the LiveView hook when it is initalized. Such as:

```javascript
import { createLiveToastHook } from 'live_toast'

// the duration for each toast to stay on screen in ms
const duration = 4000

const liveToastHook = createLiveToastHook(duration)

let liveSocket = new LiveSocket('/live', Socket, {
  hooks: { LiveToast: liveToastHook },
})
```

## Roadmap

Some of the stuff still to work on:

- [ ] Improved docs
- [ ] Configuration for the classes on toasts
- [ ] more tests
- [ ] More configuration for the animations
- [ ] Ability to have more flashes than the default :error and :info (like a :warn)
- [ ] Update a toast live (showing progress for example), and a recipe entry on this

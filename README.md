# Live Toast

![CI](https://github.com/srcrip/live_toast/workflows/CI/badge.svg) [![Hex](https://img.shields.io/hexpm/v/live_toast)](https://hex.pm/packages/live_toast)

Live Toast is a drop-in replacement for the flash system in Phoenix/LiveView.

## Installation

Add `live_toast` to your list of dependencies in the `mix.exs` of your Phoenix
application:

```elixir
def deps do
  [
    {:live_toast, "~> 0.1.0"}
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

```eex
<!-- Remove this! -->
<.flash_group flash={@flash} />

<!-- And replace it with this: -->
<LiveToast.toast_group flash={@flash} connected={assigns[:socket] != nil} />

<%= @inner_content %>
```

And you're done! Note that it's very important to set `connected` based on whether we're in a LiveView or not.

## Usage

`LiveToast` will hijack the usual display of your flash messages, so they will continue to work as normal. You can
continue to use flashes as normal, if you want to.

However, one of the reasons to *not* use flash messages, is the Phoenix flash system only allows one message for each
kind of flash. The toast pattern, alternatively, generally allows for multiple messages displayed to the user at at time.

From a LiveView, you can now use `put_toast` similar to how you may use `put_flash`:

```elixir
defmodule YourApp.SomeLiveView do
  def handle_event("submit", _payload, socket) do
    # you do some thing with the payload, then you want to show a toast, so:
    LiveToast.send_toast(:info, "Upload successful.")

    {:noreply, socket}
  end
end
```

And that's pretty much it.

## Roadmap

Some of the stuff still to work on:

- [ ] Improved docs
- [ ] Configuration for the classes on toasts
- [ ] Tests
- [ ] More configuration for the animations

# Live Toast

<div>
  <a href="https://github.com/srcrip/live_toast/actions"><img src="https://github.com/srcrip/live_toast/actions/workflows/tests.yml/badge.svg" alt="tests badge"/></a>
  <a href="https://hex.pm/packages/live_toast"><img src="https://img.shields.io/hexpm/v/live_toast" alt="tests badge"/></a>
</div>

<br />

Live Toast is a drop-in replacement for the flash system in Phoenix/LiveView.

## Features

- **📄 Stackable toast messages:** The flash system limits you to one flash per type. No longer!
- **📸 Replaces your flash messages:** One drop in component to continue to render your flash messages in the same style as
    the newer toast system.
- **💅 Beautiful by design:** Based on the look of the wonderful [Sonner](https://sonner.emilkowal.ski/) library from React.
- **⚙️ Highly configurable:** Looks good out of the box, but can be changed in pretty much any way you want.
- **🌍 Simple asset delivery:** `LiveToast` simply ships Tailwind classes and lets your project bundle them up. No CSS
    drop-in required.

## Installation

Add `live_toast` to your list of dependencies in the `mix.exs` of your Phoenix app:

```elixir
def deps do
  [
    {:live_toast, "~> 0.8.0"}
  ]
end
```

Next open up your `app.js` and import/setup the hook.

If you have a `package.json` file at the top of `assets`, you can add this to it:

```json
"dependencies": {
  "live_toast": "file:../deps/live_toast",
},
```

And then import and set up the bare module:

```javascript
import { createLiveToastHook } from 'live_toast'

let liveSocket = new LiveSocket('/live', Socket, {
  hooks: {
    LiveToast: createLiveToastHook()
  }
})
```

Or you can import the file directly:

```javascript
// this path would be relative to where your app.js happens to be.
import { createLiveToastHook } from '../deps/live_toast'

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

> **Note for Umbrella Apps:**
> If you're using an umbrella application, your paths above may look different. You'll probably have an extra folder in
> there, so the line you need to add would be more like `"../../../deps/live_toast/lib/**/*.*ex"`

Finally, replace your `<.flash_group />` component with the new `<LiveToast.toast_group />`. It's most likely in your
`app.html.heex`:

```heex
<!-- Remove this! -->
<.flash_group flash={@flash} />

<!-- And replace it with this: -->
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  toasts_sync={assigns[:toasts_sync]}
/>

<%= @inner_content %>
```

Those three options, `flash`, `connected`, and `toasts_sync` are all required. The library will not function properly if
you do not pass them in.


> **Note:**
> As far as I can tell in my testing, this usage of `assigns` in the layout has no negative impact on change tracking.

And you're done! Note that it's very important to set `connected` based on whether we're in a LiveView or not. This
controls toast/flash display on non-LiveView pages.

## Usage

`LiveToast` will hijack the usual display of your flash messages, so they will continue to work as normal. You can
continue to use flashes as normal, if you want to.

However, one of the reasons to *not* use flash messages, is the Phoenix flash system only allows one message for each
kind of flash. The toast pattern, alternatively, generally allows for multiple messages displayed to the user at at time.

From a LiveView, you can now use [`send_toast`](https://hexdocs.pm/live_toast/LiveToast.html#send_toast/3):

> **Note:**
> Please reference the `Configuration` section below for the available `options`.

```elixir
defmodule YourApp.SomeLiveView do
  def handle_event("submit", _payload, socket) do
    options = [
      title: "Status"
    ]

    # you do some thing with the payload, then you want to show a toast, so:
    LiveToast.send_toast(:info, "Upload successful.", options)

    {:noreply, socket}
  end
end
```

> **Note:**
> `LiveToast` is the top-level module, so there's no need to `alias` or `import` anything.

`send_toast/3` returns the toast UUID. You can use that UUID to dismiss the toast later from the server with
[`dismiss_toast`](https://hexdocs.pm/live_toast/LiveToast.html#dismiss_toast/2):

```elixir
defmodule YourApp.SomeLiveView do
  def handle_event("start_upload", _payload, socket) do
    uuid = LiveToast.send_toast(:info, "Upload started.", duration: 0)

    {:noreply, assign(socket, upload_toast_uuid: uuid)}
  end

  def handle_event("finish_upload", _payload, socket) do
    LiveToast.dismiss_toast(socket.assigns.upload_toast_uuid)

    {:noreply, socket}
  end
end
```

If your toast group uses a custom `id`, pass the same value as `:container_id`.

Custom toast components can also dismiss themselves with the composable client-side action
[`dismiss`](https://hexdocs.pm/live_toast/LiveToast.html#dismiss/1):

```heex
<button type="button" phx-click={LiveToast.dismiss()}>
  Dismiss
</button>
```

Both dismissal paths run the exit animation before removing the toast.

### Browser JavaScript

Import `addToast` when browser JavaScript needs to request a toast. The mounted toast host validates the requested kind
and renders the toast server-side, so it continues to use the host's configured styles, custom component function,
animation, and stacking behavior.

```javascript
import { addToast } from 'live_toast'

addToast('info', 'Copied to clipboard.', {
  title: 'Copied',
  duration: 3_000,
  metadata: { has_icon: false }
})
```

The browser API accepts serializable `title`, `duration`, and `metadata` options. Use `duration: 'infinity'` for a
persistent toast.

Or you can use the helper function, [`put_toast`](https://hexdocs.pm/live_toast/LiveToast.html#put_toast/4), similar to how you may use [`put_flash`](https://hexdocs.pm/phoenix/Phoenix.Controller.html#put_flash/3):

```elixir
defmodule YourApp.SomeLiveView do
  def handle_event("submit", _payload, socket) do
    socket = socket
    |> LiveToast.put_toast(:info, "Upload successful.")

    {:noreply, socket}
  end
end
```

[`put_toast`](https://hexdocs.pm/live_toast/LiveToast.html#put_toast/4) can take a `Phoenix.LiveView.Socket` or a `Plug.Conn`, so you can use the same thing in your live and
non-live pages.

```elixir
defmodule YourApp.SomeController do
  def create(conn, _params) do
    conn
    |> LiveToast.put_toast(:info, "Upload successful.")
    |> render(:whatever)
  end
end
```

## Configuration

### Setting the corner

You can change where toasts are anchored by passing the `corner` setting to `toast_group`. Supported positions are
`:top_left`, `:top_center`, `:top_right`, `:bottom_left`, `:bottom_center`, and `:bottom_right`. The default is
`:bottom_right`.

```heex
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  corner={:top_center}
  toasts_sync={assigns[:toasts_sync]}
/>
```

### Internationalization

You can provide translations for the defaul error toasts by adding the following to your `config.exs`:

```elixir
config :live_toast,
  gettext_backend: MyApp.Gettext
```

You have to create a `live_toast.po` file, inside the `priv/gettext/<language>/LC_MESSAGES/` folder for each language you want to support.

For example, if you want to support spanish, you would create the file `live_toast.po` in the `priv/gettext/es/LC_MESSAGES/` folder, with the following content:

```po
msgid ""
msgstr ""
"Language: es\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

msgid "We can't find the internet"
msgstr "Nosotros no podemos encontrar internet"

msgid "Attempting to reconnect"
msgstr "Intentando reconectar"

msgid "Something went wrong!"
msgstr "¡Algo salió mal!"

msgid "Hang in there while we get back on track"
msgstr "Aguanta mientras volvemos a la normalidad"
```

### Function Options

[`send_toast`](https://hexdocs.pm/live_toast/LiveToast.html#send_toast/3) takes a number of arguments to control it's behavior. They are currently:

- `kind`: The 'level' of this toast. The `component` function can receive this and modify behavior based on severity.
    the `toast_class_fn` also receives it, and it can be used there to modify styles, for example, making `:info` toasts
    green and `:error` toasts red.
- `body`: The primary text of the message.
- `title`: The optional title of the toast displayed at the top.
- `icon`: An optional function component that renders next to the title. You can use this with the default toast to display an icon.
- `action`: An optional function component that renders to the side. You can use this with the default toast to display an action, like a button.
- `duration`: How long the toast stays visible in milliseconds. Timed toasts pause while hovered or while keyboard focus
    is inside the toast, then resume with their remaining duration. Set this to `0` or `:infinity` to keep a toast visible
    until it is dismissed. A custom component can include a `[data-live-toast-remaining]` element when it needs LiveToast
    to display the remaining whole seconds.
- `component`: Use this to totally override rendering of the toast. This is expected to be a function component that
    will receive all of the above options. See [this part of the demo](https://github.com/srcrip/live_toast/blob/fddcd7c51be05ba9997eb300ca920985e98ab583/demo/lib/demo_web/live/home_live.ex#L61) as an example.
- `metadata`: An application-defined map passed unchanged to a custom `component` function. Use this for
    component-specific presentation or behavior without adding library-level options. LiveToast does not interpret
    metadata.

### Custom rendering and classes

The `component` option and `toast_component_fn` render the content inside a LiveToast-managed toast shell. The shell
continues to provide the hook, timing attributes, enter and exit animations, stacking, and dismiss button. Use
[`toast_class_fn/1`](https://hexdocs.pm/live_toast/LiveToast.html#toast_class_fn/1) to change that outer shell's
classes; use a custom component function for the icon, title, body, action, and other toast content.

### Default custom toast component

Pass `toast_component_fn` to `LiveToast.toast_group` when all programmatic toasts in that host should use the same
custom component. A `component:` passed to an individual `send_toast/3` call takes precedence. This host default does
not change Phoenix flash or connection-notice rendering.

```heex
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  toasts_sync={assigns[:toasts_sync]}
  toast_component_fn={&MyAppWeb.Components.NotificationToast.render/1}
/>
```

```elixir
LiveToast.send_toast(:info, "The message was sent.", title: "Sent")
```

### Custom component metadata

Custom component functions receive `metadata` alongside the standard toast assigns such as `kind`, `title`, `body`,
`uuid`, `duration`, and `dismissible`. This gives an application a stable extension point for renderer-specific options.

For example, a component can show its semantic icon by default and let individual toasts opt out:

```elixir
def notification_toast(assigns) do
  ~H"""
  <div>
    <span :if={Map.get(@metadata, :has_icon, true)} aria-hidden="true">*</span>
    <p :if={@title} data-part="title">{@title}</p>
    <p>{@body}</p>
  </div>
  """
end

LiveToast.send_toast(
  :info,
  "The message was sent.",
  title: "Sent",
  component: &notification_toast/1,
  metadata: %{has_icon: false}
)
```

### Persistent toasts

Pass `duration: 0` or `duration: :infinity` to disable automatic expiry. Persistent toasts can still be replaced with
the same UUID and dismissed manually or programmatically.

```elixir
uuid = LiveToast.send_toast(:info, "Export ready", duration: :infinity)

LiveToast.dismiss_toast(uuid)
```

### Connection-state notifications

Set `connection_notifications={false}` if you prefer not to show LiveToast's built-in connection failure notices. This
removes both client and server notices, including their connection-event wiring.

```heex
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  toasts_sync={assigns[:toasts_sync]}
  connection_notifications={false}
/>
```

Otherwise, customize the built-in client and server connection notices with `connection_notifications`. Each entry accepts
`kind`, `title`, and `body`; unspecified values retain their defaults. Notices are persistent, non-dismissible, and
excluded from the ordinary visible-toast limit.

Use the optional `:client_error` and `:server_error` slots when an application needs custom markup. LiveToast retains
the connection-event wiring, animation, and toast shell while the slot receives `id`, `kind`, `title`, `body`, and
`corner` through `:let`.

```heex
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  toasts_sync={assigns[:toasts_sync]}
  connection_notifications={%{
    client_error: %{kind: :info, title: "Reconnecting", body: "Your changes are safe."}
  }}
>
  <:client_error :let={notice}>
    <.reconnecting_notice title={notice.title} body={notice.body} />
  </:client_error>
</LiveToast.toast_group>
```

Note that if you use more than just `:info` and `:error` in your codebase for flashes, you can augment LiveToast using
some of the methods below to support that.

### Custom Classes

You can define a [custom toast class function](https://hexdocs.pm/live_toast/LiveToast.html#toast_class_fn/1), like so:

```elixir
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

```

And then use it to override the default styles:

```heex
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  toast_class_fn={&MyModule.toast_class_fn/1}
  toasts_sync={assigns[:toasts_sync]}
/>
```

If you need to change the classes of the container, there is a similar function parameter called [`group_class_fn`](https://hexdocs.pm/live_toast/LiveToast.html#group_class_fn/1). Reference the documentation and apply the override just as you would `toast_class_fn/1` shown above.

### Custom Severity Levels

New Phoenix projects [use `:info` and `:error`](https://hexdocs.pm/phoenix/controllers.html#flash-messages)
as the default severity levels for flash messages, so this is likely what you're already using. If you need to add an
additional severity level, like `:warning`, you can pass a list of these values to the `kind` attribute:

```heex
<LiveToast.toast_group
  flash={@flash}
  connected={assigns[:socket] != nil}
  kinds={[:info, :error, :warning]}
  toast_class_fn={&custom_toast_class_fn/1}
  toasts_sync={assigns[:toasts_sync]}
/>
```

If this value is not set, it defaults to `[:info, :error]`.

Setting `kind` will allow these new severity levels to be displayed, but it won't change how they look. To do that, you
need to override [`toast_class_fn/1`](https://hexdocs.pm/live_toast/LiveToast.html#toast_class_fn/1). For example:

```elixir
# Note that this is just the default with one line added to handle the new `:warning` level.
def custom_toast_class_fn(assigns) do
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
    assigns[:kind] == :warning && "!text-amber-700 !bg-amber-100 border-amber-200"
  ]
end
```

Then just make sure you've passed it to the `live_group` component as seen above.


### JavaScript Options

You can also change some options about the LiveView hook when it is initialized. Such as:

```javascript
import { createLiveToastHook } from 'live_toast'

// the duration for each toast to stay on screen in ms
const duration = 4000

// how many toasts to show on screen at once
const maxItems = 3

const liveToastHook = createLiveToastHook(duration, maxItems)

let liveSocket = new LiveSocket('/live', Socket, {
  hooks: { LiveToast: liveToastHook }
})
```

## Roadmap

Some of the stuff still to work on:

- [ ] A11y
- [ ] Further documentation
- [ ] Even more configuration
- [ ] Lots of amazing tests
- [ ] Spring animations
- [ ] Possibly some way to configure additional severity levels

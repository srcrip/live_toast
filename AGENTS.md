# General Information

LiveToast is an Elixir library for Phoenix LiveView that aims to add a supplemental toast system that hooks into the
existing Phoenix flash system, but extends it with additional functionality.

# Development

Assume that the developer is always running the dev server (`mix phx.server`) themselves in a separate terminal tab. Do
not offer to start the server for them.

# Testing

```sh
cd demo && mix test
```

# JavaScript Assets

- `assets/js/live_toast/live_toast.ts` is the canonical LiveToast client source.
- `priv/static/live_toast.cjs.js`, `priv/static/live_toast.esm.js`, `priv/static/live_toast.js`, and
  `priv/static/live_toast.min.js` (and their source maps) are published distribution artifacts. When a change affects
  the client source, run `mix assets.build`, review the generated output, and commit the updated artifacts with the
  source change.
- The root `assets` project uses Bun. Demo `priv/static` output is generated and ignored; do not commit it.

# Public API Changes

- For a new or materially changed supported API, update the README and add or revise a demo recipe that links to the
  relevant demo source.
- Add focused coverage in `demo/test` for the supported behavior, including both LiveView and non-LiveView rendering
  paths when the public component supports both.

# Code Style

- Use Styler/Quokka for Elixir formatting
- Run `mix format` before committing

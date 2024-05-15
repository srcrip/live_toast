[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix_live_view],
  locals_without_parens: [
    attr: 2,
    attr: 3,
    slot: 1,
    slot: 2,
    slot: 3
  ]
]

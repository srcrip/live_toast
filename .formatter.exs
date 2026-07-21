[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter, Quokka],
  inputs: ["{mix,.formatter}.exs", "*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"],
  subdirectories: ["demo"]
]

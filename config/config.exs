import Config

config :phoenix, :json_library, Jason
config :logger, :level, :debug
config :logger, :backends, []

if Mix.env() == :dev do
  esbuild = fn args ->
    [
      args: ~w(./js/live_toast --bundle) ++ args,
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
  end

  config :esbuild,
    version: "0.12.15",
    module: esbuild.(~w(--format=esm --sourcemap --outfile=../priv/static/live_toast.esm.js)),
    main: esbuild.(~w(--format=cjs --sourcemap --outfile=../priv/static/live_toast.cjs.js)),
    cdn:
      esbuild.(
        ~w(--format=iife --target=es2016 --global-name=LiveMotion --outfile=../priv/static/live_toast.js)
      ),
    cdn_min:
      esbuild.(
        ~w(--format=iife --target=es2016 --global-name=LiveMotion --minify --outfile=../priv/static/live_toast.min.js)
      )
end

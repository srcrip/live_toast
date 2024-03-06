defmodule LiveToast.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_toast,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      package: package(),
      deps: deps(),
      name: "LiveToast",
      homepage_url: "https://github.com/srcrip/live_toast",
      description: """
      Drop-in replacement for the Phoenix flash system, supporting flashes and toasts.
      """
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, ">= 1.6.0 and < 1.8.0"},
      {:phoenix_live_view, "~> 0.18"},
      {:esbuild, "~> 0.2", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Andrew Stewart"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/live_toast/changelog.html",
        GitHub: "https://github.com/srcrip/live_toast"
      },
      files:
        ~w(assets/js lib priv) ++
          ~w(CHANGELOG.md LICENSE.md mix.exs package.json README.md)
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install"],
      "assets.build": ["esbuild module", "esbuild cdn", "esbuild cdn_min", "esbuild main"],
      "assets.watch": ["esbuild module --watch"]
    ]
  end
end

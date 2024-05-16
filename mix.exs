defmodule LiveToast.MixProject do
  @moduledoc false

  use Mix.Project

  @version "0.4.3"

  def project do
    [
      app: :live_toast,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      package: package(),
      deps: deps(),
      docs: docs(),
      name: "Live Toast",
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
      {:phoenix, ">= 1.7.0"},
      {:phoenix_live_view, ">= 0.18.0"},
      {:ecto, ">= 3.11.0"},
      {:esbuild, "~> 0.2", only: :dev},
      {:bandit, "~> 1.1", only: :dev},
      {:ex_check, "~> 0.14.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.32.2", only: [:dev], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false},
      {:styler, "~> 0.11.9", only: [:dev], runtime: false},
      {:makeup, "1.1.2", only: [:dev], runtime: false},
      {:makeup_elixir, "0.16.2", only: [:dev], runtime: false},
      {:makeup_js, "~> 0.1.0", only: [:dev], runtime: false},
      {:makeup_eex, "~> 0.1.2", only: [:dev], runtime: false}
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
        ~w(assets/js lib/live_toast.ex priv) ++
          ~w(CHANGELOG.md LICENSE.md mix.exs package.json README.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: @version,
      source_url: "https://github.com/srcrip/live_toast",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
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

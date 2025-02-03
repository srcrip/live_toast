defmodule LiveToast.MixProject do
  @moduledoc false

  use Mix.Project

  @version "0.7.0"

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
      source_url: "https://github.com/srcrip/live_toast",
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
      {:phoenix_live_view, ">= 0.20.0"},
      {:ecto, ">= 3.11.0"},
      {:gettext, ">= 0.26.2"},
      {:jason, "~> 1.4"},
      {:esbuild, "~> 0.2", only: :dev},
      {:bandit, "~> 1.1", only: :dev},
      {:ex_check, "~> 0.14.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.32.2", only: [:dev], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false},
      {:styler, "~> 0.11.9", only: [:dev, :test], runtime: false},
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
        GitHub: "https://github.com/srcrip/live_toast",
        Sponsor: "https://github.com/sponsors/srcrip"
      },
      files: files()
    ]
  end

  defp files do
    ~w"""
    assets/js
    priv
    lib/live_toast.ex
    lib/live_toast/components.ex
    lib/live_toast/live_component.ex
    lib/live_toast/utility.ex
    lib/live_toast/gettext.ex
    CHANGELOG.md
    LICENSE.md
    mix.exs
    package.json
    README.md
    """
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

defmodule Demo.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :demo,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {Demo.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:live_toast, path: ".."},
      {:bandit, "~> 1.1"},
      {:phoenix, ">= 1.6.0 and < 1.8.0"},
      {:phoenix_live_view, "~> 0.20"},
      {:ecto, ">= 0.0.0"},
      {:esbuild, "~> 0.2"},
      {:ex_check, "~> 0.14.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:gettext, ">= 0.26.2"},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false},
      {:styler, "~> 0.11.9", only: [:dev, :test], runtime: false},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:tailwind, "~> 0.2"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install"],
      "assets.build": ["tailwind demo", "esbuild demo"],
      "assets.watch": ["esbuild module --watch"],
      "assets.deploy": [
        "tailwind demo --minify",
        "esbuild demo --minify",
        "phx.digest"
      ]
    ]
  end
end

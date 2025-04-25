defmodule ExLiveTable.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "DataTable with sorting, filtering, and pagination for Phoenix LiveView"

  def project do
    [
      app: :ex_live_table,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: @description,
      package: package(),
      deps: deps(),
      name: "ExLiveTable",
      source_url: "https://github.com/jamesnjovu/ex_live_table",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExLiveTable.Application, []}
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["James Njovu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/live_table"},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.18.3"},
      {:phoenix_html, "~> 3.0"},
      {:plug, "~> 1.14"},
      {:ecto, "~> 3.9", optional: true},
      {:scrivener, "~> 2.7", optional: true},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: "https://github.com/yourusername/live_table"
    ]
  end
end

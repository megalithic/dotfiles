# REF:
# - https://github.com/cr0t/dotfiles/blob/master/dot.iex.exs
# - https://samuelmullen.com/articles/customizing_elixirs_iex/
# - https://www.adiiyengar.com/blog/20180709/my-iex-exs
# - https://github.com/blackode/elixir-tips#iex-custom-configuration---iex-decoration
# - https://github.com/blackode/custom-iex.git
#
#
# # IO.ANSI.light_black_background() <>
# info = IO.ANSI.light_black() <> "\uf6ef #{queue_length.()}" <> IO.ANSI.reset()
#
# last = IO.ANSI.normal() <> "\uf460" <> IO.ANSI.reset()
# # last = IO.ANSI.normal() <> "\uf054" <> IO.ANSI.reset()
# # last = IO.ANSI.faint() <> "\uf101 \uf460 \uf63d \uf710" <> IO.ANSI.reset()
#
# alive =
#   IO.ANSI.bright() <>
#     IO.ANSI.yellow() <>
#     IO.ANSI.blink_rapid() <>
#     "\ue315 " <>
#     IO.ANSI.reset()
#

# if :mix not in Enum.map(Application.loaded_applications(), &elem(&1, 0)) do
#   Mix.install([
#     :decimal,
#     {:req, path: "~/src/req"},
#     {:easyxml, path: "~/src/easyxml"},
#     {:easyhtml, path: "~/src/easyhtml"}
#   ])
# end

history_size = 100

# Color Variables
# blue_ansi = IO.ANSI.blue()
green_ansi = IO.ANSI.green()
reset_ansi = IO.ANSI.reset()
white_background = IO.ANSI.white_background()
eval_result = [:green, :bright]
eval_error = [[:red, :bright, "\ue3bf ERROR - "]]
eval_info = [:blue, :bright]

defmodule H do
  @moduledoc """
  Defines a few helper methods to enchance visual appearance and available
  functionality of the IEx.
  ### Extra Information
  First time I've learned about customizations to `.iex.exs` here:
  - https://www.youtube.com/watch?v=E0bmtcYrz9M
  Here is a couple of good articles:
  - https://samuelmullen.com/articles/customizing_elixirs_iex/
  - https://www.adiiyengar.com/blog/20180709/my-iex-exs
  """

  @tips_and_tricks [
    ":observer.start() - a GUI for BEAM",
    "runtime_info <:memory|:applications|...> - sometimes useful data",
    "IEx.configure(inspect: [limit: :infinity]) - show everything"
  ]

  # Lookup an app in the started applications list
  def is_app_started?(app) when is_atom(app) do
    Application.started_applications()
    |> Enum.any?(&(elem(&1, 0) == app))
  end

  # Message queue length for the IEx process: nice to see when playing with
  # remote nodes (distributed Erlang)
  def queue_length do
    self()
    |> Process.info()
    |> Keyword.get(:message_queue_len)
  end

  # Wrap given text in bright ANSI colors and print
  def print_bright(text) do
    (IO.ANSI.bright() <> text <> IO.ANSI.reset())
    |> IO.puts()
  end

  def print_tips_n_tricks() do
    print_bright("\n--- Tips & Tricks:")

    Enum.map(@tips_and_tricks, &IO.puts/1)
  end

  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
  def logger_debug(), do: Logger.configure(level: :debug)
  def logger_error(), do: Logger.configure(level: :error)
  def logger_warn(), do: Logger.configure(level: :warn)
  def logger_info(), do: Logger.configure(level: :info)
end

prefix = IO.ANSI.green() <> "%prefix" <> IO.ANSI.reset()
counter = IO.ANSI.green() <> "[%node](%counter)" <> IO.ANSI.reset()
info = IO.ANSI.light_blue() <> " #{H.queue_length()}" <> IO.ANSI.reset()
last = IO.ANSI.yellow() <> "" <> IO.ANSI.reset()
alive = IO.ANSI.bright() <> IO.ANSI.yellow() <> "󱐋" <> IO.ANSI.reset()

default_prompt = prefix <> counter <> " " <> info <> " " <> last
alive_prompt = prefix <> counter <> " " <> info <> " " <> alive <> last

IEx.configure(
  inspect: [limit: :infinity, pretty: true, charlists: :as_lists],
  history_size: history_size,
  colors: [
    eval_result: eval_result,
    eval_error: eval_error,
    eval_info: eval_info
  ],
  continuation_prompt: "    ",
  alive_prompt: alive_prompt,
  default_prompt: default_prompt
)

H.print_bright("\n---  Phoenix & Ecto:")

# # Phoenix Support
# import_if_available(Plug.Conn)
# import_if_available(Phoenix.HTML)

#       Mix.Project.get().project()[:app]
# phoenix_app =
#   :application.info()
#   |> Keyword.get(:running)
#   |> Enum.reject(fn {_x, y} ->
#     y == :undefined
#   end)
#   |> Enum.find(fn {x, _y} ->
#     x |> Atom.to_string() |> String.match?(~r{_web})
#   end)
#
# # Check if phoenix app is found
# case phoenix_app do
#   nil ->
#     IO.puts("Phoenix #{IO.ANSI.yellow() <> "not detected" <> IO.ANSI.reset()}")
#
#   {app, _pid} ->
#     IO.puts("Phoenix detected: #{IO.ANSI.green() <> app <> IO.ANSI.reset()}")
#
#     ecto_app =
#       app
#       |> Atom.to_string()
#       |> (&Regex.split(~r{_web}, &1)).()
#       |> Enum.at(0)
#       |> String.to_atom()
#
#     ecto_exists =
#       :application.info()
#       |> Keyword.get(:running)
#       |> Enum.reject(fn {_x, y} ->
#         y == :undefined
#       end)
#       |> Enum.map(fn {x, _y} -> x end)
#       |> Enum.member?(ecto_app)
#
#     # Check if Ecto app exists or running
#     case ecto_exists do
#       false ->
#         IO.puts("Ecto app #{ecto_app} doesn't exist or isn't running")
#
#       true ->
#         IO.puts("Ecto app found: #{ecto_app}")
#
#         # Ecto Support
#         import_if_available(Ecto.Query)
#         import_if_available(Ecto.Changeset)
#
#         # Alias Repo
#         repo = ecto_app |> Application.get_env(:ecto_repos) |> Enum.at(0)
#
#         quote do
#           alias unquote(repo), as: Repo
#         end
#     end
# end

phoenix_started? = H.is_app_started?(:phoenix)
ecto_started? = H.is_app_started?(:ecto)

phoenix_info =
  if phoenix_started? do
    app_name = Mix.Project.get().project()[:app]

    IO.ANSI.green() <> "running (#{app_name}_web)" <> IO.ANSI.reset()
  else
    IO.ANSI.yellow() <> "not detected" <> IO.ANSI.reset()
  end

IO.puts("Phoenix: #{phoenix_info}")

ecto_info =
  if ecto_started? do
    IO.ANSI.green() <> "running" <> IO.ANSI.reset()
  else
    IO.ANSI.yellow() <> "not detected" <> IO.ANSI.reset()
  end

repo_info =
  if ecto_started? do
    repo =
      Mix.Project.get().project()[:app]
      |> Application.get_env(:ecto_repos)
      |> case do
        repo when not is_nil(repo) ->
          repo
          |> Enum.at(0)
          |> Atom.to_string()
          |> String.replace(~r/^Elixir\./, "")

        _ ->
          ""
      end

    IO.ANSI.faint() <> "(`alias #{repo}, as: Repo`)" <> IO.ANSI.reset()
  else
    ""
  end

if ecto_started? do
  import_if_available(Ecto.Query)
  import_if_available(Ecto.Changeset)

  repo =
    Mix.Project.get().project()[:app]
    |> Application.get_env(:ecto_repos)

  repo = if not is_nil(repo), do: Enum.at(repo, 0)

  quote do
    alias unquote(repo), as: Repo
  end
end

IO.puts("Ecto: #{ecto_info} #{repo_info}")

# One extra empty line before command line
IO.puts("")

# Mix.ensure_application!(:wx)
# Mix.ensure_application!(:runtime_tools)
# Mix.ensure_application!(:observer)

Application.put_env(:elixir, :dbg_callback, {Macro, :dbg, []})
Application.put_env(:elixir, :ansi_enabled, true)

# if function_exported?(Mix, :__info__, 1) and Mix.env() == :dev do
#   # if statement guards you from running it in prod, which could result in loss of logs.
#   Logger.configure_backend(:console, device: Process.group_leader())
# end

# vim:ft=elixir

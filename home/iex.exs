# REF:
# - https://github.com/cr0t/dotfiles/blob/master/dot.iex.exs
# - https://samuelmullen.com/articles/customizing_elixirs_iex/
# - https://www.adiiyengar.com/blog/20180709/my-iex-exs
# - https://github.com/blackode/elixir-tips#iex-custom-configuration---iex-decoration
# - https://github.com/blackode/custom-iex.git
# - https://youtu.be/KNqcfLUuPVc?t=151
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

IO.puts(IO.ANSI.light_blue() <> "󰬐 Using .iex.exs from #{__DIR__}/.iex.exs" <> IO.ANSI.reset())

import_if_available(Plug.Conn)
import_if_available(Ecto.UUID)
import_if_available(Ecto.Query)
import_if_available(Ecto.Changeset)
import_if_available(Phoenix.HTML)

history_size = 100

# Color Variables
# blue_ansi = IO.ANSI.blue()
green_ansi = IO.ANSI.green()
reset_ansi = IO.ANSI.reset()
white_background = IO.ANSI.white_background()
eval_result = [:green, :bright]
eval_error = [[:red, :bright, "\ue3bf [ERROR] - "]]
eval_info = [:blue, :bright]

defmodule U do
  def atoms? do
    limit = :erlang.system_info(:atom_limit)
    count = :erlang.system_info(:atom_count)

    IO.puts("Currently using #{count} / #{limit} atoms")
  end

  def cls, do: IO.puts("\ec")

  def raw(any, label \\ "iex") do
    IO.inspect(any,
      label: label,
      pretty: true,
      limit: :infinity,
      structs: false,
      syntax_colors: [
        number: :yellow,
        atom: :cyan,
        string: :green,
        nil: :magenta,
        boolean: :magenta
      ],
      width: 0
    )
  end

  # REF: https://github.com/gvaughn/dotfiles/blob/master/iex.exs
  def paste() do
    {res, _} = System.cmd("/usr/bin/pbpaste", [])
    res
  end

  def copy(val) do
    port = Port.open({:spawn_executable, "/usr/bin/pbcopy"}, [:binary, args: []])

    value =
      case val do
        val when is_binary(val) ->
          val

        val ->
          val
          |> Inspect.Algebra.to_doc(%Inspect.Opts{limit: :infinity, pretty: true})
          |> Inspect.Algebra.format(:infinity)
      end

    send(port, {self(), {:command, value}})
    send(port, {self(), :close})
    val
  end

  def generate_repo_alias(repo) do
    quote do
      alias unquote(repo), as: Repo
    end
  end
end

defmodule :_exit do
  defdelegate exit(), to: System, as: :halt
  defdelegate q(), to: System, as: :halt
end

defmodule :_restart do
  defdelegate restart(), to: System, as: :restart
end

defmodule :_util do
  defdelegate cls(), to: U, as: :cls
  defdelegate raw(any), to: U, as: :raw
  defdelegate atoms?(), to: U, as: :atoms?
  # defdelegate uuid(), to: U, as: :uuid
  defdelegate copy(any), to: U, as: :copy
  defdelegate cp(any), to: U, as: :copy
  defdelegate paste(), to: U, as: :paste
end

import :_exit
import :_restart
import :_util

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

  def print_tips() do
    print_bright("\n--- Tips & Tricks:")

    Enum.map(@tips_and_tricks, &IO.puts/1)
  end

  def wat?(term) when is_nil(term), do: "Type: Nil"
  def wat?(term) when is_binary(term), do: "Type: Binary"
  def wat?(term) when is_boolean(term), do: "Type: Boolean"
  def wat?(term) when is_atom(term), do: "Type: Atom"
  def wat?(_term), do: "Type: Unknown"
  def logger_debug(), do: Logger.configure(level: :debug)
  def logger_error(), do: Logger.configure(level: :error)
  def logger_warn(), do: Logger.configure(level: :warn)
  def logger_info(), do: Logger.configure(level: :info)

  def get_app_name() do
    app_name =
      if Mix.Project.umbrella?(),
        do:
          Mix.Project.apps_paths()
          |> Enum.reject(fn {_x, y} ->
            y == :undefined
          end)
          |> Enum.find(fn {x, _y} ->
            x |> Atom.to_string() |> String.ends_with?("_web")
          end)
          |> elem(0)
          |> Atom.to_string()
          |> String.replace("_web", ""),
        else: Mix.Project.get().project()[:app]

    if is_binary(app_name), do: String.to_atom(app_name), else: app_name
  end

  def write_phoenix_info(app_name) do
    phoenix_info =
      if H.is_app_started?(:phoenix) do
        IO.ANSI.green() <>
          "running (" <>
          IO.ANSI.light_yellow() <>
          "#{app_name}_web" <>
          IO.ANSI.reset() <>
          ")" <> IO.ANSI.reset()
      else
        IO.ANSI.yellow() <> "not detected" <> IO.ANSI.reset()
      end

    IO.puts("Phoenix: #{phoenix_info}")
  end

  def write_ecto_info(app_name) do
    ecto_started? = H.is_app_started?(:ecto)

    ecto_info =
      if ecto_started? do
        IO.ANSI.green() <> "running" <> IO.ANSI.reset()
      else
        IO.ANSI.yellow() <> "not detected" <> IO.ANSI.reset()
      end

    repo_info =
      if ecto_started? do
        repo =
          app_name
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

        import_if_available(Ecto.Query)
        import_if_available(Ecto.Changeset)

        U.generate_repo_alias(repo)

        IO.ANSI.faint() <> "(`alias #{repo}, as: Repo`)" <> IO.ANSI.reset()
      else
        ""
      end

    IO.puts("Ecto: #{ecto_info} #{repo_info}")
  end
end

prefix = IO.ANSI.green() <> "%prefix" <> IO.ANSI.reset()

counter =
  IO.ANSI.green() <>
    "[" <> IO.ANSI.light_blue() <> "%node" <> IO.ANSI.green() <> "](%counter)" <> IO.ANSI.reset()

info = IO.ANSI.light_blue() <> "#{H.queue_length()}" <> IO.ANSI.reset()
last = IO.ANSI.yellow() <> "" <> IO.ANSI.reset()
alive = IO.ANSI.bright() <> IO.ANSI.yellow() <> "󱐋" <> IO.ANSI.reset()

default_prompt = prefix <> counter <> " " <> info <> last
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

app_name = H.get_app_name()

H.write_phoenix_info(app_name)
H.write_ecto_info(app_name)

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

# Logger.remove_backend(:console)

# vim:ft=elixir

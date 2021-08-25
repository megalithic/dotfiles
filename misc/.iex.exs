Application.put_env(:elixir, :ansi_enabled, true)
#
# # Get queue length for the IEx process
# # This is fun to see while playing with nodes
# queue_length = fn ->
#   self()
#   |> Process.info()
#   |> Keyword.get(:message_queue_len)
# end
#
# prefix =
#   IO.ANSI.black_background() <>
#     IO.ANSI.green() <>
#     "%prefix" <>
#     IO.ANSI.reset()
#
# counter =
#   IO.ANSI.black_background() <>
#     IO.ANSI.green() <>
#     "-%node-(%counter)" <>
#     IO.ANSI.reset()
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
# default_prompt = prefix <> counter <> IO.ANSI.black() <> "│" <> IO.ANSI.reset() <> info <> last
#
# alive_prompt =
#   prefix <>
#     counter <>
#     IO.ANSI.black() <>
#     "│" <> IO.ANSI.reset() <> info <> IO.ANSI.black() <> "│" <> IO.ANSI.reset() <> alive <> last
#
history_size = 100

eval_result = [:green, :bright]
eval_error = [[:red, :bright, "\ue3bf ERROR - "]]
eval_info = [:blue, :bright]

defmodule IExHelpers do
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

# Configuring IEx
IEx.configure(
  inspect: [limit: :infinity, pretty: true, charlists: :as_lists],
  history_size: history_size,
  colors: [
    eval_result: eval_result,
    eval_error: eval_error,
    eval_info: eval_info
  ],
  # default_prompt: default_prompt,
  # alive_prompt: alive_prompt
)
#
# # Phoenix Support
# import_if_available(Plug.Conn)
# import_if_available(Phoenix.HTML)
#
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
#     IO.puts(
#       IO.ANSI.light_black() <>
#         IO.ANSI.faint() <> IO.ANSI.italic() <> "\uf05a  No Phoenix App found"
#     )
#
#   {app, _pid} ->
#     IO.puts("\uf05a  Phoenix app found: #{app}")
#
#     ecto_app =
#       app
#       |> Atom.to_string()
#       |> (&Regex.split(~r{_web}, &1)).()
#       |> Enum.at(0)
#       |> String.to_atom()
#
#     exists =
#       :application.info()
#       |> Keyword.get(:running)
#       |> Enum.reject(fn {_x, y} ->
#         y == :undefined
#       end)
#       |> Enum.map(fn {x, _y} -> x end)
#       |> Enum.member?(ecto_app)
#
#     # Check if Ecto app exists or running
#     case exists do
#       false ->
#         IO.puts(
#           IO.ANSI.light_black() <>
#             IO.ANSI.faint() <>
#             IO.ANSI.italic() <> "\uf05a  Ecto app #{ecto_app} doesn't exist or isn't running"
#         )
#
#       true ->
#         IO.puts(
#           IO.ANSI.light_black() <>
#             IO.ANSI.faint() <> IO.ANSI.italic() <> "\uf05a  Ecto app found: #{ecto_app}"
#         )
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
#
# vim:ft=elixir

defmodule WebServer do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.start_link(fn -> serve(client) end)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket |> read_line() |> write_line(socket)
    :ok = :gen_tcp.close(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    IO.puts("#{data}")

    cond do
      String.contains?(data, "/ ") == true ->
        index = File.read!("index.html")
        line = "HTTP/1.1 200 Ok\r\nContent-Type=text/html\r\n\r\n#{index}"

      true ->
        request = "." <> Enum.at(String.split(data, " "), 1) <> ".html"

        try do
          file = File.read!(request)
          line = "HTTP/1.1 200 Ok\r\nContent-Type=text/html\r\n\r\n#{file}"
        rescue
          File.Error ->
            fileNotFound = File.read!("404.html")
            line = "HTTP/1.1 200 Ok\r\nContent-Type=text/html\r\n\r\n#{fileNotFound}"
        end
    end

    # data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  def main(args \\ []) do
    accept(9999)
  end
end

Vim�UnDo� ;2�@|հ�x�����C�ز_��+��5   ~   U        label: "absinthe run result-------------------------------------------------"   N                          ]���    _�                    L       ����                                                                                                                                                                                                                                                                                                                                                             ]��w     �   L   N   t            �   L   N   s    5�_�                    M       ����                                                                                                                                                                                                                                                                                                                                                             ]��y     �   L   N   t               |> IO.inspect(label: "")5�_�                   M   %    ����                                                                                                                                                                                                                                                                                                                                       t          V       ]���     �   L   N   t      2        |> IO.inspect(label: "absinth run result")5�_�                    M   %    ����                                                                                                                                                                                                                                                                                                                                       t          V       ]���     �   L   N   t      3        |> IO.inspect(label: "absinths run result")5�_�                    M   1    ����                                                                                                                                                                                                                                                                                                                                       t          V       ]���    �   L   N   t      3        |> IO.inspect(label: "absinthe run result")5�_�                    M   a    ����                                                                                                                                                                                                                                                                                                                                       t          V       ]���    �   t            �   s   u          end�   r   t          2  defp prepare_telemetry(telemetry), do: telemetry�   q   s          ,  # Everything else, including regular maps.�   p   r           �   o   q          Q  defp prepare_telemetry(%{} = telemetry), do: Map.delete(telemetry, :__struct__)�   n   p          L  # This is also why we're using `Map.delete` rather than `Map.from_struct`.�   m   o          J  # don't exist in VPP and therefore VPP doesn't recognize it as a struct.�   l   n          K  # because in some cases the adapters will send over structs whose modules�   k   m          K  # This intentionally matches the map rather than the wildcard struct %_{}�   j   l          E  # Handles structs if an adapter tries to send one instead of a map.�   i   k           �   h   j            end�   g   i              :ok�   f   h          K    Logger.error("Unrecognized telemetry, ignoring: #{inspect(telemetry)}")�   e   g            defp dispatch(telemetry) do�   d   f           �   c   e            end�   b   d              )�   a   c                length(telemetry)�   `   b          *      System.monotonic_time(:millisecond),�   _   a                ReceivingRate,�   ^   `          '    Api.Utils.RateTracker.record_count(�   ]   _           �   \   ^          %    Enum.each(telemetry, &dispatch/1)�   [   ]          @    # List of telemetry.  Distribute each in the original order.�   Z   \          5  defp dispatch(telemetry) when is_list(telemetry) do�   Y   [           �   X   Z            end�   W   Y              :ok�   V   X           �   U   W          :    |> Topology.Telemetry.distribute_as_telemetry_record()�   T   V              |> prepare_telemetry()�   S   U              telemetry�   R   T          4  defp dispatch(telemetry) when is_map(telemetry) do�   Q   S           �   P   R            end�   O   Q              end)�   N   P          #      GenServer.reply(from, result)�   M   O           �   L   N          d        |> IO.inspect(label: "absinthe run result-------------------------------------------------")�   K   M          a        Absinthe.run(query, Api.Schema, variables: variables, context: %{current_user_id: "vpp"})�   J   L                result =�   I   K           �   H   J                )�   G   I          !        number_of_running_queries�   F   H          L        "execute_graphql_operation_message_supervisor.in_progress_children",�   E   G                EnbalaMetrics.gauge(�   D   F           �   C   E          \        Api.ExecuteGraphQLOperationMessageSupervisor |> Task.Supervisor.children() |> length�   B   D          !      number_of_running_queries =�   A   C          S    Task.Supervisor.start_child(Api.ExecuteGraphQLOperationMessageSupervisor, fn ->�   @   B          6  defp async_execute(from, query, variables \\ %{}) do�   ?   A           �   >   @            end�   =   ?              {:noreply, :ok}�   <   >           �   ;   =              end)�   :   <                }"�   9   ;          #        inspect(unexpected_message)�   8   :          P      "Unexpected messages received in Api.GlobalMessageReceiver.handle_cast: #{�   7   9              Logger.error(fn ->�   6   8          -  def handle_cast(unexpected_message, :ok) do�   5   7           �   4   6            end�   3   5              {:noreply, :ok}�   2   4              :ok = dispatch(telemetry)�   1   3          7  def handle_cast({:send_telemetry, telemetry}, :ok) do�   0   2           �   /   1            end�   .   0          0    {:reply, {:error, :unexpected_message}, :ok}�   -   /           �   ,   .              end)�   +   -                }"�   *   ,          #        inspect(unexpected_message)�   )   +          P      "Unexpected messages received in Api.GlobalMessageReceiver.handle_call: #{�   (   *              Logger.error(fn ->�   '   )          4  def handle_call(unexpected_message, _from, :ok) do�   &   (           �   %   '            end�   $   &              {:reply, :ok, :ok}�   #   %              :ok = dispatch(telemetry)�   "   $          >  def handle_call({:send_telemetry, telemetry}, _from, :ok) do�   !   #           �       "            end�      !              {:noreply, :ok}�                  �                -    async_execute(from, graphql_query, input)�                &      when is_binary(graphql_query) do�                P  def handle_call({:execute_graphql_operation, graphql_query, input}, from, :ok)�                 �                  end�                    {:noreply, :ok}�                 �                &    async_execute(from, graphql_query)�                &      when is_binary(graphql_query) do�                I  def handle_call({:execute_graphql_operation, graphql_query}, from, :ok)�                 �                  end�                    {:ok, :ok}�                '    :global.register_name(:vpp, self())�                 �                J    Logger.debug(fn -> "Starting #{__MODULE__} at #{inspect(self())}" end)�                  def init(:ok) do�                 �                  end�   
             ;    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)�   	               def start_link do�      
           �      	            require Logger�                 �                  use GenServer�                 �                  """�                  Handles incoming telemetry�                  @moduledoc """�                 &defmodule Api.GlobalMessageReceiver do5�_�                    I        ����                                                                                                                                                                                                                                                                                                                            M          O          V       ]��l     �   I   J                �   J   N   w    �   J   K   w    �   I   K   w            �   I   K   v    5�_�                    J       ����                                                                                                                                                                                                                                                                                                                            P          R          V       ]��n     �   I   K   y            |> IO.inspect(5�_�                    J       ����                                                                                                                                                                                                                                                                                                                            P          R          V       ]��p     �   I   K   y            IO.inspect(5�_�                    I        ����                                                                                                                                                                                                                                                                                                                            J          L          V       ]��u     �   I   J                �   J   N   z    �   J   K   z    �   I   K   z            �   I   K   y    5�_�                    J       ����                                                                                                                                                                                                                                                                                                                            M          O          V       ]��w     �   I   K   |            IO.inspect(variables,5�_�                    K       ����                                                                                                                                                                                                                                                                                                                            M          O          V       ]��{     �   J   L   |      U        label: "absinthe run result-------------------------------------------------"5�_�                    N       ����                                                                                                                                                                                                                                                                                                                            M          O          V       ]��}     �   M   O   |      U        label: "absinthe run result-------------------------------------------------"5�_�                    N       ����                                                                                                                                                                                                                                                                                                                            M          O          V       ]��}    �   M   O   |      G        label: "query-------------------------------------------------"5�_�                     N       ����                                                                                                                                                                                                                                                                                                                            M          O          V       ]���    �   |            �   {   }          end�   z   |          2  defp prepare_telemetry(telemetry), do: telemetry�   y   {          ,  # Everything else, including regular maps.�   x   z           �   w   y          Q  defp prepare_telemetry(%{} = telemetry), do: Map.delete(telemetry, :__struct__)�   v   x          L  # This is also why we're using `Map.delete` rather than `Map.from_struct`.�   u   w          J  # don't exist in VPP and therefore VPP doesn't recognize it as a struct.�   t   v          K  # because in some cases the adapters will send over structs whose modules�   s   u          K  # This intentionally matches the map rather than the wildcard struct %_{}�   r   t          E  # Handles structs if an adapter tries to send one instead of a map.�   q   s           �   p   r            end�   o   q              :ok�   n   p          K    Logger.error("Unrecognized telemetry, ignoring: #{inspect(telemetry)}")�   m   o            defp dispatch(telemetry) do�   l   n           �   k   m            end�   j   l              )�   i   k                length(telemetry)�   h   j          *      System.monotonic_time(:millisecond),�   g   i                ReceivingRate,�   f   h          '    Api.Utils.RateTracker.record_count(�   e   g           �   d   f          %    Enum.each(telemetry, &dispatch/1)�   c   e          @    # List of telemetry.  Distribute each in the original order.�   b   d          5  defp dispatch(telemetry) when is_list(telemetry) do�   a   c           �   `   b            end�   _   a              :ok�   ^   `           �   ]   _          :    |> Topology.Telemetry.distribute_as_telemetry_record()�   \   ^              |> prepare_telemetry()�   [   ]              telemetry�   Z   \          4  defp dispatch(telemetry) when is_map(telemetry) do�   Y   [           �   X   Z            end�   W   Y              end)�   V   X          #      GenServer.reply(from, result)�   U   W           �   T   V          	        )�   S   U          W          label: "absinthe run result-------------------------------------------------"�   R   T                  |> IO.inspect(�   Q   S          a        Absinthe.run(query, Api.Schema, variables: variables, context: %{current_user_id: "vpp"})�   P   R                result =�   O   Q           �   N   P                )�   M   O          K        label: "variables-------------------------------------------------"�   L   N                IO.inspect(variables,�   K   M                )�   J   L          G        label: "query-------------------------------------------------"�   I   K                IO.inspect(query,�   H   J                )�   G   I          !        number_of_running_queries�   F   H          L        "execute_graphql_operation_message_supervisor.in_progress_children",�   E   G                EnbalaMetrics.gauge(�   D   F           �   C   E          \        Api.ExecuteGraphQLOperationMessageSupervisor |> Task.Supervisor.children() |> length�   B   D          !      number_of_running_queries =�   A   C          S    Task.Supervisor.start_child(Api.ExecuteGraphQLOperationMessageSupervisor, fn ->�   @   B          6  defp async_execute(from, query, variables \\ %{}) do�   ?   A           �   >   @            end�   =   ?              {:noreply, :ok}�   <   >           �   ;   =              end)�   :   <                }"�   9   ;          #        inspect(unexpected_message)�   8   :          P      "Unexpected messages received in Api.GlobalMessageReceiver.handle_cast: #{�   7   9              Logger.error(fn ->�   6   8          -  def handle_cast(unexpected_message, :ok) do�   5   7           �   4   6            end�   3   5              {:noreply, :ok}�   2   4              :ok = dispatch(telemetry)�   1   3          7  def handle_cast({:send_telemetry, telemetry}, :ok) do�   0   2           �   /   1            end�   .   0          0    {:reply, {:error, :unexpected_message}, :ok}�   -   /           �   ,   .              end)�   +   -                }"�   *   ,          #        inspect(unexpected_message)�   )   +          P      "Unexpected messages received in Api.GlobalMessageReceiver.handle_call: #{�   (   *              Logger.error(fn ->�   '   )          4  def handle_call(unexpected_message, _from, :ok) do�   &   (           �   %   '            end�   $   &              {:reply, :ok, :ok}�   #   %              :ok = dispatch(telemetry)�   "   $          >  def handle_call({:send_telemetry, telemetry}, _from, :ok) do�   !   #           �       "            end�      !              {:noreply, :ok}�                  �                -    async_execute(from, graphql_query, input)�                &      when is_binary(graphql_query) do�                P  def handle_call({:execute_graphql_operation, graphql_query, input}, from, :ok)�                 �                  end�                    {:noreply, :ok}�                 �                &    async_execute(from, graphql_query)�                &      when is_binary(graphql_query) do�                I  def handle_call({:execute_graphql_operation, graphql_query}, from, :ok)�                 �                  end�                    {:ok, :ok}�                '    :global.register_name(:vpp, self())�                 �                J    Logger.debug(fn -> "Starting #{__MODULE__} at #{inspect(self())}" end)�                  def init(:ok) do�                 �                  end�   
             ;    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)�   	               def start_link do�      
           �      	            require Logger�                 �                  use GenServer�                 �                  """�                  Handles incoming telemetry�                  @moduledoc """�                 &defmodule Api.GlobalMessageReceiver do5�_�                   J        ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   I   J   t            �   I   K   u                IO.inspect5�_�                    K       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L   v            IO.inspect()5�_�                    K       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L   v            IO.inspect({})5�_�                    K       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L                IO.inspect({})5�_�      	              K       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L   v            IO.inspect()5�_�      
           	   K       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L   v      $      IO.inspect(variables, label: )5�_�   	              
   K   #    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L   v      &      IO.inspect(variables, label: "")5�_�   
                 K   $    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   J   L   v      =      IO.inspect(variables, label: "async_execute variables")5�_�                    K   ;    ����                                                                                                                                                                                                                                                                                                                                                             ]��    �   J   L   v      =      IO.inspect(variables, label: "async_execute variables")5�_�                    K   "    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   K   L   v            �   K   M   w            �   L   M   w    �   L   M   w      =      IO.inspect(variables, label: "async_execute variables")�   K   M        5�_�                    L       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   K   M   w      9      IO.inspect(query, label: "async_execute variables")5�_�                    L   .    ����                                                                                                                                                                                                                                                                                                                                       w          V       ]���    �   K   M   w      5      IO.inspect(query, label: "async_execute query")5�_�                            ����                                                                                                                                                                                                                                                                                                                                                 V       ]���     �      x        �                  5�_�                     L       ����                                                                                                                                                                                                                                                                                                                                                             ]��r     �   L   M   s       5��
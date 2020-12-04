Vim�UnDo� n���k;�7�����w5F[����C��%�]   (   Y    Logger.debug("The supervisor knows about it, but it's currently being restarted" end)            !       !   !   !    ]���    _�                             ����                                                                                                                                                                                                                                                                                                                                                  V        ]��;     �                         �       &   )    �       !   )    �      !   )              �      !   (    5�_�                    !       ����                                                                                                                                                                                                                                                                                                                            !          !          v       ]���     �       "   -              {:error, reason} ->�   !   "   -    5�_�                    !       ����                                                                                                                                                                                                                                                                                                                            !          !   )       v       ]���     �       "   -      -        {:error, {:error, :fuse_is_blown}} ->5�_�                   !        ����                                                                                                                                                                                                                                                                                                                            !          !   )       v       ]���     �       "   -      $        {:error, :fuse_is_blown}} ->5�_�                    !        ����                                                                                                                                                                                                                                                                                                                            !           $          V        ]���    �       %   -      #        {:error, :fuse_is_blown} ->             Logger.error(   \            "Encountered an error starting the VPP sub-supervision tree: #{inspect(reason)}"             )5�_�                             ����                                                                                                                                                                                                                                                                                                                                        $   	       V       ]���     �                     !      {:error, :fuse_is_blown} ->           Logger.error(   Z          "Encountered an error starting the VPP sub-supervision tree: #{inspect(reason)}"   	        )5�_�      	                      ����                                                                                                                                                                                                                                                                                                                                            	       V       ]���     �                        �      !   )    �         )    �         )              �         (    5�_�                 	           ����                                                                                                                                                                                                                                                                                                                                                  V        ]���    �          -          #        {:error, :fuse_is_blown} ->             Logger.error(   \            "Encountered an error starting the VPP sub-supervision tree: #{inspect(reason)}"             )5�_�   	      
             G    ����                                                                                                                                                                                                                                                                                                                                                  V        ]���    �         -      Z          "Encountered an error starting the VPP sub-supervision tree: #{inspect(reason)}"5�_�                       K    ����                                                                                                                                                                                                                                                                                                                                                  V        ]���     �         -      U          "Encountered an error starting the VPP sub-supervision tree: fuse is blown"5�_�                       N    ����                                                                                                                                                                                                                                                                                                                                                  V        ]���    �         -      U          "Encountered an error starting the VPP sub-supervision tree: fuse_is blown"5�_�                       N    ����                                                                                                                                                                                                                                                                                                                                                  V        ]���    �   +                end   end�   *   ,              end�   )   +          1        Logger.info("Started at #{inspect(pid)}")�   (   *                {:ok, pid, _} ->�   '   )           �   &   (          1        Logger.info("Started at #{inspect(pid)}")�   %   '                {:ok, pid} ->�   $   &           �   #   %          	        )�   "   $          Z          "Encountered an error starting the VPP sub-supervision tree: #{inspect(reason)}"�   !   #                  Logger.error(�       "                {:error, reason} ->�      !           �                 	        )�                U          "Encountered an error starting the VPP sub-supervision tree: fuse_is_blown"�                        Logger.error(�                !      {:error, :fuse_is_blown} ->�                 �                X        Logger.info("The supervisor knows about it, but it's currently being restarted")�                #      {:error, :already_present} ->�                 �                V        Logger.info("Sub-supervision tree for VPP already started at #{inspect(pid)}")�                *      {:error, {:already_started, pid}} ->�                M    case Supervisor.start_child(__MODULE__, VppSupervisor.child_spec(vpp)) do�                 �                Y    Logger.info("Starting a dynamic sub-supervision tree for VPP: #{Map.get(vpp, "id")}")�                  def start_vpp(vpp) do�                 �                  end�                /    Supervisor.init([], strategy: :one_for_one)�                  def init(_) do�                 �                  end�   
             ;    Supervisor.start_link(__MODULE__, [], name: __MODULE__)�   	               def start_link(_) do�      
           �      	            require Logger�                 �                  use Supervisor�                (  alias Iec60870TsoAdapter.VppSupervisor�                  """�                P  Spins up dynamic supervisors (not a DynamicSupervisor), for each retrieved VPP�                  @moduledoc """�                 4defmodule Iec60870TsoAdapter.VppDynamicSupervisor do5�_�                       R    ����                                                                                                                                                                                                                                                                                                                                                  V        ]���    �         +      a        Logger.error("Encountered an error starting the VPP sub-supervision tree: fuse_is_blown")5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V   R    ]���    �                !      {:error, :fuse_is_blown} ->   b        Logger.error("Encountered an error starting the VPP sub-supervision tree: :fuse_is_blown")    5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]��    �         (      Y    Logger.info("Starting a dynamic sub-supervision tree for VPP: #{Map.get(vpp, "id")}")5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]��     �         (      V        Logger.info("Sub-supervision tree for VPP already started at #{inspect(pid)}")5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]��     �         (      X        Logger.info("The supervisor knows about it, but it's currently being restarted")5�_�                    "       ����                                                                                                                                                                                                                                                                                                                                                             ]��     �   !   #   (      1        Logger.info("Started at #{inspect(pid)}")5�_�                    %       ����                                                                                                                                                                                                                                                                                                                                                             ]��   	 �   $   &   (      1        Logger.info("Started at #{inspect(pid)}")5�_�                    "       ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   !   #   (      2        Logger.debug("Started at #{inspect(pid)}")5�_�                    "   7    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   !   #   (      K        Logger.debug("Started sub-supervision tree for at #{inspect(pid)}")5�_�                    "   =    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �   !   #   (      O        Logger.debug("Started sub-supervision tree for VPP at #{inspect(pid)}")5�_�                    %        ����                                                                                                                                                                                                                                                                                                                            %   1       %   1       V   @    ]���     �   $   %                  �   %   '   (    �   %   &   (    �   $   &   (      2        Logger.debug("Started at #{inspect(pid)}")5�_�                    %       ����                                                                                                                                                                                                                                                                                                                            %   1       %   1       V   @    ]���     �   $   &   (      S        Logger.debug("Started sub-supervision tree for VPP at PID #{inspect(pid)}")5�_�                    "       ����                                                                                                                                                                                                                                                                                                                            %   1       %   1       V   @    ]���    �   !   #   (      S        Logger.debug("Started sub-supervision tree for VPP at PID #{inspect(pid)}")5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]���     �         (      Z    Logger.debug("Starting a dynamic sub-supervision tree for VPP: #{Map.get(vpp, "id")}")5�_�                       _    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �         (      `    Logger.debug(fn -> "Starting a dynamic sub-supervision tree for VPP: #{Map.get(vpp, "id")}")5�_�                       V    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �         (      W        Logger.debug("Sub-supervision tree for VPP already started at #{inspect(pid)}")5�_�                        X    ����                                                                                                                                                                                                                                                                                                                                                             ]���     �         (      Y        Logger.debug("The supervisor knows about it, but it's currently being restarted")5�_�      !                      ����                                                                                                                                                                                                                                                                                                                                                             ]���     �         (      [        Logger.debug("Sub-supervision tree for VPP already started at #{inspect(pid)}" end)5�_�                   !          ����                                                                                                                                                                                                                                                                                                                                                             ]���    �         (      Y    Logger.debug("The supervisor knows about it, but it's currently being restarted" end)5�_�   	              
           ����                                                                                                                                                                                                                                                                                                                                                  V        ]���     �          -              {:error, :fuse_is_blown} ->         Logger.error(   X        "Encountered an error starting the VPP sub-supervision tree: #{inspect(reason)}"         )5�_�                    !   "    ����                                                                                                                                                                                                                                                                                                                            !          !   )       v       ]���     �       "   -      #        {:error, :fuse_is_blown}} >5��
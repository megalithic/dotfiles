Vim�UnDo� �Bʐ;[������T�G+�3z�E^߮�z��   �   end   �                           ]M�g    _�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]L8�     �                  �         �    �         �    �         �        �         �    5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]L8�     �                 5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]L8�    �         �    5�_�                       
    ����                                                                                                                                                                                                                                                                                                                                                V       ]L8�    �         �      
  # cancel5�_�                          ����                                                                                                                                                                                                                                                                                                                                                V       ]L8�    �                  �         �    �         �    �         �        �         �    5�_�      	                     ����                                                                                                                                                                                                                                                                                                                                         9       v   9    ]L8�     �         �      :  @typep result :: {:ok, Model.t()} | {:error, String.t()}5�_�      
           	      "    ����                                                                                                                                                                                                                                                                                                                               "          '       v   '    ]L8�     �         �      (  @callback cancel(Model.id()) :: result�         �    5�_�   	              
          ����                                                                                                                                                                                                                                                                                                                               "          H       v   '    ]L9     �                  @typep result :: 5�_�   
                        ����                                                                                                                                                                                                                                                                                                                               "          H       v   '    ]L9    �                  �         �    �         �    �         �        �         �    5�_�                            ����                                                                                                                                                                                                                                                                                                                                                 V       ]LX    �                      # cancel behaviour callback     alias Topology.Utils.Model   I  @callback cancel(Model.id()) :: {:ok, Model.t()} | {:error, String.t()}5�_�                    m       ����                                                                                                                                                                                                                                                                                                                            m          m   %       v   %    ]L]�    �   l   n   �      0      current_time = CommonUtils.VTime.utc_now()5�_�                   q       ����                                                                                                                                                                                                                                                                                                                            o          |          V       ]M�A     �   p   r   �              �   p   r   �    5�_�                    q   �    ����                                                                                                                                                                                                                                                                                                                            o          }          V       ]M�Z     �   p   r   �      �        TODO: can we just use the front-end to draw the truncation \via the cancelled_at instead of actual destructive mutation of data5�_�                    q   �    ����                                                                                                                                                                                                                                                                                                                            o          }          V       ]M�\    �   p   r          �        TODO: can we just use the front-end to draw the truncation \via the cancelled_at instead of actual destructive mutation of data?5�_�                    q   E    ����                                                                                                                                                                                                                                                                                                                            o          }          V       ]M�_     �   p   r   �      �        # TODO: can we just use the front-end to draw the truncation \via the cancelled_at instead of actual destructive mutation of data?5�_�                    q   E    ����                                                                                                                                                                                                                                                                                                                            o          }          V       ]M�a    �   p   r          E        # TODO: can we just use the front-end to draw the truncation �   p   s   �      �        # TODO: can we just use the front-end to draw the truncation via the cancelled_at instead of actual destructive mutation of data?5�_�                    q       ����                                                                                                                                                                                                                                                                            r                                              o          ~          V       ]M�c    �   p   r   �    5�_�                     q        ����                                                                                                                                                                                                                                                                            s                                              o                    V       ]M�f    �   �              end�   �   �            end�   �   �              end�   �   �          	      end�   �   �          @        {:error, "cannot cancel a need that is not in progress"}�   �   �          
      else�   �   �          	        )�   �   �                    @deps�   �   �          %          [:validate_start_datetime],�   �   �                    },�      �          )            :end_datetime => current_time�   ~   �          *            :cancelled_at => current_time,�   }             6            :control_points => updated_control_points,�   |   ~                    %{�   {   }                    id,�   z   |                  update(�   y   {           �   x   z          O          |> Enum.concat([%{:power => {:watts, 0}, :datetime => current_time}])�   w   y                    end)�   v   x          K            CommonUtils.VTime.before?(control_point.datetime, current_time)�   u   w          ,          |> Enum.filter(fn control_point ->�   t   v                    need.control_points�   s   u                   updated_control_points =�   r   t          N        # via the cancelled_at instead of actual destructive mutation of data?�   q   s          D        # TODO: can we just use the front-end to draw the truncation�   p   r           �   o   q          I           CommonUtils.VTime.after?(current_time, need.start_datetime) do�   n   p          G      if CommonUtils.VTime.before?(current_time, need.end_datetime) and�   m   o           �   l   n          '      current_time = DateTime.utc_now()�   k   m          ,    with {:ok, need} <- NeedStore.get(id) do�   j   l            def cancel(%{id: id}) do�   i   k           �   h   j            end�   g   i              end�   f   h                }�   e   g          X        needs: Enum.slice(all_needs, (page_number - 1) * count_per_page, count_per_page)�   d   f          '        total_count: length(all_needs),�   c   e                %{�   b   d          =    with all_needs when is_list(all_needs) <- all(filters) do�   a   c          Y  def paginated(%{page_number: page_number, count_per_page: count_per_page} = filters) do�   `   b           �   _   a            end�   ^   `              {:error, :not_implemented}�   ]   _          "  def update_by_remote_id(_, _) do�   \   ^          *  # @impl Topology.Utils.ResourceBehaviour�   [   ]           �   Z   \            end�   Y   [              {:error, :not_implemented}�   X   Z            def get_by_remote_id(_) do�   W   Y          *  # @impl Topology.Utils.ResourceBehaviour�   V   X           �   U   W            end�   T   V              {:error, :not_implemented}�   S   U            def delete_by_remote_id(_) do�   R   T          *  # @impl Topology.Utils.ResourceBehaviour�   Q   S           �   P   R            end�   O   Q              {:error, :missing_vpp_id}�   N   P            def all(_filters) do�   M   O          *  # @impl Topology.Utils.ResourceBehaviour�   L   N           �   K   M            end�   J   L          #    Vpps.all_needs(vpp_id, filters)�   I   K          A  def all(%{vpp_id: vpp_id} = filters) when not is_nil(vpp_id) do�   H   J          *  # @impl Topology.Utils.ResourceBehaviour�   G   I           �   F   H            end�   E   G              end�   D   F                _ -> []�   C   E              else�   B   D                |> all()�   A   C          !      |> Map.put(:vpp_id, vpp_id)�   @   B          #      |> Map.delete(:vpp_remote_id)�   ?   A                filters�   >   @          I    with {:ok, %_{id: vpp_id}} <- Vpps.get_by_remote_id(vpp_remote_id) do�   =   ?          V  def all(%{vpp_remote_id: vpp_remote_id} = filters) when not is_nil(vpp_remote_id) do�   <   >          *  # @impl Topology.Utils.ResourceBehaviour�   ;   =           �   :   <            end�   9   ;              end�   8   :                {:ok, need}�   7   9          /      deps.need_actions.update(need_id, params)�   6   8          Y    with {:ok, need} <- NeedStore.update(deps.registry, need_id, params, skip_options) do�   5   7          C  def update(need_id, params, skip_options \\ [], deps \\ @deps) do�   4   6          *  # @impl Topology.Utils.ResourceBehaviour�   3   5           �   2   4            end�   1   3              end�   0   2          4      {:ok, Vpps.need_with_max_capacity(need, deps)}�   /   1          1    with {:ok, need} <- NeedStore.get(need_id) do�   .   0          $  def get(need_id, deps \\ @deps) do�   -   /          *  # @impl Topology.Utils.ResourceBehaviour�   ,   .           �   +   -            end�   *   ,          %    deps.need_actions.delete(need_id)�   )   +          ,    NeedStore.delete(deps.registry, need_id)�   (   *          '  def delete(need_id, deps \\ @deps) do�   '   )          *  # @impl Topology.Utils.ResourceBehaviour�   &   (           �   %   '            end�   $   &              {:error, :missing_vpp_id}�   #   %          .  def create(_params, _skip_options, _deps) do�   "   $          *  # @impl Topology.Utils.ResourceBehaviour�   !   #           �       "            end�      !              end�                       {:ok, need}�                D      need |> Map.put(:vpp_id, vpp_id) |> deps.need_actions.create()�                P    with {:ok, need} <- NeedStore.create(deps.registry, params, skip_options) do�                W  def create(%{vpp_id: vpp_id} = params, skip_options, deps) when not is_nil(vpp_id) do�                *  # @impl Topology.Utils.ResourceBehaviour�                 �                  end�                    end�                #      |> create(skip_options, deps)�                !      |> Map.put(:vpp_id, vpp_id)�                #      |> Map.delete(:vpp_remote_id)�                      params�                I    with {:ok, %_{id: vpp_id}} <- Vpps.get_by_remote_id(vpp_remote_id) do�                '      when not is_nil(vpp_remote_id) do�                J  def create(%{vpp_remote_id: vpp_remote_id} = params, skip_options, deps)�                *  # @impl Topology.Utils.ResourceBehaviour�                 �                7  def create(params, skip_options \\ [], deps \\ @deps)�                 �                  }�   
                  vpp_twin: Topology.Vpps.Twin�   	             %    registry: Topology.Vpps.Registry,�      
          ,    need_actions: Topology.Data.NeedActions,�      	          
  @deps %{�                 �                  alias Topology.Vpps.NeedStore�                  alias Topology.Vpps�                 �                -  @behaviour Topology.Utils.ResourceBehaviour�                3  @moduledoc "Interface for `Api.ResourceResolver`"�                  defmodule Topology.Vpps.Needs do5�_�                    m       ����                                                                                                                                                                                                                                                                                                                            o          |          V       ]Mټ   	 �   l   n   �      $      current_time = VTime.utc_now()5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]L8�     �         �        @callback cancel(Model.id())5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]L8q     �         �       5��
Vim�UnDo� vO���t��P@?����%�U�ck�w���_�   
     def is_iso8601(date) do                             ]�RY    _�                             ����                                                                                                                                                                                                                                                                                                                                                             ]�Q�     �                   �               5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                 def is_date?(date) do   !  case Date.from_iso8601(date) do       {:ok, _} -> true       _ -> false     end   end5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                 �              5�_�                       	    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                defmodule  do�                	defmodule5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                  �      
       �             �                 �             5�_�                           ����                                                                                                                                                                                                                                                                                                                            
           
           V        ]�Q�     �                  5�_�      	                     ����                                                                                                                                                                                                                                                                                                                            	           	           V        ]�Q�     �         
        �         	    5�_�      
          	          ����                                                                                                                                                                                                                                                                                                                            
           
           V        ]�Q�     �         
        @defmodule5�_�   	              
          ����                                                                                                                                                                                                                                                                                                                            
           
           V        ]�Q�     �         
        @moduledoc5�_�   
                    	    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                 Helper utilities for date5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                 Helper utils for date5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                 Helper utils for date related5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                 Helper utils for Date related5�_�                       %    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �               %  Helper utils for Date related needs5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�    �             5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                  �                end�   
               end�   	                 end�      
                _ -> false�      	                {:ok, _} -> true�                #    case Date.from_iso8601(date) do�                  def is_date?(date) do�                 �                  """�                &  Helper utils for Date related needs.�                  @moduledoc """�                 *defmodule Iec60870TsoAdapter.Utils.Date do5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                  *defmodule Iec60870TsoAdapter.Utils.Date do     @moduledoc """   &  Helper utils for Date related needs.     """         def is_date?(date) do   #    case Date.from_iso8601(date) do         {:ok, _} -> true         _ -> false       end     end   end5�_�                       '    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                *defmodule Iec60870TsoAdapter.Utils.Date do5�_�                       #    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�Q�     �                0defmodule Iec60870TsoAdapter.Utils.DateHelper do5�_�                       #    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�R     �                &defmodule Iec60870TsoAdapter.Utils. do5�_�                       #    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�R     �                +defmodule Iec60870TsoAdapter.Utils.TDate do5�_�                       #    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�R%    �                /defmodule Iec60870TsoAdapter.Utils.DateCherk do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�R/     �                 @moduledoc """5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]�R0    �                &  Helper utils for Date related needs.     """5�_�                       	    ����                                                                                                                                                                                                                                                                                                                                                V       ]�RE     �         
        def is_date?(date) do5�_�                          ����                                                                                                                                                                                                                                                                                                                                                V       ]�RW     �         
        def is_iso8601(date) do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]�RX     �         
        def is_iso8601(?date) do5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]�RX    �         
        def is_iso8601(date) do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]�RO    �         
      $    case Date.from_iso8601?(date) do5�_�              	             ����                                                                                                                                                                                                                                                                                                                            �           �           V        ]�Q�     �         
   �   (  @defmodule Api.Integration.VppsTest do     use Api.IntegrationCase         alias Topology.Factory   (  alias DataPersist.Query.ControlMessage         @create_query """   '    mutation($input: CreateVppInput!) {          createVpp(input: $input) {           vpp {             id             assetCount             assets { id }             siteCount             sites { id }             goal             vppProportionalGain   $          assetStorageCostHysteresis             name   	        }         }       }     """         @fetch_all_query """       query {         allVpps {   
        id           assetCount           assets {             id             name   	        }           goal           name           remoteId           siteCount         }       }     """         describe "getting a vpp" do       setup do         remote_id = "my-vpp"         sr_remote_id = "sr-vpp"             {:ok, %{id: id}} =   Z        Topology.Vpps.create(%{name: "foo", remote_id: remote_id, goal: :demand_response})             {:ok, %{id: sr_id}} =   b        Topology.Vpps.create(%{name: "sr foo", remote_id: sr_remote_id, goal: :secondary_reserve})       O      %{id: id, remote_id: remote_id, sr_id: sr_id, sr_remote_id: sr_remote_id}       end       "    test "get by id", %{id: id} do         query = """           query {             vpp(id: "#{id}") {               name             }   	        }   	      """       ;      {:ok, %{data: %{"vpp" => vpp}}} = exec_graphql(query)       !      assert vpp["name"] == "foo"       end       7    test "get by remote id", %{remote_id: remote_id} do         query = """           query {   )          vpp(remoteId: "#{remote_id}") {               name             }   	        }   	      """       ;      {:ok, %{data: %{"vpp" => vpp}}} = exec_graphql(query)       !      assert vpp["name"] == "foo"       end       D    test "get by secondary reserve vpp id and return valid ABLs", %{         sr_id: sr_id,          sr_remote_id: sr_remote_id       } do         query = """           query {   ,          vpp(remoteId: "#{sr_remote_id}") {               name                assetBaselineData  {                 power               }               id               remoteId             }   	        }   	      """             remote_id = Factory.id()             {:ok, gen1} =   !        Topology.Assets.create(%{             name: "Asset 1",             type: :generator,             remote_id: remote_id,   9          baseline_power_forecast_default: {:watts, 1000}   
        })             {:ok, gen2} =   !        Topology.Assets.create(%{             name: "Asset 2",             type: :generator,   8          baseline_power_forecast_default: {:watts, 800}   
        })       4      need = Factory.create(:need, %{vpp_id: sr_id})             {:ok, cm} =            ControlMessage.create(%{             need_id: need.id,             remote_id: remote_id,             duration: 90,             power: 700,             unit: "watts",             absolute_setpoint: 0,   &          starting_at: VTime.utc_now()   
        })       ]      {:ok, _vpp} = Topology.Vpps.update(sr_id, %{asset_ids: MapSet.new([gen1.id, gen2.id])})       ;      {:ok, %{data: %{"vpp" => vpp}}} = exec_graphql(query)       ,      assert vpp["remoteId"] == sr_remote_id         assert vpp["id"] == sr_id   $      assert vpp["name"] == "sr foo"   .      assert is_list(vpp["assetBaselineData"])         asser5��
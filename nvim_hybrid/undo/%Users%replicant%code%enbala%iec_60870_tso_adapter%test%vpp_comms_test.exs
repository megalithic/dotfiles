Vim�UnDo� ��]]���q^��*�:�ˢ���Ą��!�ْ�                     .       .   .   .    ]�9    _�                             ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                   5�_�                       	    ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                defmodule  do�                  	defmodule5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                 �                defmodule Iec104 do5�_�                       
    ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                defmodule Iec104 do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                 defmodule Iec60870TsoAdapter do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                  kLhhhh5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             ]�5�     �                  �      )       �             �                 �             5�_�      	              	        ����                                                                                                                                                                                                                                                                                                                            	                     V       ]�5�     �      	       	       e  test "build_simulation_determination_query generates a GraphQL VPP query block with a remote_id" do       remote_id = UUID.uuid4()       #    {_query, %{"input" => input}} =   F      VppControlPoints.build_simulation_determination_query(remote_id)       )    assert input["remoteId"] == remote_id     end5�_�      
           	          ����                                                                                                                                                                                                                                                                                                                            	           	          V       ]�5�    �      	         0  alias Iec60870TsoAdapter.Sims.VppControlPoints5�_�   	              
          ����                                                                                                                                                                                                                                                                                                                            	           	          V       ]�5�    �               A  * Tests our GraphQL query and mutation construction to Concerto5�_�   
                        ����                                                                                                                                                                                                                                                                                                                            	           	          V       ]�6"     �                  �              �              �                  �              5�_�                            ����                                                                                                                                                                                                                                                                                                                            
           
          V       ]�6#     �              5�_�                       1    ����                                                                                                                                                                                                                                                                                                                                                 V       ]�6&    �          !      C# TODO: extract our graphql mutations and queries to its own module5�_�                    
       ����                                                                                                                                                                                                                                                                                                                                                 V       ]�6P    �   	      !      +  alias Iec60870TsoAdapter.VppControlPoints5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�6Z    �         !      I      VppControlPoints.build_create_need_mutation(vpp_id, control_points)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�6]     �                  end�      !            end�                 3    assert input["control_points"] = control_points�                #    assert input["vpp_id"] = vpp_id�                 �                A      VppComms.build_create_need_mutation(vpp_id, control_points)�                #    {_query, %{"input" => input}} =�                 �                    ]�                      }�                        "power" => power * 2�                B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),�                      %{�                      },�                        "power" => power�                A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),�                      %{�                    control_points = [�                 �                    power = 1.23�                     vpp_id = :rand.uniform(1000)�                |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do�   
              �   	             #  alias Iec60870TsoAdapter.VppComms�      
           �      	          !  use Iec60870TsoAdapter.TestCase�                 �                  """�                7  * Tests our GraphQL mutation construction to Concerto�                  @moduledoc """�                ,defmodule Iec60870TsoAdapter.VppCommsTest do�                 �                 I# TODO: extract our graphql mutations and queries tests to its own module5�_�                            ����                                                                                                                                                                                                                                                                                                                                                 V       ]�6�     �                   I# TODO: extract our graphql mutations and queries tests to its own module       ,defmodule Iec60870TsoAdapter.VppCommsTest do     @moduledoc """   7  * Tests our GraphQL mutation construction to Concerto     """       !  use Iec60870TsoAdapter.TestCase       #  alias Iec60870TsoAdapter.VppComms       |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do        vpp_id = :rand.uniform(1000)       power = 1.23           control_points = [         %{   A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),           "power" => power         },         %{   B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),           "power" => power * 2         }       ]       _    {_query, %{"input" => input}} = VppComms.build_create_need_mutation(vpp_id, control_points)       #    assert input["vpp_id"] = vpp_id   3    assert input["control_points"] = control_points     end   end5�_�                            ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8    �                3    assert input["control_points"] = control_points5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8     �                #    assert input["vpp_id"] = vpp_id5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8     �                "    assert input["vppid"] = vpp_id5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8     �                5    # assert input["control_points"] = control_points5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8     �                4    # assert input["controlPoings"] = control_points5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8    �                4    # assert input["controlPoints"] = control_points5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�89     �         !          �              5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8@     �         !          IO.inspect5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8@     �         !          IO.inspect()5�_�                           ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8A     �         !          IO.inspect()5�_�                       2    ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8D     �         !      3                                    |> IO.inspect()5�_�                       9    ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8E     �         !      :                                    |> IO.inspect(label: )5�_�      $                 @    ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8F    �         !      B                                    |> IO.inspect(label: "input?")5�_�      %   "       $           ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�    �                 2    assert input["controlPoints"] = control_points�                "    assert input["vppId"] = vpp_id5�_�   $   &           %           ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�     �   !            �       "          end�      !            end�                 4    # assert input["controlPoints"] = control_points�                $    # assert input["vppId"] = vpp_id�                 �                B                                    |> IO.inspect(label: "input?")�                _    {_query, %{"input" => input}} = VppComms.build_create_need_mutation(vpp_id, control_points)�                 �                    ]�                      }�                        "power" => power * 2�                B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),�                      %{�                      },�                        "power" => power�                A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),�                      %{�                    control_points = [�                 �                    power = 1.23�                     vpp_id = :rand.uniform(1000)�                |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do�   
              �   	             #  alias Iec60870TsoAdapter.VppComms�      
           �      	          !  use Iec60870TsoAdapter.TestCase�                 �                  """�                7  * Tests our GraphQL mutation construction to Concerto�                  @moduledoc """�                ,defmodule Iec60870TsoAdapter.VppCommsTest do�                 �                 I# TODO: extract our graphql mutations and queries tests to its own module5�_�   %   '           &           ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�     �               "   I# TODO: extract our graphql mutations and queries tests to its own module       ,defmodule Iec60870TsoAdapter.VppCommsTest do     @moduledoc """   7  * Tests our GraphQL mutation construction to Concerto     """       !  use Iec60870TsoAdapter.TestCase       #  alias Iec60870TsoAdapter.VppComms       |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do        vpp_id = :rand.uniform(1000)       power = 1.23           control_points = [         %{   A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),           "power" => power         },         %{   B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),           "power" => power * 2         }       ]       #    {_query, %{"input" => input}} =   A      VppComms.build_create_need_mutation(vpp_id, control_points)   $      |> IO.inspect(label: "input?")       $    # assert input["vppId"] = vpp_id   4    # assert input["controlPoints"] = control_points     end   end5�_�   &   (           '           ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�    �                 $    # assert input["vppId"] = vpp_id5�_�   '   )           (          ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�     �          "      "    assert input["vppId"] = vpp_id5�_�   (   *           )       %    ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�    �      !   "      4    # assert input["controlPoints"] = control_points5�_�   )   +           *       %    ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�    �      !          5    # assert input["controlPoints"] == control_points5�_�   *   ,           +          ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�8�    �                $      |> IO.inspect(label: "input?")5�_�   +   -           ,          ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�9	     �                  end�      !            end�                 3    assert input["controlPoints"] == control_points�                #    assert input["vppId"] == vpp_id�                 �                A      VppComms.build_create_need_mutation(vpp_id, control_points)�                #    {_query, %{"input" => input}} =�                 �                    ]�                      }�                        "power" => power * 2�                B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),�                      %{�                      },�                        "power" => power�                A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),�                      %{�                    control_points = [�                 �                    power = 1.23�                     vpp_id = :rand.uniform(1000)�                |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do�   
              �   	             #  alias Iec60870TsoAdapter.VppComms�      
           �      	          !  use Iec60870TsoAdapter.TestCase�                 �                  """�                7  * Tests our GraphQL mutation construction to Concerto�                  @moduledoc """�                ,defmodule Iec60870TsoAdapter.VppCommsTest do�                 �                 I# TODO: extract our graphql mutations and queries tests to its own module5�_�   ,   .           -          ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�9     �                   I# TODO: extract our graphql mutations and queries tests to its own module       ,defmodule Iec60870TsoAdapter.VppCommsTest do     @moduledoc """   7  * Tests our GraphQL mutation construction to Concerto     """       !  use Iec60870TsoAdapter.TestCase       #  alias Iec60870TsoAdapter.VppComms       |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do        vpp_id = :rand.uniform(1000)       power = 1.23           control_points = [         %{   A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),           "power" => power         },         %{   B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),           "power" => power * 2         }       ]       _    {_query, %{"input" => input}} = VppComms.build_create_need_mutation(vpp_id, control_points)       #    assert input["vppId"] == vpp_id   3    assert input["controlPoints"] == control_points     end   end5�_�   -               .   	        ����                                                                                                                                                                                                                                                                                                                               !          2       V   @    ]�9    �      	           5�_�      #      $   "      $    ����                                                                                                                                                                                                                                                                                                                                                  V        ]�8s   
 �              5�_�   "               #           ����                                                                                                                                                                                                                                                                                                                                                  V        ]�8�     �                $    # assert input["vppId"] = vpp_id�                4    # assert input["controlPoints"] = control_points5�_�              "         ?    ����                                                                                                                                                                                                                                                                                                                                                 V       ]�8J     �                 I# TODO: extract our graphql mutations and queries tests to its own module�                 �                ,defmodule Iec60870TsoAdapter.VppCommsTest do�                  @moduledoc """�                7  * Tests our GraphQL mutation construction to Concerto�                  """�                 �      	          !  use Iec60870TsoAdapter.TestCase�      
           �   	             #  alias Iec60870TsoAdapter.VppComms�   
              �                |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do�                     vpp_id = :rand.uniform(1000)�                    power = 1.23�                 �                    control_points = [�                      %{�                A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),�                        "power" => power�                      },�                      %{�                B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),�                        "power" => power * 2�                      }�                    ]�                 �                #    {_query, %{"input" => input}} =�                A      VppComms.build_create_need_mutation(vpp_id, control_points)�                $      |> IO.inspect(label: "input?")�                 �                 "    assert input["vppId"] = vpp_id�      !          2    assert input["controlPoints"] = control_points�       "            end�   !   "          end5�_�      !                  ?    ����                                                                                                                                                                                                                                                                                                                               !           2       V   ?    ]�8Q     �       #       "   I# TODO: extract our graphql mutations and queries tests to its own module       ,defmodule Iec60870TsoAdapter.VppCommsTest do     @moduledoc """   7  * Tests our GraphQL mutation construction to Concerto     """       !  use Iec60870TsoAdapter.TestCase       #  alias Iec60870TsoAdapter.VppComms       |  test "build_create_need_mutation generates a GraphQL mutation to create a need in VPP with a VPP id and control_points" do        vpp_id = :rand.uniform(1000)       power = 1.23           control_points = [         %{   A        "datetime" => DateTime.to_iso8601(now_plus(61, :second)),           "power" => power         },         %{   B        "datetime" => DateTime.to_iso8601(now_plus(122, :second)),           "power" => power * 2         }       ]       #    {_query, %{"input" => input}} =   A      VppComms.build_create_need_mutation(vpp_id, control_points)   $      |> IO.inspect(label: "input?")       "    assert input["vppId"] = vpp_id   2    assert input["controlPoints"] = control_points     end   end5�_�                   !           ����                                                                                                                                                                                                                                                                                                                               !           2       V   ?    ]�8T   	 �                 $    # assert input["vppId"] = vpp_id�      !          4    # assert input["controlPoints"] = control_points5��
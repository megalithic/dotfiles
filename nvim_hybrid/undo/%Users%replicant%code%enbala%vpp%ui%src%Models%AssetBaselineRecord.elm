Vim�UnDo� L�D/}��.��P:2]�NJ����N��:����t                                      ]^�)    _�                             ����                                                                                                                                                                                                                                                                                                                                                             ]]�     �                 �               �               �                  �               5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             ]]�     �                  5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]�     �                -module Models.CustomerBaselineRecord exposing5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]�      �                   ( CustomerBaselineRecord5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]�"     �               (import Api.Object.CustomerBaselineRecord5�_�                          ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               #type alias CustomerBaselineRecord =5�_�      	                     ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               Tselection : SS.SelectionSet CustomerBaselineRecord Api.Object.CustomerBaselineRecord5�_�      
           	      ;    ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               Qselection : SS.SelectionSet AssetBaselineRecord Api.Object.CustomerBaselineRecord5�_�   	              
      0    ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               F    Api.Object.CustomerBaselineRecord.selection CustomerBaselineRecord5�_�   
                        ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               C    Api.Object.CustomerBaselineRecord.selection AssetBaselineRecord5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               H        |> SS.with (Api.Object.CustomerBaselineRecord.power |> GD.watts)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               L        |> SS.with (Api.Object.CustomerBaselineRecord.startingAt |> GD.time)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               J        |> SS.with (Api.Object.CustomerBaselineRecord.need Need.selection)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �                 M        |> SS.with (Api.Object.CustomerBaselineRecord.duration |> GD.seconds)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �                G        |> SS.with (Api.Object.AssetBaselineRecord.need Need.selection)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �                    , need : Maybe Need5�_�                    
        ����                                                                                                                                                                                                                                                                                                                                                             ]]��    �   	   
          *import Models.Need as Need exposing (Need)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��    �                   , datetime : Time5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]^��     �                        �               �               �                         �               5�_�                       3    ����                                                                                                                                                                                                                                                                                                                                                             ]^��     �                 J        |> SS.with (Api.Object.AssetBaselineRecord.duration |> GD.seconds)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]^��     �                   �             5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]^��     �                 �      
       �      	       �      	          �      	       5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]^��     �      	         %import Api.Object.AssetBaselineRecord5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]^�     �                        �               �               �                 F        |> SS.with (Api.Object.AssetBaselineRecord.need |> GD.seconds)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]^�     �                 J        |> SS.with (Api.Object.CustomerBaselineRecord.need Need.selection)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]^�     �                   , need : Need5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]^�     �                 �      
       �      	       �      	         import Api.Object.Need5�_�                             ����                                                                                                                                                                                                                                                                                                                                                V       ]^�(    �                  *module Models.AssetBaselineRecord exposing       ( AssetBaselineRecord       , selection       )       import Api.Object   %import Api.Object.AssetBaselineRecord   *import Models.Need as Need exposing (Need)   import GraphQl.Decode as GD   #import Graphqelm.SelectionSet as SS   import Time exposing (Time)   &import Units exposing (Seconds, Watts)            type alias AssetBaselineRecord =       { power : Watts       , startingAt : Time       , duration : Seconds       , need : Maybe Need       }           Nselection : SS.SelectionSet AssetBaselineRecord Api.Object.AssetBaselineRecord   selection =   @    Api.Object.AssetBaselineRecord.selection AssetBaselineRecord   E        |> SS.with (Api.Object.AssetBaselineRecord.power |> GD.watts)   I        |> SS.with (Api.Object.AssetBaselineRecord.startingAt |> GD.time)   J        |> SS.with (Api.Object.AssetBaselineRecord.duration |> GD.seconds)   G        |> SS.with (Api.Object.AssetBaselineRecord.need Need.selection)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]]��     �               type alias Asset =5��
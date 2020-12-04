Vim�UnDo� ����N��j��A\��?�Ξ>%��Rr���_   [   8          rated_power: %{value: {:watts, current_power}}      
                       ]Y    _�                            ����                                                                                                                                                                                                                                                                                                                                                             ]�8    �         f          rated_power <= 05�_�                   4        ����                                                                                                                                                                                                                                                                                                                            4   +       6           V   +    ]�y     �   3   4          1    {:watts, rated_power} = generator.rated_power   ^    max_soc_in_watt_hours = calculate_soc_in_watt_hours(maximum_state_of_charge, rated_energy)    5�_�                    4       ����                                                                                                                                                                                                                                                                                                                            4   +       4           V   +    ]�|     �   3   5   c      O    current_energy > min(operational_upper_energy_limit, max_soc_in_watt_hours)5�_�      	             4       ����                                                                                                                                                                                                                                                                                                                            4   +       4           V   +    ]��    �   3   5   c      N    current_power > min(operational_upper_energy_limit, max_soc_in_watt_hours)5�_�      
           	           ����                                                                                                                                                                                                                                                                                                                                          %       V   %    ]��    �                    1    {:watts, rated_power} = generator.rated_power5�_�   	              
   :   %    ����                                                                                                                                                                                                                                                                                                                                          %       V   %    ]��     �   9   ;   a      I  - Check if the generator's current energy is at or below the maximum of5�_�   
                 :   :    ����                                                                                                                                                                                                                                                                                                                            :   :       ;   6       v   6    ]��     �   9   ;   `      ;  - Check if the generator's current power is at or below .�   9   ;   a      H  - Check if the generator's current power is at or below the maximum of   8    operational lower energy limit and user minimum SoC.5�_�                    :   ?    ����                                                                                                                                                                                                                                                                                                                            :   :       :   p       v   6    ]��     �   9   ;   `      K  - Check if the generator's current power is at or below user power limit.5�_�                    :   L    ����                                                                                                                                                                                                                                                                                                                            :   :       :   p       v   6    ]��     �   9   ;   `      S  - Check if the generator's current power is at or below user minimum power limit.5�_�                    :   ?    ����                                                                                                                                                                                                                                                                                                                            :   :       :   p       v   6    ]��     �   9   ;   `      M  - Check if the generator's current power is at or below user minimum power.5�_�                    ;   ?    ����                                                                                                                                                                                                                                                                                                                            ;   ?       <   6       v   6    ]��     �   :   <   _      @  - Check if the generator's current energy is at or above the .�   :   <   `      I  - Check if the generator's current energy is at or above the minimum of   8    operational upper energy limit and user maximum SoC.5�_�                   <   0    ����                                                                                                                                                                                                                                                                                                                            ;   ?       ;   u       v   6    ]��     �   ;   =   _      Y  - If either case is true, then release control if the asset is currently under control.5�_�                    ?       ����                                                                                                                                                                                                                                                                                                                            ;   ?       ;   u       v   6    ]��     �   >   @   _      P    if energy_below_lower_limits?(asset) or energy_above_upper_limits?(asset) do5�_�                    ?   +    ����                                                                                                                                                                                                                                                                                                                            ;   ?       ;   u       v   6    ]��    �   >   @   _      O    if power_below_user_minimum?(asset) or energy_above_upper_limits?(asset) do5�_�                    [        ����                                                                                                                                                                                                                                                                                                                            [           ^          V       ]�    �   Z   [              D  defp calculate_soc_in_watt_hours(state_of_charge, rated_energy) do   (    state_of_charge / 100 * rated_energy     end5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             ]N    �         [      7        rated_power: %{value: {:watts, current_power}},5�_�                       
    ����                                                                                                                                                                                                                                                                                                                                                             ]U     �         [      8          rated_power: %{value: {:watts, current_power}}5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             ]X    �         [      ;          currenty_power: %{value: {:watts, current_power}}5�_�                    <   1    ����                                                                                                                                                                                                                                                                                                                            ;   ?       ;   u       v   6    ]��     �   ;   =   _      Y  - If either case is true, then release control of the asset is currently under control.5�_�                    4       ����                                                                                                                                                                                                                                                                                                                            4   +       4           V   +    ]�~     �   3   5   c          current_power > user_min5�_�                   5       ����                                                                                                                                                                                                                                                                                                                                                             ]�M     �   4   6        5�_�                    4   $    ����                                                                                                                                                                                                                                                                                                                                                             ]�^     �   3   5          3    # {:watts, rated_power} = generator.rated_power5�_�                     3        ����                                                                                                                                                                                                                                                                                                                            3           3          V       ]�s     �   2   5        5��
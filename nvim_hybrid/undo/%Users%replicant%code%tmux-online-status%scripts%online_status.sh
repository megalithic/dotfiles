Vim�UnDo� ��m5`J���o���,x>���iJ�E�Ř�   <     if $(dnd_status); then   2         R       R   R   R    ]G�    _�       	                      ����                                                                                                                                                                                                                                                                                                                                                  V        ]A�     �                    dnd_on_icon_osx="DND"   dnd_on_icon="DND"   dnd_off_icon_osx=""   dnd_off_icon=""5�_�      
          	   #       ����                                                                                                                                                                                                                                                                                                                            	           	           V        ]B�    �   "   $   6        if is_dnd_installed; then5�_�   	              
   /        ����                                                                                                                                                                                                                                                                                                                            /           0          V       ]C�     �   .   /                $(dnd_status)5�_�   
                 "        ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �   !   #   4      dnd_status() {5�_�                    "       ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �   !   #   4      online_status() {5�_�                            ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      #dnd_on_option_string="@dnd_on_icon"5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      &online_on_option_string="@dnd_on_icon"5�_�                            ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      %dnd_off_option_string="@dnd_off_icon"5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      (online_off_option_string="@dnd_off_icon"5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      dnd_on_icon_default() {5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4          echo "$dnd_on_icon_osx"5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4          echo "$dnd_on_icon"5�_�                            ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      dnd_off_icon_default() {5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4          echo "$dnd_off_icon_osx"5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4          echo "$dnd_off_icon"5�_�                    *       ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �   )   +   4        if $(dnd_status); then5�_�                    *       ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]D     �   )   +   4        if $(online_status); then5�_�                   +        ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]D
     �   *   ,   4      P    printf "$(get_tmux_option "$dnd_on_option_string" "$(dnd_on_icon_default)")"5�_�                            ����                                                                                                                                                                                                                                                                                                                                                 V       ]D     �                )online_on_option_string="@online_on_icon"   +online_off_option_string="@online_off_icon"    5�_�      !                      ����                                                                                                                                                                                                                                                                                                                                                  V        ]D     �                    online_on_icon_default() {     if is_osx; then       echo "$online_on_icon_osx"     else       echo "$online_on_icon"     fi   }       online_off_icon_default() {     if is_osx; then       echo "$online_off_icon_osx"     else       echo "$online_off_icon"     fi   }5�_�      #           !           ����                                                                                                                                                                                                                                                                                                                                                  V        ]D+     �         "          �         !    5�_�   !   $   "       #           ����                                                                                                                                                                                                                                                                                                                                                  V        ]DK     �         #       �         "    5�_�   #   %           $           ����                                                                                                                                                                                                                                                                                                                                                 v        ]DR     �         %       �         $    5�_�   $   &           %      
    ����                                                                                                                                                                                                                                                                                                                                                 v        ]DS     �         %      
dnd_status5�_�   %   '           &          ����                                                                                                                                                                                                                                                                                                                                                 v        ]DS     �                dnd_status()5�_�   &   (           '          ����                                                                                                                                                                                                                                                                                                                                                 v        ]DS     �         %      dnd_status()5�_�   '   )           (          ����                                                                                                                                                                                                                                                                                                                                                 v        ]DT     �         %      dnd_status() 5�_�   (   *           )          ����                                                                                                                                                                                                                                                                                                                                                 v        ]DT     �         &      dnd_status() {�                }�         %    �                dnd_status() {}5�_�   )   +           *          ����                                                                                                                                                                                                                                                                                                                                                 v        ]DU     �         &        }�         '           }�                }5�_�   *   ,           +           ����                                                                                                                                                                                                                                                                                                                                                  V        ]DU     �         '       �         '    5�_�   +   -           ,          ����                                                                                                                                                                                                                                                                                                                                                  V        ]DV     �                  {5�_�   ,   .           -           ����                                                                                                                                                                                                                                                                                                                                                  V        ]DW     �                }5�_�   -   /           .           ����                                                                                                                                                                                                                                                                                                                                                  V        ]DZ     �                  else5�_�   .   0           /          ����                                                                                                                                                                                                                                                                                                                                                  V        ]Dh     �         *      %  if is_osx && is_dnd_installed; then5�_�   /   1           0          ����                                                                                                                                                                                                                                                                                                                                                  V        ]Dk     �                  else5�_�   0   2           1           ����                                                                                                                                                                                                                                                                                                                                                V       ]Dq    �                #    status=$(do-not-disturb status)   -    $([ "$status" == "on" ] && true || false)5�_�   1   3           2          ����                                                                                                                                                                                                                                                                                                                                                V       ]Dw     �                    �      .   (    �         (    �         (          �         '    5�_�   2   8           3   ,       ����                                                                                                                                                                                                                                                                                                                            -          -          V       ]Dy    �   +   ,              sleep 305�_�   3   >   5       8          ����                                                                                                                                                                                                                                                                                                                            ,          ,          V       ]E�     �         :      n      [[ -n $(ifconfig utun$i | rg 'inet ') ]] && tun=$(ifconfig utun$i | rg 'inet ' | awk '{print "["$2"]"}')�         :    5�_�   8   ?   =       >   $       ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]E�     �   #   %   :      |      [[ -n $(ifconfig en$i | rg 'inet ') ]] && lan=$(ifconfig en$i | rg 'inet ' | awk '$2 ~ /^[[:blank:]]*192/ {print $2}')�   $   %   :    5�_�   >   @           ?      V    ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]E�     �         :      ~      [[ -n $(ifconfig utun$i >/dev/null 2>&1 | rg 'inet ') ]] && tun=$(ifconfig utun$i | rg 'inet ' | awk '{print "["$2"]"}')�         :    5�_�   ?   A           @   $   R    ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]E�    �   #   %   :      �      [[ -n $(ifconfig en$i >/dev/null 2>&1 | rg 'inet ') ]] && lan=$(ifconfig en$i | rg 'inet ' | awk '$2 ~ /^[[:blank:]]*192/ {print $2}')�   $   %   :    5�_�   @   B           A          ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]F     �         ;          �         :    5�_�   A   C           B           ����                                                                                                                                                                                                                                                                                                                                           ,       v   ,    ]F)   	 �                  else 5�_�   B   D           C   3       ����                                                                                                                                                                                                                                                                                                                            3          3   P       v       ]F�     �   2   4   <      S    printf "$(get_tmux_option "$online_on_option_string" "$(dnd_on_icon_default)")"5�_�   C   E           D   2       ����                                                                                                                                                                                                                                                                                                                            2          2          v       ]F�     �   1   3   <        if $(online_info); then5�_�   D   F           E   3       ����                                                                                                                                                                                                                                                                                                                            2          2          v       ]F�     �   2   4   <          printf "$()"5�_�   E   G           F   5       ����                                                                                                                                                                                                                                                                                                                            5          5          v       ]F�   
 �   4   6   <      R    printf "$(get_tmux_option "$dnd_off_option_string" "$(dnd_off_icon_default)")"5�_�   F   H           G   5   >    ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]F�     �   4   6   <      @    printf ""$dnd_off_option_string" "$(dnd_off_icon_default)")"5�_�   G   I           H   5       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]F�     �   4   6   <      ?    printf ""$dnd_off_option_string" "$(dnd_off_icon_default)""5�_�   H   J           I   5       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]F�     �   4   6   <          printf 5�_�   I   K           J   5       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]F�    �   4   6   <          printf ""5�_�   J   L           K   1       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]F�     �   0   2   <      print_icon() {5�_�   K   M           L   :   	    ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]F�    �   9   ;   <        print_icon5�_�   L   N           M   3       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]G     �   2   3              printf "$(online_info)"5�_�   M   O           N   3       ����                                                                                                                                                                                                                                                                                                                            4   >       4   >       v   >    ]G     �   3   4              �   4   6   <    �   4   5   <    �   3   5   <          �   3   5   ;    5�_�   N   P           O   5       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]G      �   4   5              printf ""5�_�   O   Q           P   2       ����                                                                                                                                                                                                                                                                                                                            5   >       5   >       v   >    ]G!    �   2   3              �   3   5   <    �   3   4   <    �   2   4   <          �   2   4   ;    5�_�   P   R           Q      
    ����                                                                                                                                                                                                                                                                                                                            6   >       6   >       v   >    ]G�     �         <      dnd_status() {5�_�   Q               R   2       ����                                                                                                                                                                                                                                                                                                                            6   >       6   >       v   >    ]G�    �   1   3   <        if $(dnd_status); then5�_�   8       <   >   =   $       ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]E�     �   $   %   :    �   #   %   :      �      [[ -n $(ifconfig en$i  >/dev/null 2>&1| rg 'inet ') ]] && lan=$(ifconfig en$i | rg 'inet ' | awk '$2 ~ /^[[:blank:]]*192/ {print $2}')5�_�   8       ;   =   <   $       ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]E�     �   $   %   :            �   $   &   ;            �   %   &   ;    �   %   &   ;      |      [[ -n $(ifconfig en$i | rg 'inet ') ]] && lan=$(ifconfig en$i | rg 'inet ' | awk '$2 ~ /^[[:blank:]]*192/ {print $2}')       done�   $   &        5�_�   8       :   <   ;   $       ����                                                                                                                                                                                                                                                                                                                                         ,       v   ,    ]E�     �   #   &        5�_�   8       9   ;   :   $       ����                                                                                                                                                                                                                                                                                                                            .          .          V       ]E�     �   $   %   :            �   $   &   ;            �   %   &   ;    �   %   &   ;      |      [[ -n $(ifconfig en$i | rg 'inet ') ]] && lan=$(ifconfig en$i | rg 'inet ' | awk '$2 ~ /^[[:blank:]]*192/ {print $2}')       done�   $   &        5�_�   8           :   9   $       ����                                                                                                                                                                                                                                                                                                                            *          *          V       ]E�     �   #   &        5�_�   3   6   4   8   5   )       ����                                                                                                                                                                                                                                                                                                                            .          .          V       ]D�     �   )   *   :          �   )   +   ;           5�_�   5   7           6   +        ����                                                                                                                                                                                                                                                                                                                            3           4          V       ]D�     �   +   ,   <          �   +   -   =          �   ,   -   =    �   ,   -   =      7    [[ -n $wan ]] && wan="$(tput setaf 2)(wan) 礪$wan"   :    [[ -n $tun ]] && tun="$(tput setaf 4)(tun) \uf982$tun"   8    [[ -n $lan ]] && lan="$(tput setaf 3)(lan)  $lan"       "    [[ -n $wan ]] && echo "$wan\r"   "    [[ -n $tun ]] && echo "$tun\r"   "    [[ -n $lan ]] && echo "$lan\r"�   +   -        5�_�   6               7   3        ����                                                                                                                                                                                                                                                                                                                            3           3          V       ]D�     �   2   5        5�_�   3           5   4           ����                                                                                                                                                                                                                                                                                                                            -          -          V       ]D�     �         :       5�_�   !           #   "          ����                                                                                                                                                                                                                                                                                                                                                  V        ]DH     �         "          �         #          if5�_�             !               ����                                                                                                                                                                                                                                                                                                                                                  V        ]D"     �         !       �         "           5�_�                             ����                                                                                                                                                                                                                                                                                                                                                  V        ]D     �              5�_�                   +        ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]D     �   *   ,   4      @    printf "$(get_tmux_option "$info" "$(dnd_on_icon_default)")"5�_�                     +   )    ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]D     �   *   ,   4      1    printf "$(get_tmux_option "$info" "$(info)")"5�_�                           ����                                                                                                                                                                                                                                                                                                                            /           /          V       ]C�     �         4      is_online_installed() {5�_�             	      *       ����                                                                                                                                                                                                                                                                                                                            	           	           V        ]B�     �   )   +   6        if $(dnd_status) &&; then5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]A�     �      !        5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]A�     �              5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]B     �              5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        ]B     �               print_info() {5�_�                       	    ����                                                                                                                                                                                                                                                                                                                                                  V        ]B	     �                 print_iinfo5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        ]B
     �                 print_info5��
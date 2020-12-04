Vim�UnDo� )A��*i�b
���k�z���/���8z6�   %   :  if (appConfig ~= nil or appConfig.quitGuard == nil) then      .      ;       ;   ;   ;    ]�a�    _�                            ����                                                                                                                                                                                                                                                                                                                                                v       ]y�5    �         !      O    log.df("[app-quit-guard] - attempting to quit for %s, and quitGuard is %s",5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       ]y�?     �                 �         !    �         !    �         !      local log = require('log')5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]y�A     �         !      .local log = hs.logger.new('[layout]', 'debug')5�_�                           ����                                                                                                                                                                                                                                                                                                                                                V       ]y�F     �         !      E    log.df("[quit] - attempting to quit for %s, and quitGuard is %s",5�_�                           ����                                                                                                                                                                                                                                                                                                                                                v       ]y�K    �         !      x    log.df("[app-quit-guard] - unable to determine how to handle this app, %s; it likely isn't configured.", app:name())5�_�                             ����                                                                                                                                                                                                                                                                                                                                                v       ]y�N    �                  5�_�                            ����                                                                                                                                                                                                                                                                                                                                                v       ]y�d     �         !        �              5�_�      	                     ����                                                                                                                                                                                                                                                                                                                                         $       v   $    ]y�k     �         !      2  if (config.applications[app:name()] ~= nil) then5�_�      
           	          ����                                                                                                                                                                                                                                                                                                                                         $       v   $    ]y�l     �         !        local appConfig = �         !    5�_�   	              
          ����                                                                                                                                                                                                                                                                                                                                         $       v   $    ]y�n     �         !        if ( ~= nil) then5�_�   
                        ����                                                                                                                                                                                                                                                                                                                                         $       v   $    ]y�s     �         !      0      config.applications[app:name()].quitGuard)5�_�                           ����                                                                                                                                                                                                                                                                                                                                         $       v   $    ]y�v     �         !      5    if config.applications[app:name()].quitGuard then5�_�                           ����                                                                                                                                                                                                                                                                                                                                         $       v   $    ]y�|     �         !    5�_�                           ����                                                                                                                                                                                                                                                                                                                                       $       v   $    ]y܀     �         "      <    log.df("attempting to quit for %s, and quitGuard is %s",         app:name(),5�_�                           ����                                                                                                                                                                                                                                                                                                                                       $       v   $    ]y܀    �         !      H    log.df("attempting to quit for %s, and quitGuard is %s", app:name(),         appConfig.quitGuard)5�_�                       .    ����                                                                                                                                                                                                                                                                                                                                       $       v   $    ]yܣ     �                e    log.df("unable to determine how to handle this app, %s; it likely isn't configured.", app:name())5�_�                           ����                                                                                                                                                                                                                                                                                                                                       $       v   $    ]yܬ    �                ]    log.df("attempting to quit for %s, and quitGuard is %s", app:name(), appConfig.quitGuard)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                           ]zC�    �                3  local appConfig = config.applications[app:name()]5�_�                       $    ����                                                                                                                                                                                                                                                                                                                                                           ]zD\     �                +  local appConfig = config.apps[app:name()]5�_�                       ,    ����                                                                                                                                                                                                                                                                                                                                                           ]zD_     �                0  local appConfig = config.apps[app:bundleIDj()]5�_�                       2    ����                                                                                                                                                                                                                                                                                                                                                           ]zDl     �         !        �              5�_�                           ����                                                                                                                                                                                                                                                                                                                                                           ]zDw     �         !    5�_�                            ����                                                                                                                                                                                                                                                                                                                                                           ]zDx     �         #        �         "    5�_�                       "    ����                                                                                                                                                                                                                                                                                                                                                           ]zD}     �         #      "  local appBundleID = app:bundleID5�_�                       #    ����                                                                                                                                                                                                                                                                                                                                                           ]zD}     �                $  local appBundleID = app:bundleID()5�_�                       #    ����                                                                                                                                                                                                                                                                                                                                                           ]zD}     �         #      $  local appBundleID = app:bundleID()5�_�                            ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      /  local appConfig = config.apps[app:bundleID()]5�_�                       =    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ]    log.df("attempting to quit app %s, and quitGuard is %s", app:name(), appConfig.quitGuard)5�_�                       Y    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�    �         #      d    log.df("unable to determine how to handle the app, %s; it likely isn't configured.", app:name())5�_�                       %    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ^    log.df("attempting to quit app %s, and quitGuard is %s", appBundleID, appConfig.quitGuard)5�_�                        &    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ]    log.df("attempting to quit app %s and quitGuard is %s", appBundleID, appConfig.quitGuard)5�_�      !                  5    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ^    log.df("attempting to quit app %s with quitGuard is %s", appBundleID, appConfig.quitGuard)5�_�       "           !      5    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ]    log.df("attempting to quit app %s with quitGuard s %s", appBundleID, appConfig.quitGuard)5�_�   !   #           "      5    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      \    log.df("attempting to quit app %s with quitGuard  %s", appBundleID, appConfig.quitGuard)5�_�   "   $           #      5    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      [    log.df("attempting to quit app %s with quitGuard %s", appBundleID, appConfig.quitGuard)5�_�   #   %           $      6    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ]    log.df("attempting to quit app %s with quitGuard ()%s", appBundleID, appConfig.quitGuard)5�_�   $   &           %      6    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ]    log.df("attempting to quit app %s with quitGuard ()%s", appBundleID, appConfig.quitGuard)5�_�   %   '           &      8    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      \    log.df("attempting to quit app %s with quitGuard (%s", appBundleID, appConfig.quitGuard)5�_�   &   (           '      "    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ]    log.df("attempting to quit app %s with quitGuard (%s)", appBundleID, appConfig.quitGuard)5�_�   '   )           (      &    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      ^    log.df("attempting to quit app, %s with quitGuard (%s)", appBundleID, appConfig.quitGuard)5�_�   (   *           )      ;    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      _    log.df("attempting to quit app, %s, with quitGuard (%s)", appBundleID, appConfig.quitGuard)5�_�   )   +           *      V    ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      e    log.df("unable to determine how to handle the app, %s; it likely isn't configured.", appBundleID)5�_�   *   ,           +          ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         #      a    log.df("attempting to quit app, %s, with quitGuard (%s)..", appBundleID, appConfig.quitGuard)5�_�   +   -           ,           ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zD�     �         $       �         #    5�_�   ,   .           -          ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zE      �         $      local quitAlertText = 5�_�   -   /           .          ����                                                                                                                                                                                                                                                                                                                                        -       v        ]zE      �         $      local quitAlertText = ""5�_�   .   0           /          ����                                                                                                                                                                                                                                                                                                                                       .       v   .    ]zE     �         $      3      hs.alert.show("Press Cmd+Q again to quit", 1)5�_�   /   1           0          ����                                                                                                                                                                                                                                                                                                                                              v       ]zE     �         $      local quitAlertText = ""�         $    5�_�   0   2           1          ����                                                                                                                                                                                                                                                                                                                                       0       v       ]zE
     �         $            hs.alert.show(, 1)5�_�   1   3           2          ����                                                                                                                                                                                                                                                                                                                                       V       v       ]zE     �         $      f    log.df("unable to determine how to handle the app, %s; it likely isn't configured..", appBundleID)5�_�   2   4           3      M    ����                                                                                                                                                                                                                                                                                                                                       V       v       ]zE-    �         $      \    log.df("unable to quit the app, %s, with quitGuard; likely not configured", appBundleID)5�_�   3   5           4          ����                                                                                                                                                                                                                                                                                                                                       V       v       ]zE;   
 �         $    5�_�   4   6           5           ����                                                                                                                                                                                                                                                                                                                                                           ]zI�     �         &          �         %    5�_�   5   7           6      0    ����                                                                                                                                                                                                                                                                                                                                                           ]zI�    �         &    5�_�   6   8           7          ����                                                                                                                                                                                                                                                                                                                                                           ]zJ     �         '        if (appConfig ~= nil) then5�_�   7   9           8      -    ����                                                                                                                                                                                                                                                                                                                                                           ]zJ     �         '      3  if (appConfig ~= nil or appConfig.quitGuard) then5�_�   8   :           9          ����                                                                                                                                                                                                                                                                                                                                                           ]zJ!    �                1    if appConfig.quitGuard == nil then return end5�_�   9   ;           :           ����                                                                                                                                                                                                                                                                                                                                                           ]zJ"    �                 5�_�   :               ;      .    ����                                                                                                                                                                                                                                                                                                                                                             ]�a�    �         %      :  if (appConfig ~= nil or appConfig.quitGuard == nil) then5��
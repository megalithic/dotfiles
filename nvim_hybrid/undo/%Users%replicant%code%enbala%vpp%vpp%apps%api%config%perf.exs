Vim�UnDo� ��F��$~�p"��
�s�#���e���fɪϹ                                      \X�U    _�                        
    ����                                                                                                                                                                                                                                                                                                                                                             \X��    �                 level: :debug,5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       \X��    �                 �               �               �                 8# We don't run a server during test. If one is required,�                )# you can enable the server option below.   config :api, Api.Endpoint,     http: [port: 4001],   V  secret_key_base: "w/OqVT6yrPSvokQWn9PK16pAYqk3hNGPp6wKcjsT94wg7esQEnCS+o7nb5qYXeWV",     server: false       config :api, Api.Guardian,   P  secret_key: "U3fUPwmxJnhI7uTR1odsI2v++/3bFK6hdhrh4vmOkBvbRB/pImsKqLoV63pyaaF+"       config :api,   !  ecto_repos: [DataPersist.Repo],     security_store: Security.Mock       ,# Print only warnings and errors during test   config :logger, :console,     level: :info,     device: :standard_error5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        \X�T    �                    config :logger, :console,     level: :info,     device: :standard_error5�_�                           ����                                                                                                                                                                                                                                                                                                                                                  V        \X�R     �              5�_�                          ����                                                                                                                                                                                                                                                                                                                                                             \X��     �               5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        \X��     �              5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        \X��     �              5�_�                             ����                                                                                                                                                                                                                                                                                                                                                  V        \X��    �               5��
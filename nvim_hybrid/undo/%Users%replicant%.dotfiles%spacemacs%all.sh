Vim�UnDo� ��4M�U�5��:��X �y��%۬B�	�r��      J# clone asdf-vm (no need for homebrew version of asdf if we're doing this)                        
    \�    _�                             ����                                                                                                                                                                                                                                                                                                                                                             \�     �               5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             \�     �                  5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \�     �         :      echo ":: setting up asdf-vm..."5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \�     �      	   :      if [[ ! -d "$HOME/.asdf" ]]5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \�"    �   
      :      /  echo ":: ~/.asdf not found; cloning it now.."5�_�                            ����                                                                                                                                                                                                                                                                                                                                                V       \�8    �         :      7  git clone https://github.com/asdf-vm/asdf.git ~/.asdf�         :    5�_�                       ;    ����                                                                                                                                                                                                                                                                                                                                                V       \�:     �               :   #!/usr/bin/env zsh       echo ""   !echo ":: setting up spacemacs..."   echo ""       J# clone asdf-vm (no need for homebrew version of asdf if we're doing this)   if [[ ! -d "$HOME/.emacs.d" ]]   then   	  echo ""   2  echo ":: ~/.emacs.d not found; cloning it now.."   	  echo ""   <  git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d   fi       source ~/.zshrc   source $HOME/.asdf/asdf.sh       #   # preferred plugins..   A#asdf plugin-add golang https://github.com/kennyp/asdf-golang.git   =asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git   Aasdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git   Aasdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git   7asdf plugin-add elm https://github.com/vic/asdf-elm.git   =asdf plugin-add lua https://github.com/Stratus3D/asdf-lua.git   asdf plugin-add nodejs   ?bash $HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring       #   # TODO:   Q# add python asdf installer.. his notes about multiple python versions and reshim   (# https://github.com/danhper/asdf-python   F# asdf plugin-add python https://github.com/tuvistavie/asdf-python.git       #   V# must initially symlink our tool-versions file for asdf to install the right things..   source ~/.zshrc   =ln -sfv $DOTS/asdf/tool-versions.symlink $HOME/.tool-versions   asdf install   source ~/.zshrc       #   # ruby-specific...   sh $DOTS/asdf/ruby.sh       #   # node-specific...   {# TODO: it seems as though after installing a node vresion we have to explicitly set it with `asdf global nodejs <version>`   sh $DOTS/asdf/node.sh       #   # elixir-specific...   sh $DOTS/asdf/elixir.sh       #   # lua-specific...   sh $DOTS/asdf/lua.sh5�_�      	                      ����                                                                                                                                                                                                                                                                                                                                      :          V       \�=     �             +   source ~/.zshrc   source $HOME/.asdf/asdf.sh       #   # preferred plugins..   A#asdf plugin-add golang https://github.com/kennyp/asdf-golang.git   =asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git   Aasdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git   Aasdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git   7asdf plugin-add elm https://github.com/vic/asdf-elm.git   =asdf plugin-add lua https://github.com/Stratus3D/asdf-lua.git   asdf plugin-add nodejs   ?bash $HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring       #   # TODO:   Q# add python asdf installer.. his notes about multiple python versions and reshim   (# https://github.com/danhper/asdf-python   F# asdf plugin-add python https://github.com/tuvistavie/asdf-python.git       #   V# must initially symlink our tool-versions file for asdf to install the right things..   source ~/.zshrc   =ln -sfv $DOTS/asdf/tool-versions.symlink $HOME/.tool-versions   asdf install   source ~/.zshrc       #   # ruby-specific...   sh $DOTS/asdf/ruby.sh       #   # node-specific...   {# TODO: it seems as though after installing a node vresion we have to explicitly set it with `asdf global nodejs <version>`   sh $DOTS/asdf/node.sh       #   # elixir-specific...   sh $DOTS/asdf/elixir.sh       #   # lua-specific...   sh $DOTS/asdf/lua.sh5�_�      
           	           ����                                                                                                                                                                                                                                                                                                                                                V       \�@    �                 5�_�   	              
          ����                                                                                                                                                                                                                                                                                                                                                V       \�M    �               J# clone asdf-vm (no need for homebrew version of asdf if we're doing this)5�_�   
                         ����                                                                                                                                                                                                                                                                                                                                                             \�    �                 �                	# echo ""�                ## echo ":: setting up spacemacs..."�                	# echo ""�                 �                !# # clone spacemacs to ~/.emacs.d�      	           # if [[ ! -d "$HOME/.emacs.d" ]]�      
          # then�   	             #   echo ""�   
             4#   echo ":: ~/.emacs.d not found; cloning it now.."�                #   echo ""�                >#   git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d�                # fi5�_�   
                         ����                                                                                                                                                                                                                                                                                                                                                  V        \�     �                 ##!/usr/bin/env zsh�                 �                #echo ""�                "#echo ":: setting up spacemacs..."�                #echo ""�                 �                 ## clone spacemacs to ~/.emacs.d�      	          #if [[ ! -d "$HOME/.emacs.d" ]]�      
          #then�   	             
#  echo ""�   
             3#  echo ":: ~/.emacs.d not found; cloning it now.."�                
#  echo ""�                =#  git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d�                #fi5��
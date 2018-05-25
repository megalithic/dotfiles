# Git
alias git="nocorrect git"
alias gglg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias gst="git status -sb"
alias gcb="git rev-parse --abbrev-ref HEAD"
alias ggpush="git push origin \`gcb\`"
alias gd="git difftool"

function gneb {
  git checkout --orphan $1
  git reset --hard
}

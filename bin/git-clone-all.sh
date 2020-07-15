# WIP
# curl -s "https://$GITHUB_API_TOKEN:@api.github.com/orgs/enbala/repos?per_page=200" | jq -r '.[].ssh_url' | while read ssh_url; do git clone "${ssh_url}"; done
# find . -maxdepth 2 -iname .tool-versions -type f -print -exec cat {} \; > stack_versions.log

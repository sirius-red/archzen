function list-git-dir --argument repo --argument path
  curl -s https://api.github.com/repos/$repo/contents/$path | jq '.[] | .name'
end

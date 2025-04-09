function nvim-testconfig --argument repo
	set -x NVIM_APPNAME $(string split -f2 '/' $repo)

	git clone --depth 1 "https://github.com/$repo" "$HOME/.config/$NVIM_APPNAME"
	NVIM_APPNAME=$NVIM_APPNAME nvim
end

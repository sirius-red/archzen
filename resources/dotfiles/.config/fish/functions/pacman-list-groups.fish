function pacman-list-groups -a regex_pattern
	if test -n "$regex_pattern"
		pacman -Sgg | cut -d' ' -f1 | sort -u | grep -E "$regex_pattern"
	else
		pacman -Sgg | cut -d' ' -f1 | sort -u
	end
end

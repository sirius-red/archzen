# Format man pages
set -x MANROFFOPT -c
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"


# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low


# Set settings for https://github.com/oh-my-fish/plugin-bang-bang
if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __bang-bang_history_previous_command
    bind -Minsert '$' __bang-bang_history_previous_command_arguments
else
    bind ! __bang-bang_history_previous_command
    bind '$' __bang-bang_history_previous_command_arguments
end

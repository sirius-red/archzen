function __bang-bang_history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __bang-bang_history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

function __bang-bang_key_bindings --on-variable fish_key_bindings
    bind --erase !
    bind --erase '$'
    switch "$fish_key_bindings"
    case 'fish_default_key_bindings'
        bind --mode default ! __bang-bang_history_previous_command
        bind --mode default '$' __bang-bang_history_previous_command_arguments
    case 'fish_vi_key_bindings' 'fish_hybrid_key_bindings'
        bind --mode insert ! __bang-bang_history_previous_command
        bind --mode insert '$' __bang-bang_history_previous_command_arguments
    end
end

function __bang-bang_uninstall --on-event plugin-bang-bang_uninstall
    bind --erase !
    bind --erase '$'
    functions --erase __bang-bang_uninstall
end

__bang-bang_key_bindings

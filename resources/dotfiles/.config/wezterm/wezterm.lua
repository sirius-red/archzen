local util = require('util')

MSYS2_PATH = 'C:/msys64/msys2_shell.cmd'
MSYS2_CWD = 'C:/msys64/home/sirius'
PWSH_PATH = 'C:/Program Files/PowerShell/7/pwsh.exe'

local config = util.inject_modules(
    {},
    'config.bindings',
    'config.color-scheme',
    'config.cursor',
    'config.font',
    'config.mouse',
    'config.scrolling',
    'config.terminal',
    'config.video',
    'config.window'
)

return config

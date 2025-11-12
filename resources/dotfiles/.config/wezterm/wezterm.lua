local util = require('util')

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

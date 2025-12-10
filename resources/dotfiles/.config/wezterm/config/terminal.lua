local util = require('util')

local M = {
	default_prog = nil,
	default_cwd = nil
}

if not util.is_windows() then return M end

local msys2 = {
	MSYS2_PATH,
	'-defterm',
	'-no-start',
	'-ucrt64',
	'-shell',
	'fish'
}

local pwsh = {
	PWSH_PATH,
	'-NoLogo'
}

if util.file_exists(MSYS2_PATH) then
	M.default_prog = msys2
	M.default_cwd = MSYS2_CWD
elseif util.file_exists(PWSH_PATH) then
	M.default_prog = pwsh
end

return M

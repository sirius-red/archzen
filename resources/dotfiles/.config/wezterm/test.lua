local util = require('util')

local function test_util_merge_tables()
	local target = {}
	local src1 = { a = 1, b = 2 }
	local src2 = { b = 3, c = 4 }
	local expected = { a = 1, b = 3, c = 4 }

	util.merge_tables(target, src1, src2)

	-- check that target is as expected
	for k, v in pairs(expected) do
		if target[k] == v then
			print(string.format("util.merge_tables: target[%s] = %s", k, target[k]))
		else
			error(string.format("util.merge_tables: target[%s] = %s, expected %s", k, target[k], v))
		end
	end
end

local function test_util_inject_modules()
	local target = {}
	local expected = { 'color_scheme', 'scrollback_lines' }

	util.inject_modules(target, 'config.color-scheme', 'config.scrolling')

	for _, k in ipairs(expected) do
		if target[k] ~= nil then
			print(string.format("util.inject_modules: target[%s] = %s", k, target[k]))
		else
			error(string.format("util.inject_modules: target[%s] is nil", k))
		end
	end
end

test_util_merge_tables()
test_util_inject_modules()

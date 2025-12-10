local M = {}

--- @private
--- @param t any
function M.ensure_table(t)
	if type(t) ~= "table" then return {} end
	return t
end

---
--- Merges multiple source tables into a target table recursively.
--- This function handles cyclic references and ensures that nested tables are merged correctly.
---
--- Throws an error if `target` is not a table.
---
--- @param target table: The table into which the source tables will be merged. Must be a table.
--- @param ... table: One or more source tables to merge into the target table.
--- @return table: The modified target table after merging all source tables.
function M.merge_tables(target, ...)
	if type(target) ~= "table" then
		error("util.merge_tables: target must be a table", 2)
	end

	-- map source_table -> corresponding_target_table to handle cycles
	local seen = {}

	local function merge(tgt, src)
		-- If exact same table, nothing to do
		if tgt == src then return tgt end
		-- If we've already mapped this source table, reuse mapped target to avoid cycles
		if seen[src] then return seen[src] end
		-- remember mapping
		seen[src] = tgt

		for k, v in pairs(src) do
			local existing = tgt[k]
			if type(v) == "table" and type(existing) == "table" then
				-- both are tables -> merge recursively
				merge(existing, v)
			else
				-- otherwise overwrite (this also covers the case existing is table and v is not)
				tgt[k] = v
			end
		end

		return tgt
	end

	-- iterate all sources
	for i = 1, select('#', ...) do
		local src = select(i, ...)
		if type(src) == "table" then
			merge(target, src)
		end
	end

	return target
end

--- @param target table
--- @param ... string
--- @return table
function M.inject_modules(target, ...)
	target = M.ensure_table(target)
	--- @type table<string, any>
	local mod = {}

	for i = 1, select('#', ...) do
		local mod_name = select(i, ...)
		mod = require(mod_name)
		M.merge_tables(target, mod)
	end

	return target
end

--- @return boolean
function M.is_windows()
	return package.config:sub(1, 1) == '\\'
end

--- @param path string
--- @return boolean
function M.file_exists(path)
	return path ~= nil and io.open(path, 'r') ~= nil
end

return M

local ModuleComponents = {}

local function formatTypes(values)
	local out = {}
	for i, v in ipairs(values) do
		out[i] = typeof(v)
	end
	return table.concat(out, ", ")
end

function ModuleComponents:params(expected, args, skipCount)
	if typeof(expected) == "string" then
		expected = { expected }
	end
	assert(typeof(expected) == "table", "expected must be a table/string")
	assert(typeof(args) == "table", "args must be a table")

	skipCount = skipCount or 0
	for i, typeName in ipairs(expected) do
		if typeName ~= "skip" and i > skipCount then
			local got = typeof(args[i])
			if got ~= typeName then
				error(string.format("bad argument #%d, expected %s got %s (%s)", i, typeName, got, formatTypes(args)), 2)
			end
		end
	end
end

function ModuleComponents:printf(fmt, ...)
	print(string.format(fmt, ...))
end

function ModuleComponents:warnf(fmt, ...)
	warn(string.format(fmt, ...))
end

function ModuleComponents:errorf(fmt, ...)
	error(string.format(fmt, ...), 2)
end

function ModuleComponents:assertf(condition, fmt, ...)
	assert(condition, string.format(fmt, ...))
end

function ModuleComponents:tCount(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

return ModuleComponents

--- Manager for tags
-- @module ldoc.tags

local tags = { }

--- Build a tag
-- @tparam Tag List of tags
-- @tparam LineInfo? lineInfo Line info for the current comment
-- @tparam Messager The messager to use
local function buildTag(tag, lineInfo, messager)
	local name, value, modifiers = tag[1], tag[2], tag[3]

	local factory = tags[name]
	if not factory then
		messager:error("Unknown tag " .. name, lineInfo)
		return false
	end

	return factory(tag, lineInfo, messager)
end

--- Extract args from the value
-- @tparam string The text to extract from
-- @tparam number|{string} Names of fields to extract to, or number of fields to use a flat array
-- @treturn[1] string Remaining text
-- @treturn[1] {number=string}|{string=string} Key, value pair using keys from @{args}
-- @treturn[2] false When nothing can be parsed
-- @treturn[2] string The error message
-- @usage extractArgs("Hello World This works", {"foo", "bar"}) -- { foo = "Hello", bar = "World"}, "This works"
local function extractArgs(value, args)
	local export = {}
	local n = 1

	local max
	if type(args) == "number" then
		max = args
		args = {}
	else
		max = #args
	end
	for i = 1, max do
		-- Try to parse "value" first
		local _, finish, contents = value:find("^%s*\"([^\"]+)\"%s*", n)

		-- Otherwise just parse a word
		if not finish then _, finish, contents = value:find("^%s*(%S+)%s*", n) end

		if not finish then
			return false, "Expected value for '" .. v .. "' at position " .. n
		end

		export[args[i] or i] = contents
		n = finish + 1
	end

	return export, value:sub(n)
end

return {
	tags = tags,
	buildTag = buildTag,
	extractArgs = extractArgs,
}

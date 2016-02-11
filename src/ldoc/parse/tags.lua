--- Convert LDoc comments into a table of properties
-- @module ldoc.parse.tags

local tagStorage = require "ldoc.tags"

local function asLines(str) return str:gmatch('([^\n\r]*)[\n\r]?') end
local function trim(str) return (str:gsub('^%s+', ''):gsub('%s+$', '')) end
local function readUntil(lines, pattern)
	local contents, n = {}, 0
	local line = lines()
	while line and not line:match(pattern) do
		n = n + 1
		contents[n] = line
		line = lines()
	end

	return trim(table.concat(contents, "\n")), line
end

local luadocTag = '^%s*@(%w+)'
local luadocTagValue = luadocTag .. '%s*(.*)'
local luadocTagModAndValue = luadocTag .. '%[([^%]]*)%]%s*(.*)'

--- Parse tags in the form `@foo[key=value,modifier] values`
-- @tparam string text The text to parse
-- @treturn string The preamble before tags
-- @treturn {Tag} List of tags
local function parseAtTags(text)
	-- Ignore empty comments
	if text:match '^%s*$' then return "", {} end

	local lines, follows = asLines(text)
	local preamble, line = readUntil(lines, luadocTag)
	local tags, tagN = {}, 0

	while line do
		local tag, modString, rest = line:match(luadocTagModAndValue)
		if not tag then tag, rest = line:match(luadocTagValue) end

		local modifiers = {}
		if modString then
			for x in modString:gmatch('[^,]+') do
				local k, v = x:match('^([^=]-)=(.*)$')
				if not k then k, v = x, true end
				modifiers[k] = v
			end
		end

		follows, line = readUntil(lines, luadocTag)

		tagN = tagN + 1
		tags[tagN] = {tag, trim(rest .. '\n' .. follows), modifiers }
	end

	return preamble, tags
end

local colonTag = '%s*(%S-):%s'
local colonTagValue = colonTag .. '(.*)'

--- Parse tags in the form `foo: values`
-- @tparam string text The text to parse
-- @treturn string The preamble before tags
-- @treturn {Tag} List of tags
local function parseColonTags(text)
	-- Ignore empty comments
	if text:match '^%s*$' then return "", {} end

	local lines, follows = asLines(text)
	local preamble, line = readUntil(lines, colonTag)
	local tags, tagN = {}, 0

	while line do
		local tag, rest = line:match(colonTagValue)
		follows, line = readUntil(lines, colonTag)
		local value = rest .. '\n' .. follows

		-- Special handling for types in the form ?number
		if tag:match('^[%?!]') then
			tag = tag:gsub('^!', '')
			value = tag .. ' ' .. value
			tag = 'tparam'
		end

		tagN = tagN + 1
		tags[tagN] = { tag, trim(value) }
	end

	return preamble, tags
end

--- Extract information from tags, also handling summary and description
-- @tparam string preamble The initial text
-- @tparam {Tag} tags List of tags
-- @tparam metalua.Node? node The node this doc comment is bound to.
-- @tparam sourcetools.Scope scope The current scope
-- @tparam metalua.LineInfo? lineInfo Line info for the current comment
-- @tparam Messager The messager to use
local function extractTags(preamble, tags, node, definition, scope, lineInfo, messager)
	-- Split after an empty line
	local summary, description = preamble:match('^(.-\n\n)(.+)')
	if not summary then summary = preamble end

	local tagsFormatted = {
		summary = trim(summary),
		description = description and trim(description),
		node = node,
		definition = definition,
		scope = scope,
		lineinfo = lineInfo,
	}

	for _, tag in ipairs(tags) do
		tagStorage.parseTag(tag[1], tag[2], tag[3], tagsFormatted, messager)
	end

	return tagsFormatted
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
		-- Parse "value" first
		local _, finish, contents = value:find("^%s*(%S+)%s*", n)

		if not finish then
			return false, "Expected value for '" .. (args[i] or i) .. "' at position " .. n
		end

		export[args[i] or i] = contents
		n = finish + 1
	end

	return export, value:sub(n)
end

--- Helper function to find a number inside
-- @tparam table modifiers List of modifiers
-- @treturn number? The number to return
local function findNumber(modifiers)
	for num, _ in pairs(modifiers) do
		num = tonumber(num)
		if num then return num end
	end

	return nil
end

return {
	extractTags = extractTags,
	extractArgs = extractArgs,

	parseAtTags = parseAtTags,
	parseColonTags = parseColonTags,

	findNumber = findNumber,
}

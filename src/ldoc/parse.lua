--- Convert LDoc comments into a table of properties
-- @module ldoc.parse

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

		local modifiers
		if modString then
			modifiers = {}
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
-- @tparam LineInfo? lineInfo Line info for the current comment
-- @tparam Messager The messager to use
local function extractTags(preamble, tags, lineInfo, messager)
	-- Split after an empty line
	local summary, description = preamble:match('^(.-\n\n)(.+)')
	if not summary then summary = preamble end

	local tagsFormatted = {
		summary = trim(summary),
		description = description and trim(description),
	}

	for _, tag in ipairs(tags) do
		local formatted, isMulti = tagStorage.buildTag(tag, lineInfo, messager)

		if formatted then
			local name = tag[1]
			local existing = tagsFormatted[name]
			if isMulti then
				if not existing then
					existing = {}
					tagsFormatted[name] = existing
				end

				existing[#existing + 1] = formatted
			elseif existing ~= nil then
				messager:error("Duplicate tag " .. name, lineInfo)
			else
				tagsFormatted[name] = formatted
			end
		end
	end

	return tagsFormatted
end

return {
	extractTags = extractTags,
	parseColonTags = parseColonTags,
	parseAtTags = parseAtTags,
}

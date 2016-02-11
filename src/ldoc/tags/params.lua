local tagParser = require "ldoc.parse.tags"
local tags = require "ldoc.tags"

local function parseParam(value, modifiers, tags, messager)
	local data, description = tagParser.extractArgs(value, { "name" })

	if not data then
		messager:error(description, tags.lineinfo)
		return false
	end

	local name = data.name
	modifiers.name = name

	local params = tags.params
	if not params then
		params = {}
		tags.params = params
	end

	local paramNum = tagParser.findNumber(modifiers) or 1
	local paramList = params[paramNum]
	if not paramList then
		paramList = {}
		params[paramNum] = paramList
	end

	local last = #paramList + 1
	paramList[last] = modifiers
	modifiers.summary = description
	modifiers.params = paramList
end

local function parseReturn(value, modifiers, tags, messager)
	local ret = tags.returns
	if not ret then
		ret = {}
		tags.returns = ret
	end

	local retNum = tagParser.findNumber(modifiers) or 1
	local retList = ret[retNum]
	if not retList then
		retList = {}
		ret[retNum] = retList
	end

	local last = #retList + 1
	retList[last] = modifiers
	modifiers.summary = value
	modifiers.returns = retList
end

local function buildParam(tags, messager)
	if not tags.params then return end

	if tags.class ~= "function" and tags.class ~= "signature" then
		messager:error("Cannot have parameters inside " .. tags.class)
		return false
	end

	local success = true

	if tags.node then
		local node = tags.definition
		if node.tag == "Function" then
			local funcParams = node[1]
			for _, params in ipairs(tags.params) do
				for i, param in ipairs(params) do
					if not funcParams[i] then break end
					if funcParams[i].var.name ~= param.name then
						messager:error("Expected argument " .. funcParams[i].var.name .. ", got " .. param.name, tags.lineinfo)
						success = false
						break
					end
				end

				if #params ~= #funcParams then
					messager:error("Expected " .. #funcParams .. " arguments, got " .. #params, tags.lineinfo)
					success = false
				end

			end
		end
	end

	return success
end

local function inject()
	tags.tagParsers["param"] = parseParam
	tags.addBuilder(buildParam)

	tags.tagParsers["tparam"] = function(value, modifiers, tags, messager)
		local data, description = tagParser.extractArgs(value, { "type" })

		modifiers.type = data.type
		return parseParam(description, modifiers, tags, messager)
	end

	tags.tagParsers["return"] = parseReturn
end

return {
	inject = inject,
}

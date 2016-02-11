--- Manager for tags
-- @module ldoc.tags

local tagParsers = { }

local genericBuilders = { }
local classBuilders = { }

--- Build a tag
-- @tparam string name The name of the tag
-- @tparam string value Remaining text
-- @tparam {string=string|number} modifiers Lookup of modifiers
-- @tparam table tags The information to append to.
-- @tparam sourcetools.Messager The messager to use
-- @treturn boolean If the tag could be parsed
local function parseTag(name, value, modifiers, tags, messager)
	local factory = tagParsers[name]
	if not factory then
		messager:error("Unknown tag " .. name, tags.lineinfo)
		return false
	end

	return factory(value, modifiers, tags, messager)
end

--- Validate a tag
-- @signature Builder
-- @tparam table tags List of tags
-- @tparam sourcetools.Messager The messager to use
-- @treturn boolean If the tag could be built

--- Build tags
-- @inherit Builder
local function buildTag(tags, messager)
	if not tags.class then
		messager:error("No class on tag", tags.lineinfo)
		return false
	end

	for _, builder in ipairs(genericBuilders) do
		if not builder(tags, messager) then
			return false
		end
	end

	local builders = classBuilders[tags.class]
	if builders then
		for _, builder in ipairs(builders) do
			if not builder(tags, messager) then
				return false
			end
		end
	end

	return true
end

--- Add a builder
-- @tparam Builder builder The builder to add
-- @tparam string? className The class name this builder is assigned to
local function addBuilder(builder, className)
	local builders = {}
	if className then
		builders = classBuilders[className]
		if not builders then
			builders = {}
			classBuilders[className] = builders
		end
	else
		builders = genericBuilders
	end

	table.insert(builders, builder)
end

return {
	tagParsers = tagParsers,
	parseTag = parseTag,
	buildTag = buildTag,
	addBuilder = addBuilder,
}

--- Parse LDoc comments
-- @module ldoc.parse

local tags = require("ldoc.tags")

local function parse_file(comments, reporter, options)
	if options.boilerplate then comments(true) end

	local module, moduleDoc = comments()
	if module then
		local tags = options.extractTags(moduleDoc)
		if tags.moduleTags[tags.class] then

		end
	else
		reporter:warn("No initial doc comment")
	end

	for ast, comment in comments do
		if not comment:match('^%s*$') then
			local tags = options.extractTags(comment)
		end
	end

	local function add_module(tags,module_found,old_style)
		tags:add('name',module_found)
		tags:add('class','module')
		local item = F:new_item(tags,lineno())
		item.old_style = old_style
		module_item = item
	end

	
end

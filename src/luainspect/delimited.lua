--- Convert AST to delimited text using LuaInspect info embedded.
-- @module luainspect.delimited

--! require 'luainspect.typecheck' (context)

local LI = require("luainspect.init")

local function escape(s)
	-- s = s:gsub('\n', '\\n') -- escape new lines
	s = s:gsub('"', '""') -- escape double quotes
	if s:match'["\r\n,]' then s = '"'..s..'"' end -- escape with double quotes
	return s
end

local function describe(token, tokenlist, src)
	if token then
		local ast = token.ast
		if token.tag == 'Id' or ast.isfield then
			local line = 'id'
			if ast.id then line = line .. ",id" .. ast.id end
			line = line .. ',' .. escape(table.concat(LI.get_var_attributes(ast),' '))
			line = line .. ',' .. escape(LI.get_value_details(ast, tokenlist, src):gsub('\n', ';'))
			return line
		end
	end
end

return function(ast, src, tokenlist)
	local fmt_tokens = {}
	for _, token in ipairs(tokenlist) do
		local fchar, lchar = token.fpos, token.lpos
		local desc = describe(token, tokenlist, src)
		if desc then
			fmt_tokens[#fmt_tokens + 1] = ("%d,%d,%s\n"):format(fchar, lchar, desc)
		end
	end
	return table.concat(fmt_tokens)
end

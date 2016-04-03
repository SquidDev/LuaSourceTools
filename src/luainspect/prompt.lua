--- Convert AST to delimited text using LuaInspect info embedded.
-- @module luainspect.prompt

--! require 'luainspect.typecheck' (context)

local LI = require("luainspect.init")

local colors ={
	error = "\27[91m",
	warn = "\27[93m",
}

local reset = "\27[0m"

local function describe(token, tokenlist, src, builder)
	if token then
		local ast = token.ast
		if token.tag == 'Id' or ast.isfield then
			local severity, warnings,flags = LI.get_messages(token, tokenlist, src)
			if severity then
				local fli, lli = token.lineinfo.first, token.lineinfo.last
				local line	= fli.line;	if line~=lli.line	then line	=line	..'-'..lli.line	end
				local column = fli.column; if column~=lli.column then column=column..'-'..lli.column end
				local prefix = ("%s:%s:%s "):format(fli.source, line, column)

				for i, warning in ipairs(warnings) do
					builder[#builder + 1] = (colors[flags[i] or ""] or reset) .. prefix .. warning
				end
			end
		end
	end
end

return function(ast, src, tokenlist)
	local fmt_tokens = {}
	for _, token in ipairs(tokenlist) do
		describe(token, tokenlist, src, fmt_tokens)
	end
	return table.concat(fmt_tokens, "\n") .. reset .. "\n"
end

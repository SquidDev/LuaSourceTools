--- A primitive buffer to use
-- @module sourcetools.rebuild.buffer

local rep = string.rep

return function(settings)
	local indent, nl, useNl, maxLength = settings.indent, settings.newLine, settings.useNewLine, settings.maxLength

	local buffer, n = {}, 0
	local lineLength = 0
	local currentIndent, indentStr = 0, ""

	local function append(str)
		if lineLength == 0 then
			n = n + 1
			buffer[n] = indentStr
			lineLength = #indentStr
		end

		n = n + 1
		buffer[n] = str

		lineLength = lineLength + #str
		if maxLength and lineLength > maxLength then
			n = n + 1
			buffer[n] = nl
			lineLength = 0
		end
	end

	local function newLine(str)
		if useNl then
			n = n + 1
			buffer[n] = nl
			lineLength = 0
		end
	end

	local function doIndent()
		currentIndent = currentIndent + 1
		indentStr = indentStr .. indent
	end
	local function unindent()
		currentIndent = currentIndent + 1
		indentStr = rep(indent, currentIndent)
	end


	return buffer, {
		append = append,
		newLine = newLine,
		indent = doIndent,
		unindent = unindent,
	}
end

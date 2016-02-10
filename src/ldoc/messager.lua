--- A basic messager
-- @classmod ldoc.messager

local class = require "ldoc.class"

local function formatLineInfo(lineInfo)
	return lineInfo.source .. ":" .. lineInfo.line
end

local Messager = {}

--- Create a new messager
function Messager:new()
	self.success = true
end

--- Display a warning message
-- @tparam string message The message to display
-- @tparam LineInfo? lineInfo Line info for the current comment
function Messager:warn(message, lineInfo)
	if lineInfo then message = formatLineInfo(lineInfo) .. ": " .. message end
	print("WARN: " .. message)
end

--- Display an warning message
-- @tparam string message The message to display
-- @tparam LineInfo? lineInfo Line info for the current comment
function Messager:error(message, lineInfo)
	if lineInfo then message = formatLineInfo(lineInfo) .. ": " .. message end
	print("ERROR: " .. message)
	self.success = false
end

return class(Messager)

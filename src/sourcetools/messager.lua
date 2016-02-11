--- A basic messager
-- @classmod sourcetools.messager

local class = require "sourcetools.class"

local function formatLineInfo(lineInfo)
	return lineInfo.source .. ":" .. lineInfo.line
end

local coloursier
do
	local isWindows = type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1,1) == '\\'

	if fs and term and colours then
		local cols = {
			error = colours.red,
			normal = colours.white,
			notice = colours.cyan,
			warn = colours.yellow,
		}
		coloursier = function(type)
			local colour = cols[type]
			if not colour then error("Unknown type " .. type) end

			term.setTextColour(code)
		end
	elseif not isWindows or os.getenv("ANSICON") then
		local ansiColours = {
			warn = 33,
			error = 31,
			notice = 36,
			normal = 0,
		}
		local escapeString = string.char(27) .. '[%dm'

		coloursier = function(type)
			local colour = ansiColours[type]
			if not colour then error("Unknown type " .. type) end

			io.write(escapeString:format(colour))
		end
	else
		coloursier = function() end
	end
end

local Messager = {}

--- Create a new messager
function Messager:new()
	self.success = true
end

function Messager:print(message, type)
	coloursier(type)
	print(message)
	coloursier("normal")
end

--- Display a warning message
-- @tparam string message The message to display
-- @tparam LineInfo? lineInfo Line info for the current comment
function Messager:warn(message, lineInfo)
	if lineInfo then message = formatLineInfo(lineInfo) .. ": " .. message end
	self:print("[WARN] " .. message, "warn")
end

--- Display a information message
-- @tparam string message The message to display
-- @tparam LineInfo? lineInfo Line info for the current comment
function Messager:info(message, lineInfo)
	if lineInfo then message = formatLineInfo(lineInfo) .. ": " .. message end
	self:print("[INFO] " .. message, "notice")
end

--- Display an warning message
-- @tparam string message The message to display
-- @tparam LineInfo? lineInfo Line info for the current comment
function Messager:error(message, lineInfo)
	self.success = false

	if lineInfo then message = formatLineInfo(lineInfo) .. ": " .. message end
	self:print("[ERROR] " .. message, "error")
end

return class(Messager)

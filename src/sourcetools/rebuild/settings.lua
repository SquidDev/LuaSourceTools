--- Settings for the minifier
-- @module sourcetools.rebuild.settings

--- Data about how the source code should be formatted
-- @struct Settings
-- @tfield string indent The indent to use
-- @tfield string newLine The newline character to use
-- @tfield boolean useNewLine Ad new lines after each statement
-- @tfield int? maxLength Maximum length of a line, will be forcefully wrapped.

--- Settings for the minifier
local minify = {
	indent = "",
	newLine = "\n",
	useNewLine = false,
	maxLength = 100,
}

--- Settings for the default code
local default = {
	indent = "\t",
	newLine = "\n",
	useNewLine = true,
	maxLength = nil,
}

return {
	minify = minify,
	default = default,
}

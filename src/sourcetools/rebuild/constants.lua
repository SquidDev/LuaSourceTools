--- Various constants used for rebuilding

local function createLookup(tbl)
	local r = {}
	for _, k in pairs(tbl) do r[k] = true end
	return r
end

local function createPrecedence(tbl)
	local r = {}
	for prec, ops in ipairs(tbl) do
		for _, op in ipairs(ops) do r[op] = prec end
	end
	return r
end

local M = {}

--- Keywords, which are illegal as identifiers.
-- This is shared between instances so should be copied before using
M.keywords = createLookup {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "if", "in",
	"local", "nil", "not", "or", "repeat", "return",
	"then", "true", "until", "while"
}
--- Operator -> precedences lookup table, in increasing order.
M.precedence = createPrecedence {
	{ "or", "and" },
	{ "lt", "le", "eq", "ne" },
	{ "concat" },
	{ "add", "sub" },
	{ "mul", "div", "mod" },
	{ "unm", "not", "len" },
	{ "pow" },
	{ "index" }
}

--- operator -> source representation.
-- This is shared between instances so should be copied before using
M.symbols = {
	add = " + ",
	sub = " - ",
	mul = " * ",
	div = " / ",
	mod = " % ",
	pow = " ^ ",
	concat = " .. ",
	eq = " == ",
	ne = " ~= ",
	lt = " < ",
	le = " <= ",
	["and"] = " and ",
	["or"]  = " or ",
	["not"] = "not ",
	len     = "#",
	unm     = '-',
}

return M

---------------------------------------------------------------------------
-- Copyright (c) 2006-2013 Fabien Fleutot and others.
--
-- All rights reserved.
--
-- This program and the accompanying materials are made available
-- under the terms of the Eclipse Public License v1.0 which
-- accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- This program and the accompanying materials are also made available
-- under the terms of the MIT public license which accompanies this
-- distribution, and is available at http://www.lua.org/license.html
--
-- Contributors:
--     Fabien Fleutot - API and implementation
-- @module metalua.compiler
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Convert between various code representation formats. Atomic
-- converters are written in extenso, others are composed automatically
-- by chaining the atomic ones together in a closure.
--
-- Supported formats are:
--
-- * srcfile:    the name of a file containing sources.
-- * src:        these sources as a single string.
-- * lexstream:  a stream of lexemes.
-- * ast:        an abstract syntax tree.
-- * proto:      a (Yueliang) struture containing a high level
--               representation of bytecode. Largely based on the
--               Proto structure in Lua's VM
-- * bytecode:   a string dump of the function, as taken by
--               loadstring() and produced by string.dump().
-- * function:   an executable lua function in RAM.
--
--------------------------------------------------------------------------------
local expect = require 'metalua.expect'

local M  = { }

--- Order of the transformations. if 'a' is on the left of 'b', then a 'a' can
-- be transformed into a 'b' (but not the other way around).
-- M.sequence goes for numbers to format names, M.order goes from format
-- names to numbers.
M.sequence = {
	'srcfile',  'src', 'lexstream', 'ast'
}

local arg_types = {
	srcfile    = { 'string', '?string' },
	src        = { 'string', '?string' },
	lexstream  = { 'lexer.stream', '?string' },
	ast        = { 'table', '?string' }
}


M.order= { }; for a,b in pairs(M.sequence) do M.order[b]=a end

local CONV = { } -- conversion metatable __index

function CONV:srcfile_to_src(x, name)
	expect(self, 'metalua.compiler', 'self')
	expect(x, 'string', 'x')
	expect(name, '?string', 'name')
	name = name or '@'..x
	local f, msg = io.open (x, 'rb')
	if not f then error(x .. ': ' .. msg) end
	local r, msg = f :read '*a'
	if not r then error("Cannot read file '"..x.."': "..msg) end
	f :close()
	return r, name
end

function CONV :src_to_lexstream(src, name)
	expect(self, 'metalua.compiler', 'self')
	expect(src, 'string', 'src')
	expect(name, '?string', 'name')
	local r = self.parser.lexer :newstream (src, name)
	return r, name
end

function CONV :lexstream_to_ast(lx, name)
	expect(self, 'metalua.compiler', 'self')
	expect(lx, 'lexer.stream', 'lx')
	expect(name, '?string', 'name')
	local r = self.parser.chunk(lx)
	r.source = name
	if M.check_ast then M.check_ast (r) end
	return r, name
end

--- Create all sensible combinations
for i=1,#M.sequence do
	local src = M.sequence[i]
	for j=i+2, #M.sequence do
		local dst = M.sequence[j]
		local dst_name = src.."_to_"..dst
		local my_arg_types = arg_types[src]
		local functions = { }
		for k=i, j-1 do
			local name =  M.sequence[k].."_to_"..M.sequence[k+1]
			local f = assert(CONV[name], name)
			table.insert (functions, f)
		end
		CONV[dst_name] = function(self, a, b)
			expect(self, 'metalua.compiler', 'self')
			expect(a, my_arg_types[1], 'a')
			expect(b, my_arg_types[2], 'b')
			for _, f in ipairs(functions) do
				a, b = f(self, a, b)
			end
			return a, b
		end
	end
end


-- This one goes in the "wrong" direction, cannot be composed.
function CONV:function_to_bytecode(...) return string.dump(...) end

local MT = { __index=CONV, __type='metalua.compiler' }

function M.new()
	local parser = require 'metalua.compiler.parser' .new()
	local self = { parser = parser }
	setmetatable(self, MT)
	return self
end

return M

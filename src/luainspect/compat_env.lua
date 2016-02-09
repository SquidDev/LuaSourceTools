--[[-- Lua 5.1/5.2 environment compatibility functions

	This module provides Lua 5.1/5.2 environment related compatibility functions.
	This includes implementations of Lua 5.2 style `load` for use in Lua 5.1.

	@copyright David Manura. Licensed under the same terms as Lua 5.1/5.2 (MIT license).
	@module luainspect.compat_env
--]]

local M = { }

local function check_chunk_type(s, mode)
	local nmode = mode or 'bt'
	local isBinary = s and #s > 0 and s:byte(1) == 27
	if isBinary and not nmode:match'b' then
		return nil, ("attempt to load a binary chunk (mode is '%s')"):format(mode)
	elseif not isBinary and not nmode:match't' then
		return nil, ("attempt to load a text chunk (mode is '%s')"):format(mode)
	end
	return true
end

local IS_52_LOAD = pcall(load, '')
if IS_52_LOAD then
	M.load  = _G.load
else
	-- 5.2 style `load` implemented in 5.1
	function M.load(ld, source, mode, env)
		local f
		if type(ld) == 'string' then
			local s = ld
			local ok, err = check_chunk_type(s, mode); if not ok then return ok, err end
			local err; f, err = loadstring(s, source); if not f then return f, err end
		elseif type(ld) == 'function' then
			local ld2 = ld
			if (mode or 'bt') ~= 'bt' then
				local first = ld()
				local ok, err = check_chunk_type(first, mode); if not ok then return ok, err end
				ld2 = function()
					if first then
						local chunk=first; first=nil; return chunk
					else return ld() end
				end
			end
			local err; f, err = load(ld2, source); if not f then return f, err end
		else
			error(("bad argument #1 to 'load' (function expected, got %s)"):format(type(ld)), 2)
		end
		if env then setfenv(f, env) end
		return f
	end
end

return M

--- Removes annotations added by @{sourcetools.annotator} and similar tools
-- @module sourcetools.unannotator

local next, type = next, type

return {
	down = function(node)
		local len = #node
		local item = next(node)
		while item do
			local k = item
			item = next(node, item)

			if k ~= "lineinfo" and (type(k) ~= "number" or k < 1 or k > len) then
				node[k] = nil
			end
		end
	end
}

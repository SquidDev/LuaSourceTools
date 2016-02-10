--- Annotate nodes with their scope, usages and parents
-- @module metalua.annotate

local walk = require "metalua.walk"
local pp = require "metalua.pprint"

local setmetatable, ipairs, insert = setmetatable, ipairs, table.insert

--- An offset in a variable expression
-- @struct Offset
-- @tfield "Offset" tag
-- @tfield Expression 1 The expression
-- @tfield int 2 The offset in that expression

--- A variable source
-- @type Source = Expression|Fornum|ForIn|Offset

--- A local variable
-- @struct Variable
-- @tfield Variable? hides The variable this one blocks
-- @tfield {Node} references List of references. This should just be `Id/`Dot nodes
-- @tfield Source? declaration The initial value for this node.
-- @tfield {Source} values List of other values, that aren't its declaration

local function getName(node)
	local name
	if node.tag == "Dots" then
		return "..."
	elseif node.tag == "Id" then
		return node[1]
	else
		error("Expected Id or Dots, got " .. loc.tag .. " for " .. pprint.tostring(loc))
	end
end


local multi = { Dots = true, Call = true, Invoke = true, Stat = true }

local function handleAssignment(vars, values, scope, declaration)
	if not values then return end
	local remainder, remainderIndex

	for index, declr in ipairs(vars) do
		local name = getName(declr)
		local var = scope.vars[name]

		local value = values[index]

		if value then
			if multi[value.tag] then
				remainder = value
				remainderIndex = index
			else
				remainder = nil
			end
		elseif remainder then
			value = { tag = "Offset", remainder, index - remainderIndex }
		end

		if value then
			if declaration then
				var.declaration = value
			else
				insert(var.values, value)
			end
		end
	end
end

local globalMeta = {
	__index = function(self, name)
		local var = {
			global = true,
			references = {},
			values = {},
		}

		self[name] = var
		return var
	end
}

local visitor = {
	scope = function(current)
		local vars = { }

		local scope = {
			parent = current,
			vars = vars,
			children = {},
		}

		if current then
			setmetatable(vars, { __index = current.vars})
			insert(current.children, scope)
		else
			setmetatable(vars, globalMeta)
		end

		return scope
	end,

	down = function(node, parent, scope)
		node.scope = scope
		node.parent = parent
	end,

	upLocal = function(node, parent, scope)
		handleAssignment(node[1], node[2], scope, true)
	end,

	upLocalRec = function(node, parent, scope)
		handleAssignment(node[1], node[2], scope, true)
	end,

	upFornum = function(node, parent, scope)
		scope[getName(node[1])].declaration = node
	end,

	upForin = function(node, parent, scope)
		handleAssignment(node[1], node[2], scope, true)
	end,

	upSet = function(node, parent, scope)
		handleAssignment(node[1], node[2], scope, false)
	end,

	upId = function(node, parent, scope)
		local var = scope.vars[getName(node)]
		node.var = var

		local isUsage = true
		if parent and not parent.tag then
			local pParent = parent.parent
			if pParent and pParent.tag == "Set" and pParent[1] == parent then
				isUsage = false
			end
		end

		if isUsage then
			insert(var.references, node)
		end
	end,

	declare = function(node, parent, scope)
		local name = getName(node)

		local var = {
			hides = scope.vars[name],
			references = {},
			declaration = nil,
			values = {}
		}
		scope.vars[name] = var
		node.var = var
	end,
}

return visitor

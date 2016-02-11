--- Basic traversal library for nodes.
-- @module sourcetools.walk

local pp = require 'metalua.pprint'

local ipairs = ipairs

--- Make a scope
-- @tparam Node node The node this scope belongs to
-- @tparam Scope? scope The scope to create
-- @treturn Scope the child scope
local function makeScope(visitor, node, scope)
	local factory = visitor.scope
	if factory then
		return factory(node, scope)
	else
		return nil
	end
end

--- A visitor for a node.
-- There can be generic fields to allow custom functions (upLocal and downLocal)
-- @struct Visitor<Scope>
-- @tfield ((Node, Node?, Scope)->boolean?)? up The visitor when exiting a node
-- @tfield ((Node, Node?, Scope)->boolean?)? down The visitor when entering a node
-- @tfield ((Node, Node?, Scope)->boolean?)? declare Called when a variable is declared
-- @tfield (Scope->Scope)? scope Used to create a new scope

--- Traverses a node, calling a visitor
-- @type Traverser = (Node, Node?, parent, visitor, Scope)->nil
-- @tparam Node node The node to visit
-- @tparam Node parent The parent node
-- @tparam Visitor visitor The visitor to use
-- @tparam Scope scope The Scope for this node

--- Create a fully featured traverser which calls @{Visitor.down} and @{Visitor.up}.
-- @tparam Traverser The traverser to delegate to
-- @treturn Traverser The wrapper traverser
local function wrapTraverser(traverse)
	return function(node, parent, visitor, scope)
		local down, up = visitor.down, visitor.up

		if not down or down(node, parent, scope) ~= false then
			traverse(node, parent, visitor, scope)
		end

		if up then
			up(node, parent, scope)
		end
	end
end

--- Create a traverser that loops through a list
-- @tparam Traverser traverse The traverser to delegate to
-- @treturn Traverser A traverser that loops through each item
local function listTraverser(traverse)
	return function(node, parent, visitor, scope)
		for _, item in ipairs(node) do
			traverse(item, node, visitor, scope)
		end
	end
end

--- A traverser that looks up using the tag
-- @tparam {string=Traverser} traversers Lookup of traverse to delegate to
-- @treturn Traverser The formed traverser
local function tagTraverser(traversers, category)
	local upCat, downCat = "up" .. category, "down" .. category
	return function(node, parent, visitor, scope)
		local tag = node.tag
		if not tag then error("Node with no tag: " .. pp.tostring(node)) end

		local nodeVisitor = visitor[downCat]
		if nodeVisitor and nodeVisitor(node, parent, scope) == false then
			return
		end

		nodeVisitor = visitor["down" .. tag]
		if nodeVisitor and nodeVisitor(node, parent, scope) == false then
			return
		end

		local traverser = traversers[tag]
		if not traverser then
			error("Unknown node with tag ".. tag .. ": " .. pp.tostring(node))
		end

		traverser(node, parent, visitor, scope)

		nodeVisitor = visitor["up" .. tag]
		if nodeVisitor then nodeVisitor(node, parent, scope) end

		nodeVisitor = visitor[upCat]
		if nodeVisitor then nodeVisitor(node, parent, scope) end
	end
end

local empty = function() end

local expr = {
	Id = empty,
	Nil = empty,
	Dots = empty,
	True = empty,
	False = empty,
	Number = empty,
	String = empty,
}

local stat = {
	Break = empty,
	Goto = empty,
	Label = empty,
}

local table = { }

--- Traverse statements
-- @inherit Traverser
local statT = wrapTraverser(tagTraverser(stat, "Statement"))

--- Traverse a list of statements
-- @inherit Traverser
local statLT = wrapTraverser(listTraverser(statT))

--- Traverse an expression
-- @inherit Traverser
local exprT = wrapTraverser(tagTraverser(expr, "Expression"))

--- Traverse a list of expressions
-- @inherit Traverser
local exprLT = wrapTraverser(listTraverser(exprT))

local tableT = wrapTraverser(tagTraverser(table, "Table"))

--- Traverse a declaration
-- @inherit Traverser
-- @see Visitor.declare
local declT = wrapTraverser(function(node, parent, visitor, scope)
	local func = visitor.declare
	if not func then return end
	func(node, parent, scope)
end)

--- Traverse a list of declarations
-- @inherit Traverser
-- @see Visitor.declare
local declLT = wrapTraverser(function(node, parent, visitor, scope)
	local func = visitor.declare
	if not func then return end

	for _, item in ipairs(node) do
		func(item, node, scope)
	end
end)

-- Statements
function stat.Do(node, parent, visitor, scope)
	statLT(node, node, visitor, makeScope(visitor, node, scope))
end

function stat.Set(node, parent, visitor, scope)
	exprLT(node[1], node, visitor, scope)
	exprLT(node[2], node, visitor, scope)
end

function stat.While(node, parent, visitor, scope)
	exprT(node[1], node, visitor, scope)
	statLT(node[2], node, visitor, makeScope(visitor, node, scope))
end

function stat.Repeat(node, parent, visitor, scope)
	local childScope = makeScope(visitor, node, scope)
	statLT(node[1], node, visitor, childScope)
	exprT(node[2], node, visitor, childScope)
end

function stat.Local(node, parent, visitor, scope)
	local locals = node[2]
	if locals then exprLT(locals, node, visitor, scope) end
	declLT(node[1], node, visitor, scope)
end

function stat.Localrec(node, parent, visitor, scope)
	declLT(node[1], node, visitor, scope)
	exprLT(node[2], node, visitor, scope)
end

function stat.Fornum(node, parent, visitor, scope)
	exprT(node[2], node, visitor, scope)
	exprT(node[3], node, visitor, scope)

	local body
	if #visitor == 4 then
		body = node[4]
	else
		body = node[5]
		exprT(node[4], node, visitor, scope)
	end

	local childScope = makeScope(visitor, node, scope)
	declT(node[1], node, visitor, childScope)
	statLT(body, node, visitor, childScope)
end

function stat.Forin(node, parent, visitor, scope)
	exprLT(node[2], node, visitor, scope)

	local childScope = makeScope(visitor, node, scope)
	declLT(node[1], node, visitor, childScope)
	statLT(node[3], node, visitor, childScope)
end

function stat.If(node, parent, visitor, scope)
	for i = 1, #node - 1, 2 do
		exprLT(node[i], node, visitor, scope)
		statLT(node[i + 1], node, visitor, makeScope(visitor, node, scope))
	end

	if #node % 2 == 1 then
		statLT(node[#node], node, visitor, makeScope(visitor, node, scope))
	end
end

stat.Call = exprLT
expr.Call = exprLT

stat.Invoke = exprLT
expr.Invoke = exprLT

stat.Return = exprLT

-- Expressions
function expr.Paren(node, parent, visitor, scope)
	exprT(node[1], node, visitor, scope)
end

function expr.Index(node, parent, visitor, scope)
	exprT(node[1], node, visitor, scope)
	exprT(node[2], node, visitor, scope)
end

function expr.Op(node, parent, visitor, scope)
	exprT(node[2], node, visitor, scope)
	if #node == 3 then
		exprT(node[3], node, visitor, scope)
	end
end

function expr.Function(node, parent, visitor, scope)
	local childScope = makeScope(visitor, node, scope)
	declLT(node[1], node, visitor, childScope)
	statLT(node[2], node, visitor, childScope)
end

function expr.Stat(node, parent, visitor, scope)
	local childScope = makeScope(visitor, node, scope)
	statLT(node[1], node, visitor, childScope)
	exprLT(node[2], node, visitor, childScope)
end

function expr.Table(node, parent, visitor, scope)
	for _, item in ipairs(node) do
		if item.tag == "Pair" then
			tableT(item, node, visitor, scope)
		else
			exprT(item, node, visitor, scope)
		end
	end
end

function table.Pair(node, parent, visitor, scope)
	exprT(node[1], node, visitor, scope)
	exprT(node[2], node, visitor, scope)
end

--- Add an expression traverser
-- @tparam string name The name of the node
-- @tparam Traverser traverser The traverser to use
local function addExpr(name, traverser)
	if expr[name] then error("Traverser already exists for expression " .. name) end
	expr[name] = traverser
	return traverser
end

--- Add a statement traverser
-- @tparam string name The name of the node
-- @tparam Traverser traverser The traverser to use
local function addStat(name, traverser)
	if stat[name] then error("Traverser already exists for statement " .. name) end
	stat[name] = traverser
	return traverser
end

return {
	statement = statT,
	block = statLT,
	expression = exprT,
	expressionList = exprLT,
	declaration = declT,
	declarationList = declLT,

	addExpression = addExpr,
	addStatement = addStat,
}

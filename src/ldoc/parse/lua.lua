--- Walks an annotated metalua source tree finding LDoc comments
-- @module ldoc.parse.lua

package.path = package.path..';'..'./?/init.lua'

local walk = require "sourcetools.walk"
local pp = require "metalua.pprint"
local tags = require "ldoc.parse.tags"
local tagStorage = require "ldoc.tags"
local messager = require "sourcetools.messager"()

require "ldoc.tags.params".inject()

local function extractDefinition(node, messager)
	if node.tag == "LocalRec" or node.tag == "Local" then
		if #node[1] > 1 then
			messager:warn("Cannot have doc comment on multiple values", node.lineinfo.first)
			return node
		end

		if node[2] and #node[2] == 1 then
			return node[2][1]
		else
			local var = node[1][1].var
			local def = var.definition

			if not def then
				if #var.values ~= 1 then
					messager:warn("This value is not defined once, so no node can be attached", node.lineinfo.first)
					return node
				end

				return var.values[1]
			else
				return def
			end
		end
	end

	return node
end

local function handleComment(comment, node, scope, messager)
	local text = comment[1]:gsub("^-*\n?", "")
	local definition = extractDefinition(node, messager)

	local preamble, parsed = tags.parseAtTags(text)
	local tags = tags.extractTags(preamble, parsed, node, definition, scope, comment.lineinfo.first, messager)

	if node or definition and not tags.class then
		if node.tag == "Function" or definition.tag == "Function" then
			tags.class = "function"
		elseif definition or node.tag == "Local" then
			tags.class = "var"
		end
	end

	tagStorage.buildTag(tags, messager)

	print(pp.tostring(tags, { blacklist = { node = true, scope = true, lineinfo = true, definition = true } }))
end

local walker = {
	downStatement = function(node, parent, scope)
		local info = node.lineinfo
		if not info then return end

		local comments = info.first.comments
		if not comments then return end

		local line = info.first.line
		for _, comment in ipairs(comments) do
			if comment[1]:sub(1, 1) == '-' then
				local thisNode
				local currentLine = comment.lineinfo.last.line
				if currentLine == line or currentLine == line - 1 then
					thisNode = node
				end

				handleComment(comment, thisNode, node.scope, messager)
			end
		end
	end
}

do
	local mlc = require "metalua.compiler".new()
	local annotator = require'sourcetools.annotator'

	local tree =  mlc:src_to_ast(
[[
--- Foobar baz
-- @param foo This is simple
-- @param another Testing
-- @tparam[2] string anotherSig
local x = function(x, y) end
]], "foobar.lua")
	walk.block(tree, nil, annotator, annotator.scope())
	walk.block(tree, nil, walker, annotator.scope())
end

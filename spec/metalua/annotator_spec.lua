describe("annotator", function()
	local walk = require "metalua.walk"
	local annotator = require "metalua.annotator"

	it("local", function()
		local id = { tag = "Id", "foo" }
		local value = { tag = "String", "bar" }
		local scope = annotator.scope()

		walk.statement({
			tag = "Local",
			{ id },
			{ value },
		}, nil, annotator, scope)

		assert.equal(scope.vars.foo, id.var)
		assert.equal(value, id.var.declaration)
	end)

	it("set", function()
		local id1, id2 = { tag = "Id", "foo" }, { tag = "Id", "foo" }
		local value = { tag = "String", "bar" }
		local scope = annotator.scope()

		walk.block(
		{
			{
				tag = "Local",
				{ id1 },
				{ { tag = "String", "baz" } },
			},
			{
				tag = "Set",
				{ id2 },
				{ value }
			}
		}, nil, annotator, scope)

		assert.equal(scope.vars.foo, id1.var)
		assert.equal(scope.vars.foo, id2.var)

		assert.same({ value } , scope.vars.foo.values)
	end)

	it("reference", function()
		local id = { tag = "Id", "foo" }
		local idUsage = { tag = "Id", "foo" }
		local idNonUsage = { tag = "Id", "foo", "nonusage" }
		local value = { tag = "String", "bar" }

		local scope = annotator.scope()

		walk.block(
		{
			{ tag = "Local", { id }, },
			{
				tag = "Call",
				{ tag = "Id", "bar" },
				idUsage
			},
			{
				tag = "Set",
				{ idNonUsage },
				{ value }
			}
		}, nil, annotator, scope)

		assert.equal(scope.vars.foo, id.var)
		assert.same({ idUsage }, id.var.references)

		assert.equal(nil, id.var.declaration)
		assert.same({ value }, id.var.values)
	end)

	it("hides", function()
		local id1 = { tag = "Id", "foo" }
		local id2 = { tag = "Id", "foo" }
		local value = { tag = "String", "bar" }
		local scope = annotator.scope()

		walk.block({
			{
				tag = "Local",
				{ id1 },
				{ value },
			},
			{
				tag = "Local",
				{ id2 },
				{ value },
			}
		}, nil, annotator, scope)

		assert.equal(scope.vars.foo, id2.var)
		assert.no.equal(scope.vars.foo, id1.var)
		assert.equal(id1.var, id2.var.hides)
	end)
end)

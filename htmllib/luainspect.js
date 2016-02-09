// LuaInspect (c) 2010 David Manura, MIT License.

function get_line_of_domobject(obj) {
	var line = obj.innerText.match(/used-line:(\d+)/);
	if (line) { line = line[1]; }
	return line;
}

function get_linerange_of_objects(objects) {
	var maxlinenum; var minlinenum;

	for (var i = 0; i < objects.length; i++) {
		var linenum = get_line_of_domobject(objects[i].nextElementSibling);

		if (linenum) {
			minlinenum = (minlinenum==null) ? linenum : Math.min(minlinenum, linenum);
			maxlinenum = (maxlinenum==null) ? linenum : Math.max(maxlinenum, linenum);
		}
	}

	return [minlinenum, maxlinenum];
}

function highlight_id(aclass, enable) {
	var methname = enable ? "add" : "remove";
	var objects = document.getElementsByClassName(aclass);
	for (var i = 0; i < objects.length; i++) {
		objects[i].classList[methname]("highlight");
	}

	var linenums = get_linerange_of_objects(objects);
	if (linenums) { for (var i=linenums[0]; i <= linenums[1]; i++) {
		document.getElementById('L'+i).classList[methname]("highlight");
	}}
}

function highlightSameClass(obj, enable) {
	var classes = obj.classList;
	for (var i = 0; i < classes.length; i++) {
		var aclass = classes[i];
		if (aclass.match(/^id\w*\d+/)) {
			highlight_id(aclass, enable);
		}
	}
}

function applyHighlights(className, onOver, onOff) {
	var elements = document.getElementsByClassName(className);
	for (var i = 0; i < elements.length; i++) {
		elements[i].addEventListener('mouseenter', onOver, false);
		elements[i].addEventListener('mouseleave', onOff, false);
	}
}

applyHighlights(
	"id",
	function() {
		highlightSameClass(this, true);
		var next = this.nextElementSibling;
		if(next.tagName == "SPAN") next.style.display = "block";
	},
	function() {
		highlightSameClass(this, false);
		var next = this.nextElementSibling;
		if(next.tagName == "SPAN") next.style.display = "none";
	}
);

applyHighlights(
	"keyword",
	function() { highlightSameClass(this, true); },
	function() { highlightSameClass(this, false); }
);

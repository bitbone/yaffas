function parseScript(_source){
    var source = _source;
    var scripts = new Array();
    
    // Strip out tags
    while (source.indexOf("<script") > -1 || source.indexOf("</script") > -1) {
        var s = source.indexOf("<script");
        var s_e = source.indexOf(">", s);
        var e = source.indexOf("</script", s);
        var e_e = source.indexOf(">", e);
        
        // Add to scripts array
        scripts.push(source.substring(s_e + 1, e));
        // Strip from source
        source = source.substring(0, s) + source.substring(e_e + 1);
    }
    
    // Loop through every script collected and eval it
    for (var i = 0; i < scripts.length; i++) {
        try {
            eval(scripts[i]);
        } 
        catch (ex) {
            // do what you want here when a script fails
        }
    }
    // Return the cleaned source
    return source;
}

/**
 * Takes an array of input elements and returns if some of them are checked
 *
 * @param {Object} e Elements
 * @param {Object} n Name of the checkboxes
 *
 */
function returnChecked(e, n) {
	var ret = [];
    for (var i = 0; i < e.length; ++i) {
        if (e[i].name === n && e[i].checked === true) {
            ret.push(e[i].value);
        }
    }
    return ret;
}

/**
 * fixed version of build-in version of typeof. See: http://javascript.crockford.com/remedial.html
 * @param {Object} obj
 */

function typeOf(obj) {
    if (typeof(obj) == 'object')
        if (obj.length)
            return 'array';
        else
            return 'object';
    else
        return typeof(obj);
}

function _(s, m) {
	if (typeof(Yaffas.LANG) !== "undefined") {
		if (typeof(m) !== "undefined") {
			if (typeof(Yaffas.LANG[m][s]) !== "undefined") {
				return Yaffas.LANG[m][s];
			}
		}
		else {
			if (typeof(Yaffas.LANG[Yaffas.ui.currentPage][s]) !== "undefined") {
				return Yaffas.LANG[Yaffas.ui.currentPage][s];
			}
			if (typeof(Yaffas.LANG["global"][s]) !== "undefined") {
				return Yaffas.LANG["global"][s];
			}

		}
	}
	return "!!! FIXME: "+s+" not translated !!!"
}

/**
 * Returns a HTML list of the given argument. 
 * @param {Object} s can be either a string or an array
 */

function dlg_arg(s) {
	var r = [];
	r.push("<div class='dlg_arguments'><ul>");
	if (typeOf(s) == "array") {
		for (var i = 0; i < s.length; ++i) {
			r.push("<li>"+s[i]+"</li>");
		}
	}
	else {
		r.push("<li>"+s+"</li>");
	}
	r.push("</ul></div>");
	return r.join("");
}

/**
 * Returns the current set authtype
 */
function auth_type() {
	return Yaffas.AUTH.current;
}



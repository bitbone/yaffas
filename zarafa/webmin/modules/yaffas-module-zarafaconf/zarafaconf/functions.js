



function toggle_visibility (name, visible) {
	var elements = document.getElementsByName (name);
	for (var i=0; i<elements.length; i++) {
		elements[i].style.display = (visible ? "block" : "none");
	}
}

var quota_unchanged_color          = "rgb(221, 221, 221)";
var quota_unchanged_color_selected = "rgb(170, 170, 170)";
var quota_changed_color            = "rgb(221, 100, 100)";
var quota_changed_color_selected   = "rgb(171, 100, 100)";
var quota_diff_mails = new Array(3);
for (var i=0; i<quota_diff_mails.length; i++)
	quota_diff_mails[i] = 0;

function quota_select_mail() {
	var messages     = new Array('message_warn', 'message_soft', 'message_hard');
	var radiobuttons = document.getElementsByName ("quota_radiogroup")[0].getElementsByTagName ("input");
	for (var i=0; i<radiobuttons.length && i<messages.length; i++) {
		var style = radiobuttons[i].parentNode.style;
		if (radiobuttons[i].checked) {
			toggle_visibility (messages[i], 1);
			if (quota_diff_mails[i]) {
				style.backgroundColor = quota_changed_color_selected;
				style.fontWeight = "bold";
			}
			else {
				style.backgroundColor = quota_unchanged_color_selected;
				style.fontWeight = "bold";
			}
		}
		else {
			toggle_visibility (messages[i], 0);
			if (quota_diff_mails[i]) {
				style.backgroundColor = quota_changed_color;
				style.fontWeight = "normal";
			}
			else {
				style.backgroundColor = quota_unchanged_color;
				style.fontWeight = "normal";
			}
		}
	}
}

function quota_mail_diff(index) {
	var radiobuttons = document.getElementsByName ("quota_radiogroup")[0].getElementsByTagName ("label");
	quota_diff_mails[index] = 1;
	radiobuttons[index].style.backgroundColor = quota_changed_color_selected;
}

function quota_init() {
	toggle_visibility ('quota_radiogroup', 1);
	toggle_visibility ('quota_textarea_label', 0);
	quota_select_mail();
	var radiobuttons = document.getElementsByName ("quota_radiogroup")[0].getElementsByTagName ("label");
	for (var i=0; i<radiobuttons.length; i++) {
		radiobuttons[i].style.border = "1px solid black";
		radiobuttons[i].style.padding = "0 5px 0 5px";
	}
}

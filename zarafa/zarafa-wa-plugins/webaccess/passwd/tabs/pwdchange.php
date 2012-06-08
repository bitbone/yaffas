<?php

function pwdchange_settings_title(){
	return _("Change Password");
}

function pwdchange_settings_order(){
	return 6;
}

function pwdchange_settings_html(){
	echo '
	<form enctype="multipart/form-data" id="formpwdchange" name="formpwdchange" method="post">
	<input name="pwdchange_username" id="pwdchange_username" type="hidden" value="'.$_SESSION['username'].'">
	<fieldset>
		<legend>'._("Change Password").'</legend>
		<table class="textinput">
			<tr>
				<th><label for="pwdchange_oldpw">'._("Old password").'</label></th>
				<td><input name="pwdchange_oldpw" id="pwdchange_oldpw" type="password" class="text" value=""> </td>
			</tr>
			<tr>
				<th><label for="pwdchange_newpwd1">'._("New password").'</label></th>
				<td><input name="pwdchange_newpwd1" id="pwdchange_newpwd1" type="password" class="text" value=""></td>
			</tr>
			<tr>
				<th><label for="pwdchange_newpwd2">'._("Retype new password").'</label></th>
				<td><input name="pwdchange_newpwd2" id="pwdchange_newpwd2" type="password" class="text" value=""></td>
			</tr>
			<tr>
				<th colspan="2">
				    <center>
					<input type="button" onclick="return doPasswordChange();" value="'._('Change Password').'..." class="inline_button"/>
				    </center>
				</th>
			</tr>
		</table>
	</fieldset>
	</form>
	'; 
} 


?>

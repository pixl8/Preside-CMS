<cfparam name="args.parent_folder" type="string" />
<cfscript>
	allowedTypes = rc.allowedTypes ?: "";
	multiple     = rc.multiple     ?: "";
	folderLink   = event.buildAdminLink(
		  linkTo      = "assetManager.assetPickerBrowser"
		, queryString = "folder=#args.parent_folder#&allowedTypes=#allowedTypes#&multiple=#multiple#"
	);
</cfscript>
<cfoutput>
	<tr class="clickable">
		<td class="folder-icon"><i class="fa fa-folder-open blue"></i></td>
		<td><a href="#folderLink#">..</a></td>
	</tr>
</cfoutput>
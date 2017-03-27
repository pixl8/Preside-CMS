<cfparam name="args.label"        type="string" />
<cfparam name="args.id"           type="string" />

<cfscript>
	allowedTypes = rc.allowedTypes ?: "";
	multiple     = rc.multiple     ?: "";
	savedFilters = rc.savedFilters ?: "";
	folderLink   = event.buildAdminLink(
		  linkTo      = "assetManager.assetPickerBrowser"
		, queryString = "folder=#args.id#&allowedTypes=#allowedTypes#&savedFilters=#savedFilters#&multiple=#multiple#"
	);
</cfscript>

<cfoutput>
	<tr class="clickable">
		<td class="folder-icon"><i class="fa fa-folder-open blue"></i></td>
		<td>
			<a class="folder-view-link" href="#folderLink#"><span class="folder-name">#args.label#</span></a>
		</td>
	</tr>
</cfoutput>
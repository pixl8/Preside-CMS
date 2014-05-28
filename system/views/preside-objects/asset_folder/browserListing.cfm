<cfscript>
	param name="args.label" type="string";
	param name="args.id"    type="string";

	permissionContext = Duplicate( prc.permissionContext ?: [] );
	permissionContext.prepend( args.id );
</cfscript>

<cfif hasPermission( permissionKey="assetmanager.general.navigate", context="assetmanagerfolder", contextKeys=permissionContext )>
	<cfoutput>
		<tr>
			<td class="folder-icon"><i class="fa fa-folder-open blue"></i></td>
			<td>
				<a class="folder-view-link" href="#event.buildAdminLink( linkTo="assetManager", queryString="folder=#args.id#")#"><span class="folder-name">#args.label#</span></a>

				<cfif hasPermission( permissionKey="assetmanager.folders.edit", context="assetmanagerfolder", contextKeys=permissionContext )>
					<form class="edit-folder-form" action="#event.buildAdminLink( linkTo="assetManager.renameFolderAction" )#" method="post">
						<input type="hidden" name="folder" value="#args.id#" />

						#renderFormControl(
							  name         = "label"
							, type         = "textInput"
							, context      = "inline"
							, defaultValue = args.label
							, layout       = ""
						)#
					</form>
				</cfif>
			</td>
			<td>
				<div class="action-buttons">
					<cfif hasPermission( permissionKey="assetmanager.folders.edit", context="assetmanagerfolder", contextKeys=permissionContext )>
						<a class="blue rename-folder" href="##" data-context-key="e">
							<i class="fa fa-pencil bigger-130"></i>
						</a>
					</cfif>
					<cfif hasPermission( permissionKey="assetmanager.folders.delete", context="assetmanagerfolder", contextKeys=permissionContext )>
						<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashFolderAction", queryString="folder=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.trash.folder.link", data=[ urlEncodedFormat( args.label ) ] )#">
							<i class="fa fa-trash-o bigger-130"></i>
						</a>
					</cfif>
				</div>
			</td>
		</tr>
	</cfoutput>
</cfif>
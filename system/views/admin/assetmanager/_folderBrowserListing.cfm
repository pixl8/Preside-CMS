<cfscript>
	param name="args.label" type="string";
	param name="args.id"    type="string";

	currentParentFolder = rc.folder ?: "";

	permissionContext = Duplicate( prc.permissionContext ?: [] );
	permissionContext.prepend( args.id );
</cfscript>

<cfif hasCmsPermission( permissionKey="assetmanager.general.navigate", context="assetmanagerfolder", contextKeys=permissionContext )>
	<cfoutput>
		<tr>
			<td class="folder-icon"><i class="fa fa-folder-open blue"></i></td>
			<td>
				<a class="folder-view-link" href="#event.buildAdminLink( linkTo="assetManager", queryString="folder=#args.id#")#"><span class="folder-name">#args.label#</span></a>
			</td>
			<td>
				<div class="action-buttons">
					<cfif hasCmsPermission( permissionKey="assetmanager.folders.edit", context="assetmanagerfolder", contextKeys=permissionContext )>
						<a class="blue rename-folder" href="#event.buildAdminLink( linkTo="assetmanager.editFolder", queryString="id=#args.id#&folder=#currentParentFolder#" )#" data-context-key="e">
							<i class="fa fa-pencil bigger-130"></i>
						</a>
					</cfif>
					<cfif hasCmsPermission( permissionKey="assetmanager.folders.delete", context="assetmanagerfolder", contextKeys=permissionContext )>
						<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashFolderAction", queryString="folder=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.trash.folder.link", data=[ urlEncodedFormat( args.label ) ] )#">
							<i class="fa fa-trash-o bigger-130"></i>
						</a>
					</cfif>
				</div>
			</td>
		</tr>
	</cfoutput>
</cfif>
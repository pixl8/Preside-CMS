<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}
	isTrash = activeFolder == "trash";

	permissionContext   = prc.permissionContext ?: [];
	hasDeletePermission = hasCmsPermission( permissionKey="assetmanager.assets.delete" , context="assetmanagerfolder", contextKeys=permissionContext );
</cfscript>

<cfoutput>
	<div class="form-actions" id="multi-action-buttons">
		<cfif hasDeletePermission>
			<button class="btn btn-danger confirmation-prompt" type="submit" name="delete" disabled="disabled" data-global-key="d" title="#translateResource( "cms:assetmanager.browser.deleteMulti.prompt" )#">
				<i class="fa fa-trash-o bigger-110"></i>
				#translateResource( "cms:assetmanager.browser.deleteMulti.btn" )#
			</button>
		</cfif>

		<cfif isTrash>
			<button class="btn btn-info" disabled="disabled" data-global-key="m" data-toggle="move-assets-dialog" data-target="restore-assets-form" data-dialog-title="#translateResource( 'cms:assetmanager.restore.multi.assets.dialog.title' )#">
				<i class="fa fa-magic bigger-110"></i>
				#translateResource( "cms:assetmanager.browser.restoreMulti.btn" )#
			</button>
		<cfelse>
			<button class="btn btn-info" disabled="disabled" data-global-key="m" data-toggle="move-assets-dialog" data-target="move-assets-form" data-dialog-title="#translateResource( 'cms:assetmanager.move.multi.assets.dialog.title' )#">
				<i class="fa fa-folder bigger-110"></i>
				#translateResource( "cms:assetmanager.browser.moveMulti.btn" )#
			</button>
		</cfif>

		<button class="btn btn-info" type="submit" name="clearDerivatives" disabled="disabled" title="#translateResource( "cms:assetmanager.clear.derivatives.prompt" )#">
			<i class="fa fa-redo bigger-110"></i>
			#translateResource( "cms:assetmanager.clear.derivatives.btn" )#
		</button>
	</div>
</cfoutput>
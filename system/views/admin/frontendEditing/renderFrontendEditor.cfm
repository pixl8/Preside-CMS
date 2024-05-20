<!---@feature admin and cms--->
<cfscript>
	renderedContent  = args.renderedContent ?: "";
	args.containerId = "_" & Left( LCase( Hash( CreateUUId() ) ), 8 );

	if ( event.isAdminUser() ) {
		prc.hasCmsSaveDraftPermissions = prc.hasCmsSaveDraftPermissions ?: hasCmsPermission( permissionKey="sitetree.saveDraft", context="page", contextKeys=event.getPagePermissionContext() );
		prc.hasCmsPublishPermissions   = prc.hasCmsPublishPermissions   ?: hasCmsPermission( permissionKey="sitetree.publish", context="page", contextKeys=event.getPagePermissionContext() );
		prc.hasCmsPageEditPermissions  = prc.hasCmsPageEditPermissions  ?: ( prc.hasCmsSaveDraftPermissions || prc.hasCmsPublishPermissions ) && hasCmsPermission( permissionKey="sitetree.edit", context="page", contextKeys=event.getPagePermissionContext() );
		prc.adminToolbarDisplayMode    = prc.adminToolbarDisplayMode    ?: getSystemSetting( "frontend-editing", "admin_toolbar_mode", "fixed" );
		prc.adminQuickEditDisabled     = prc.adminQuickEditDisabled     ?: isTrue( getSystemSetting( "frontend-editing", "disable_quick_edit" ) );
	}
</cfscript>

<cfoutput>
	<cfif !event.isAdminUser() or !prc.hasCmsPageEditPermissions or prc.adminToolbarDisplayMode eq "none" or prc.adminQuickEditDisabled>
		#renderedContent#
	<cfelse>
		<!-- container: #args.containerId# -->#Trim( renderedContent )#<!-- !container: #args.containerId# -->
		<script type="text/template" class="content-editor">
			#toBase64( renderView( view="/admin/frontendEditing/_editorTemplate", args=args ) )#
		</script>
	</cfif>
</cfoutput>
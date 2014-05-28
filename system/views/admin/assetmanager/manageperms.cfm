<cfscript>
	folderId     = rc.folder  ?: "";
	folderRecord = prc.folder ?: QueryNew( 'label' );

	prc.pageIcon     = "lock";
	prc.pageTitle    = translateResource( uri="cms:assetmanager.manageperms.title", data=[ folderRecord.label ] );;
	prc.pageSubTitle = translateResource( uri="cms:assetmanager.manageperms.subtitle", data=[ folderRecord.label ] );;
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.permissions.contextPermsForm", args={
		  permissionKeys       = [ "assetmanager.general.*", "assetmanager.folders.*", "assetmanager.assets.*" ]
		, context              = "assetmanagerfolder"
		, contextKey           = folderId
		, inheritedContextKeys = prc.inheritedPermissionContext ?: []
		, saveAction           = event.buildAdminLink( linkTo="assetmanager.savePermsAction", queryString="folder=#folderId#" )
		, cancelAction         = event.buildAdminLink( linkTo="assetmanager.index"          , queryString="folder=#folderId#" )
	} )#
</cfoutput>
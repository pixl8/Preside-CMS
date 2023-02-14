<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.edit.folder.title" );

	isRootFolder = ( rc.folder ?: "" ) == ( prc.rootFolderId ?: "" );

	event.addAdminBreadCrumb(
		  title = prc.pageSubTitle
		, link  = event.buildAdminLink( linkTo="assetmanager.editFolder", queryString="folder=#( rc.folder ?: '' )#" )
	);
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object            = "asset_folder"
		, id                = rc.folder  ?: ""
		, record            = prc.record ?: {}
		, editRecordAction  = event.buildAdminLink( linkTo='assetmanager.editFolderAction', queryString='folder=#( rc.folder ? : "" )#' )
		, cancelAction      = event.buildAdminLink( linkTo='assetmanager.index' )
		, mergeWithFormName = isRootFolder ? "preside-objects.asset_folder.admin.edit.root" : ""
		, additionalArgs    = { fields = { parent_folder = { excludeDescendants = rc.folder ?: "" } } }
	} )#
</cfoutput>
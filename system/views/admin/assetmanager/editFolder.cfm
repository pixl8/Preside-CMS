<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.edit.folder.title" );

	event.addAdminBreadCrumb(
		  title = prc.pageSubTitle
		, link  = event.buildAdminLink( linkTo="assetmanager.editFolder", queryString="id=#( rc.id ?: '' )#" )
	);
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "asset_folder"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='assetmanager.editFolderAction', queryString='folder=#( rc.folder ? : "" )#' )
		, cancelAction     = event.buildAdminLink( linkTo='assetmanager.index' )
	} )#
</cfoutput>
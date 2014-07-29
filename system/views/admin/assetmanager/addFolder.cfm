<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.add.folder.title" );

	folderQS = 'folder=#( rc.folder ?: "" )#';

	event.addAdminBreadCrumb(
		  title = prc.pageSubTitle
		, link  = event.buildAdminLink( linkTo="assetmanager.addFolder", queryString=folderQS )
	);

</cfscript>


<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "asset_folder"
		, addRecordAction       = event.buildAdminLink( linkTo='assetmanager.addFolderAction', queryString=folderQS )
		, allowAddAnotherSwitch = true
		, cancelAction          = event.buildAdminLink( linkTo='assetmanager.index', querystring=folderQS )
	} )#
</cfoutput>
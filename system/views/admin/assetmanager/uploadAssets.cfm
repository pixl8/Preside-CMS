<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.upload.assets.title" );

	folderQS = 'folder=#( rc.folder ?: "" )#';

	event.addAdminBreadCrumb(
		  title = prc.pageSubTitle
		, link  = event.buildAdminLink( linkTo="assetmanager.uploadAssets", queryString=folderQS )
	);

</cfscript>


<cfoutput>#renderView( "admin/assetmanager/assetDropZone" )#</cfoutput>
<cfscript>
	prc.pageIcon  = "picture-o";
	prc.pageTitle = translateResource( "cms:assetManager" );

	folder              = rc.folder ?: "";
	permissionContext   = prc.permissionContext ?: [];
	hasUploadPermission = hasPermission( permissionKey="assetmanager.assets.upload", context="assetmanagerfolder", contextKeys=permissionContext )
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif Len( Trim( folder ) ) && hasPermission( permissionKey="assetmanager.folders.manageContextPerms", context="assetmanagerfolder", contextKeys=permissionContext )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="assetmanager.manageperms", queryString="folder=#folder#" )#" data-global-key="p">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-lock"></i>
					#translateResource( "cms:assetmanager.manageperms.button" )#
				</button>
			</a>
		</cfif>
	</div>

	<div class="row">
		<div class="#( hasUploadPermission ? 'col-lg-8 col-md-8 col-sm-7 col-xs-6' : 'col-md-12' )#">
			#renderView( "admin/assetmanager/listingtable" )#
		</div>

		<cfif hasUploadPermission>
			<div class="col-lg-4 col-md-4 col-sm-5 col-xs-6">
				#renderView( "admin/assetmanager/assetDropZone" )#
			</div>
		</cfif>
	</div>
</cfoutput>
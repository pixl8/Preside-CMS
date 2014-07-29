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

	<cfif hasUploadPermission>
		<div class="tabbable">
			<ul class="nav nav-tabs">
				<li class="active">
					<a data-toggle="tab" href="##browse">
						<i class="green fa fa-search bigger-110"></i>
						#translateResource( uri="cms:assetmanager.browse.tab" )#
					</a>
				</li>

				<li>
					<a data-toggle="tab" href="##upload">
						<i class="blue fa fa-cloud-upload bigger-110"></i>
						#translateResource( uri="cms:assetmanager.upload.tab" )#
					</a>
				</li>
			</ul>


			<div class="tab-content">
				<div id="browse" class="tab-pane in active">
	</cfif>

	#renderView( "admin/assetmanager/listingtable" )#

	<cfif hasUploadPermission>
				</div>

				<div id="upload" class="tab-pane">
					#renderView( "admin/assetmanager/assetDropZone" )#
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>


<cfscript>
	prc.pageIcon  = "picture-o";
	prc.pageTitle = translateResource( "cms:assetManager" );

	folder              = rc.folder ?: "";
	folderTitle         = prc.folder.label ?: translateResource( "cms:assetmanager.root.folder" );
	permissionContext   = prc.permissionContext ?: [];
	folderTree          = prc.folderTree ?: [];
	hasUploadPermission = hasPermission( permissionKey="assetmanager.assets.upload", context="assetmanagerfolder", contextKeys=permissionContext )
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-sm-5 col-md-4 col-lg-3">
			<div class="navigation-tree-container">
				<div class="preside-tree-nav tree tree-unselectable" data-nav-list="1" data-nav-list-child-selector=".tree-folder-header,.tree-item">
					<cfloop array="#folderTree#" index="node">
						#renderView( view="/admin/assetmanager/_treeFolderNode", args=node )#
					</cfloop>
				</div>
			</div>
		</div>
		<div class="col-sm-7 col-md-8 col-lg-9">
			<h3 class="blue folder-title"><i class="fa fa-folder"></i> <span class="title">#folderTitle#</span></h3>

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

			<!--- <div class="top-right-button-group">
				<cfif Len( Trim( folder ) ) && hasPermission( permissionKey="assetmanager.folders.manageContextPerms", context="assetmanagerfolder", contextKeys=permissionContext )>
					<a class="pull-right inline" href="#event.buildAdminLink( linkTo="assetmanager.manageperms", queryString="folder=#folder#" )#" data-global-key="p">
						<button class="btn btn-default btn-sm">
							<i class="fa fa-lock"></i>
							#translateResource( "cms:assetmanager.manageperms.button" )#
						</button>
					</a>
				</cfif>
			</div>--->

			#renderView( "admin/assetmanager/listingtable" )#

			<cfif hasUploadPermission>
						</div>

						<div id="upload" class="tab-pane">
							#renderView( "admin/assetmanager/assetDropZone" )#
						</div>
					</div>
				</div>
			</cfif>
		</div>
	</div>


</cfoutput>


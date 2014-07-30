<cfscript>
	param name="args.folderId"    type="string";
	param name="args.folderTitle" type="string";

	permissionContext = prc.permissionContext ?: [];
	args.folderTitle  = args.folderTitle == "$root" ? translateResource( "cms:assetmanager.root.folder" ) : args.folderTitle;

	hasUploadPermission            = hasPermission( permissionKey="assetmanager.assets.upload"             , context="assetmanagerfolder", contextKeys=permissionContext );
	hasAddFolderPermission         = hasPermission( permissionKey="assetmanager.folders.add"               , context="assetmanagerfolder", contextKeys=permissionContext );
	hasEditFolderPermission        = hasPermission( permissionKey="assetmanager.folders.edit"              , context="assetmanagerfolder", contextKeys=permissionContext );
	hasManageFolderPermsPermission = hasPermission( permissionKey="assetmanager.folders.manageContextPerms", context="assetmanagerfolder", contextKeys=permissionContext );
	hasAnyFolderPermissions        = hasAddFolderPermission || hasEditFolderPermission || hasManageFolderPermsPermission;
</cfscript>

<cfoutput>
	<h3 class="blue folder-title pull-left"><i class="fa fa-folder"></i> #args.folderTitle#</h3>

	<div class="pull-right">
		<cfif hasUploadPermission>
			<a class="inline" href="#event.buildAdminLink( linkTo="assetmanager.uploadAssets", queryString="folder=#args.folderId#" )#" data-global-key="l" class="upload-button">
				<button class="btn btn-primary btn-sm">
					<i class="fa fa-cloud-upload"></i>
					#translateResource( "cms:assetmanager.upload.button" )#
				</button>
			</a>
		</cfif>

		<div class="btn-group">
			<button data-toggle="dropdown" class="btn btn-sm btn-default inline">
				<span class="fa fa-caret-down"></span>
				#translateResource( "cms:assetmanager.folder.options.button" )#
			</button>

			<cfif hasAnyFolderPermissions>
				<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
					<cfif hasAddFolderPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.addFolder", queryString="folder=#args.folderId#" )#" data-global-key="a"><i class="fa fa-fw fa-plus"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.add" )#</a></li>
					</cfif>
					<cfif hasEditFolderPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.editFolder", queryString="folder=#args.folderId#" )#" data-global-key="e"><i class="fa fa-fw fa-pencil"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.edit" )#</a></li>
					</cfif>
					<cfif hasManageFolderPermsPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.managePerms", queryString="folder=#args.folderId#" )#"><i class="fa fa-fw fa-lock"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.manage.perms" )#</a></li>
					</cfif>
				</ul>
			</cfif>
		</div>
	</div>
</cfoutput>
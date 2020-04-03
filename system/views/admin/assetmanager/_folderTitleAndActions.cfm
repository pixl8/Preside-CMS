<cfscript>
	param name="args.folderId"       type="string";
	param name="args.folderTitle"    type="string";
	param name="args.isSystemFolder" type="boolean" default=false;

	permissionContext = prc.permissionContext ?: [];

	hasAddFolderPermission         = !args.isSystemFolder && hasCmsPermission( permissionKey="assetmanager.folders.add"               , context="assetmanagerfolder", contextKeys=permissionContext );
	hasDeleteFolderPermission      = !args.isSystemFolder && args.folderTitle != "$root" && hasCmsPermission( permissionKey="assetmanager.folders.delete", context="assetmanagerfolder", contextKeys=permissionContext );
	hasUploadPermission            = hasCmsPermission( permissionKey="assetmanager.assets.upload"             , context="assetmanagerfolder", contextKeys=permissionContext );
	hasEditFolderPermission        = hasCmsPermission( permissionKey="assetmanager.folders.edit"              , context="assetmanagerfolder", contextKeys=permissionContext );
	hasManageFolderPermsPermission = hasCmsPermission( permissionKey="assetmanager.folders.manageContextPerms", context="assetmanagerfolder", contextKeys=permissionContext );
	hasManageLocationsPermission   = hasCmsPermission( permissionKey="assetmanager.storagelocations.manage" );
	hasAnyFolderPermissions        = hasAddFolderPermission || hasEditFolderPermission || hasManageFolderPermsPermission || hasDeleteFolderPermission || hasManageLocationsPermission;

	args.folderTitle  = args.folderTitle == "$root" ? translateResource( "cms:assetmanager.root.folder" ) : args.folderTitle;
</cfscript>

<cfoutput>
	<div class="pull-right">
		<cfif hasUploadPermission>
			<a class="inline" href="#event.buildAdminLink( linkTo="assetmanager.uploadAssets", queryString="folder=#args.folderId#" )#" data-global-key="l" class="upload-button">
				<button class="btn btn-primary btn-sm">
					<i class="fa fa-cloud-upload"></i>
					#translateResource( "cms:assetmanager.upload.button" )#
				</button>
			</a>
		</cfif>

		<cfif hasAnyFolderPermissions>
			<div class="btn-group">
				<button data-toggle="dropdown" class="btn btn-sm btn-default inline">
					<span class="fa fa-caret-down"></span>
					#translateResource( "cms:assetmanager.folder.options.button" )#
				</button>

				<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
					<cfif hasAddFolderPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.addFolder", queryString="folder=#args.folderId#" )#" data-global-key="a"><i class="fa fa-fw fa-plus"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.add" )#</a></li>
					</cfif>
					<cfif hasEditFolderPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.editFolder", queryString="folder=#args.folderId#" )#" data-global-key="e"><i class="fa fa-fw fa-pencil"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.edit" )#</a></li>
					</cfif>
					<cfif hasManageLocationsPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.setFolderLocation", queryString="folder=#args.folderId#" )#"><i class="fa fa-fw fa-folder"></i>&nbsp; #translateResource( uri="cms:assetmanager.set.folder.location.menu.title" )#</a></li>
					</cfif>
					<cfif hasEditFolderPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.clearFolderDerivativesAction", queryString="folder=#args.folderId#" )#"><i class="fa fa-fw fa-redo"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.clear.derivatives" )#</a></li>
					</cfif>
					<cfif hasManageFolderPermsPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.managePerms", queryString="folder=#args.folderId#" )#"><i class="fa fa-fw fa-lock"></i>&nbsp; #translateResource( uri="cms:assetmanager.folder.options.manage.perms" )#</a></li>
					</cfif>
					<cfif hasDeleteFolderPermission>
						<li><a href="#event.buildAdminLink( linkTo="assetmanager.trashFolderAction", queryString="folder=#args.folderId#" )#" class="confirmation-prompt" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.trash.folder.link", data=[ args.folderTitle ] ) )#"><i class="fa fa-fw fa-trash"></i>&nbsp; #translateResource( uri="cms:assetmanager.trash.folder.menu.title" )#</a></li>
					</cfif>
				</ul>
			</div>
		</cfif>
	</div>
</cfoutput>
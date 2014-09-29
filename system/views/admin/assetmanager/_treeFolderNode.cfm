<cfscript>
	param name="args.id"                 type="string";
	param name="args.access_restriction" type="string";
	param name="args.label"              type="string";
	param name="args.children"           type="array";
	param name="args.permissionContext"  type="array";

	selected        = rc.folder ?: "";
	hasChildren     = args.children.len();
	hasRestrictions = args.access_restriction != "none";

	if ( args.label == "$root" ) {
		args.label = translateResource( "cms:assetmanager.root.folder" );
	}

	hasAddFolderPermission         = hasCmsPermission( permissionKey="assetmanager.folders.add"               , context="assetmanagerfolder", contextKeys=args.permissionContext );
	hasEditFolderPermission        = hasCmsPermission( permissionKey="assetmanager.folders.edit"              , context="assetmanagerfolder", contextKeys=args.permissionContext );
	hasManageFolderPermsPermission = hasCmsPermission( permissionKey="assetmanager.folders.manageContextPerms", context="assetmanagerfolder", contextKeys=args.permissionContext );
	hasAnyFolderPermissions        = hasAddFolderPermission || hasEditFolderPermission || hasManageFolderPermsPermission;
</cfscript>

<cfif hasCmsPermission( permissionKey="assetmanager.general.navigate", context="assetmanagerfolder", contextKeys=[ args.id ] )>
	<cfoutput>
		<cfsavecontent variable="nodeOptions">
			<cfif hasAnyFolderPermissions>
				<div class="node-options">
					<cfif hasAddFolderPermission>
						<a href="#event.buildAdminLink( linkTo="assetmanager.addFolder", queryString="folder=#args.id#" )#" data-context-key="a" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.folder.options.add" ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-fw fa-plus"></i></a>
					</cfif>
					<cfif hasEditFolderPermission>
						<a href="#event.buildAdminLink( linkTo="assetmanager.editFolder", queryString="folder=#args.id#" )#" data-context-key="e" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.folder.options.edit" ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-fw fa-pencil"></i></a>
					</cfif>
					<cfif hasManageFolderPermsPermission>
						<a href="#event.buildAdminLink( linkTo="assetmanager.managePerms", queryString="folder=#args.id#" )#" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.folder.options.manage.perms" ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-fw fa-lock"></i></a>
					</cfif>
				</div>
			</cfif>
		</cfsavecontent>

		<cfif hasChildren>
			<div class="tree-folder">
				<div class="tree-node tree-folder-header<cfif selected eq args.id> selected</cfif>" data-folder-id="#args.id#">
					<i class="fa fa-fw fa-folder tree-node-toggler tree-node-icon"></i>
					<cfif hasRestrictions>
						<small><i class="fa fa-lock red"></i></small>
					</cfif>

					<div class="tree-folder-name node-name">
						<span class="folder-name">#args.label#</span>
						#Trim( nodeOptions )#
					</div>
				</div>
				<div class="tree-folder-content">
					<cfloop array="#args.children#" index="child">
						#renderView( view="/admin/assetmanager/_treeFolderNode", args=child )#
					</cfloop>
				</div>
			</div>
		<cfelse>
			<div class="tree-node tree-item<cfif selected eq args.id> selected</cfif>" data-folder-id="#args.id#">
				<div class="tree-item-name node-name">
					<i class="fa fa-fw fa-folder-o tree-node-icon"></i>
					<cfif hasRestrictions>
						<small><i class="fa fa-lock red"></i></small>
					</cfif>
					<span class="folder-name">#args.label#</span>
					#Trim( nodeOptions )#
				</div>
			</div>
		</cfif>
	</cfoutput>
</cfif>
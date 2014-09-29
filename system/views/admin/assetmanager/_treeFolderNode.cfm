<cfscript>
	param name="args.id"       type="string";
	param name="args.label"    type="string";
	param name="args.children" type="array";

	selected    = rc.folder ?: "";
	hasChildren = args.children.len();

	if ( args.label == "$root" ) {
		args.label = translateResource( "cms:assetmanager.root.folder" );
	}
</cfscript>

<cfif hasCmsPermission( permissionKey="assetmanager.general.navigate", context="assetmanagerfolder", contextKeys=[ args.id ] )>
	<cfoutput>
		<cfif hasChildren>
			<div class="tree-folder">
				<div class="tree-node tree-folder-header<cfif selected eq args.id> selected</cfif>" data-folder-id="#args.id#">
					<i class="fa fa-folder fa-fw tree-node-toggler"></i>

					<div class="tree-folder-name node-name">
						<span class="folder-name">#args.label#</span>
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
					<i class="fa fa-folder fa-fw"></i>
					<span class="folder-name">#args.label#</span>
				</div>
			</div>
		</cfif>
	</cfoutput>
</cfif>
<cfscript>
	param name="args.id"                 type="string";
	param name="args.access_restriction" type="string";
	param name="args.label"              type="string";
	param name="args.storage_location"   type="string";
	param name="args.asset_count"        type="string";
	param name="args.is_system_folder"   type="any";
	param name="args.children"           type="array";
	param name="args.permissionContext"  type="array";

	selected        = rc.folder ?: "";
	hasChildren     = args.children.len();
	hasRestrictions = args.access_restriction != "none";

	if ( args.label == "$root" ) {
		args.label = translateResource( "cms:assetmanager.root.folder" );
	}
</cfscript>

<cfif hasCmsPermission( permissionKey="assetmanager.general.navigate", context="assetmanagerfolder", contextKeys=[ args.id ] )>
	<cfoutput>
		<cfif hasChildren>
			<div class="tree-folder">
				<div class="tree-node tree-folder-header<cfif selected eq args.id> selected</cfif>" data-folder-id="#args.id#">
					<i class="fa fa-fw fa-folder tree-node-toggler tree-node-icon<cfif IsTrue( args.is_system_folder )> grey</cfif>"></i>

					<cfif hasRestrictions>
						<small><i class="fa fa-lock red"></i></small>
					</cfif>

					<div class="tree-folder-name node-name">
						<span class="folder-name">
							<cfif Len( Trim( args.storage_location ) )><span class="location-name">#args.storage_location#:</span> </cfif>
							#args.label# (#args.asset_count#)
						</span>
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
					<i class="fa fa-fw fa-folder-o tree-node-icon<cfif IsTrue( args.is_system_folder )> grey</cfif>"></i>
					<cfif hasRestrictions>
						<small><i class="fa fa-lock red"></i></small>
					</cfif>
					<span class="folder-name">
						<cfif Len( Trim( args.storage_location ) )>#args.storage_location#:</cfif>
						#args.label# (#args.asset_count#)
					</span>
				</div>
			</div>
		</cfif>
	</cfoutput>
</cfif>
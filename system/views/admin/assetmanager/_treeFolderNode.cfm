<cfscript>
	param name="args.id"       type="string";
	param name="args.label"    type="string";
	param name="args.children" type="array";

	selected    = rc.selected ?: "";
	hasChildren = args.children.len();
</cfscript>

<cfoutput>
	<cfif hasChildren>
		<div class="tree-folder">
			<div class="tree-node tree-folder-header<cfif selected eq args.id> selected-node</cfif>" data-context-container="#args.id#" data-folder-id="#args.id#">
				<i class="fa fa-folder"></i>

				<div class="tree-folder-name node-name">
					#args.label#
				</div>
			</div>
			<div class="tree-folder-content">
				<cfloop array="#args.children#" index="child">
					#renderView( view="/admin/assetmanager/_treeFolderNode", args=child )#
				</cfloop>
			</div>
		</div>
	<cfelse>
		<div class="tree-node tree-item<cfif selected eq args.id> selected-node</cfif>" data-context-container="#args.id#" data-folder-id="#args.id#">
			<div class="tree-item-name node-name">
				<i class="fa fa-folder"></i>
				#args.label#
			</div>
		</div>
	</cfif>
</cfoutput>
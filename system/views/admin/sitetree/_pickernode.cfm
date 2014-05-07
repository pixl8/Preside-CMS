<cfscript>
	param name="args.id"    type="string";
	param name="args.label" type="string";
</cfscript>

<cfoutput>
	<cfif args.hasChildren>
		<div class="tree-folder tree-node" data-node-id="#args.id#">
			<div class="tree-folder-header">
				<i class="fa fa-folder-close"></i>
				<div class="tree-folder-name node-name">
					<span class="page-title">#args.label#</span>
					<div class="node-options">
						<i class="fa fa-ok-circle green"></i>
					</div>
				</div>
			</div>
			<div class="tree-folder-content">
				<cfloop array="#args.children#" index="child">
					#renderView( view="/admin/sitetree/_pickernode", args=child )#
				</cfloop>
			</div>
		</div>
	<cfelse>
		<div class="tree-item tree-node" data-node-id="#args.id#">
			<div class="tree-item-name node-name">
				<i class="fa fa-file-alt"></i>
				<span class="page-title">#args.label#</span>
				<div class="node-options">
					<i class="fa fa-ok-circle green"></i>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>
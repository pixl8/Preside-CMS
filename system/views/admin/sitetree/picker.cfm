<cfscript>
	tree = event.getValue( name="tree", defaultValue=ArrayNew(1), private=true );
</cfscript>

<cfoutput>
	<cfif ArrayLen( tree )>
		<div class="site-tree site-tree-picker tree tree-unselectable">
			<cfloop array="#tree#" index="node">
				#renderView( view="/admin/sitetree/_pickernode", args=node )#
			</cfloop>
		</div>
	<cfelse>
		<em>#translateResource( "cms:sitetree.picker.empty.tree" )#</em>
	</cfif>
</cfoutput>
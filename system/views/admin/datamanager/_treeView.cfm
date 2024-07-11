<!---@feature admin--->
<cfscript>
	topLevel       = args.topLevel ?: Querynew('');
	gridFields     = args.gridFields ?: [];
	objectName     = args.objectName;
	draftsEnabled  = IsTrue( args.draftsEnabled  ?: "" );
	isMultilingual = IsTrue( args.isMultilingual ?: "" );
	treeFetchUrl   = args.treeFetchUrl ?: "";

	event.include( "/js/admin/specific/sitetree/" )
	     .include( "/css/admin/specific/sitetree/" )
	     .includeData( { treeFetchUrl=treeFetchUrl } );
</cfscript>
<cfoutput>
	<table class="table table-striped table-hover tree-table">
		<thead>
			<tr>
				<cfloop array="#gridFields#" index="fieldName">
					<th>#translatePropertyName( objectName, fieldName, "listing" )#</th>
				</cfloop>
				<cfif draftsEnabled>
					<th>#translateResource( uri="cms:datamanager.column.draft.status" )#</th>
				</cfif>
				<cfif isMultilingual>
					<th>#translateResource( uri="cms:datamanager.translate.column.status" )#</th>
				</cfif>
			</tr>
		</thead>
		<tbody data-nav-list-child-selector="tr" data-nav-list="1">
			<cfloop query="topLevel">
				<cfset args.record = QueryRowToStruct( topLevel, topLevel.currentRow ) />

				#renderView( view="/admin/datamanager/_treeNode", args=args )#
			</cfloop>
		</tbody>
	</table>
</cfoutput>
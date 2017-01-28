<cfscript>
	pageType        = rc.pageType         ?: "";
	parentId        = rc.parent           ?: "";
	canAddChildren  = prc.canAddChildren  ?: false;
	gridFields      = prc.gridFields      ?: [];
	cleanGridFields = prc.cleanGridFields ?: [];
	gridFieldTitles = prc.gridFieldTitles ?: [];

	objectTitle    = translateResource( uri="page-types.#pageType#:name", defaultValue=pageType );
	addRecordTitle = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitle ) ] );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = pageType
		, objectTitle     = LCase( objectTitle )
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sitetree.getManagedPagesForAjaxDataTables&parent=#parentId#&pageType=#pageType#&gridFields=#ArrayToList( gridFields )#" )
		, useMultiActions = false
		, allowSearch     = true
	} );
</cfscript>

<cfoutput>
	<cfif canAddChildren>
		<div class="top-right-button-group">
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#parentId#&page_type=#pageType#" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</div>
	</cfif>

	<div class="table-responsive">
		<table id="object-listing-table-#LCase( pageType )#" class="table table-hover object-listing-table">
			<thead>
				<tr>
					<cfloop array="#gridFields#" item="fieldName" index="i">
						<th data-field="#cleanGridFields[ i ]#">#gridFieldTitles[ i ]#</th>
					</cfloop>
					<th data-field="status" data-sortable="false">#translateResource( uri="cms:sitetree.table.status.header" )#</th>
					<th data-width="12em">&nbsp;</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr a:nth-of-type(1)">
			</tbody>
		</table>
	</div>
</cfoutput>
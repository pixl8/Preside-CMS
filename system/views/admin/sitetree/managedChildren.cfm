<cfscript>
	pageType = rc.pageType ?: "";
	parentId = rc.parent   ?: "";

	objectTitle    = translateResource( uri="page-types.#pageType#:name", defaultValue=pageType );
	addRecordTitle = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitle ) ] );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName      = pageType
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sitetree.getManagedPagesForAjaxDataTables&parent=#parentId#&pageType=#pageType#" )
		, useMultiActions = false
		, allowSearch     = true
	} );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#parentId#&page_type=#pageType#" )#" data-global-key="a">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-plus"></i>
				#addRecordTitle#
			</button>
		</a>
	</div>

	<div class="table-responsive">
		<table id="object-listing-table-#LCase( pageType )#" class="table table-hover object-listing-table">
			<thead>
				<tr>
					<th data-field="title">#translateResource( uri="preside-objects.page:field.title.title" )#</th>
					<th data-field="active">#translateResource( uri="preside-objects.page:field.active.title" )#</th>
					<th data-field="datecreated">#translateResource( uri="preside-objects.page:field.datecreated.title", defaultValue=translateResource( "cms:preside-objects.default.field.datecreated.title" ) )#</th>
					<th>&nbsp;</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr a:nth-of-type(1)">
			</tbody>
		</table>
	</div>
</cfoutput>
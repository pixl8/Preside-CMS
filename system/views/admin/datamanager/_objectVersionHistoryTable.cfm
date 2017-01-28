<cfscript>
	param name="args.objectName"    type="string";
	param name="args.datasourceUrl" type="string"  default=event.buildAdminLink( linkTo="ajaxProxy", queryString="action=dataManager.getRecordHistoryForAjaxDataTables&object=#args.objectName#&id=#id#" );

	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName )
	gridFields           = [ /* TODO */ ];

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  objectName          = args.objectName
		, datasourceUrl       = args.datasourceUrl
		, useMultiActions     = false
		, allowSearch         = false
		, isMultilingual      = false
	} );

</cfscript>
<cfoutput>
	<div class="table-responsive">
		<table id="object-listing-table-#LCase( args.objectName )#" class="table table-hover object-listing-table">
			<thead>
				<tr>
					<th data-field="datemodified">#translateResource( uri="cms:version.table.date.header" )#</th>
					<th data-field="published">#translateResource( uri="cms:version.table.published.header" )#</th>
					<th data-field="_version_author">#translateResource( uri="cms:version.table.author.header" )#</th>
					<th data-field="_version_changed_fields">#translateResource( uri="cms:version.table.fields.header" )#</th>
					<th>&nbsp;</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr a:nth-of-type(1)">
			</tbody>
		</table>
	</div>
</cfoutput>
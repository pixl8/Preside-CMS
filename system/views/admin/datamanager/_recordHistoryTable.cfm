<cfscript>
	param name="args.objectName" type="string" default=( rc.object ?: '' );
	param name="args.recordId"   type="string" default=( rc.id ?: '' );
	param name="args.history"    type="query"  default=( prc.history ?: QueryNew('') );
	param name="args.gridFields" type="array"  default=[ "datemodified", "label" ];

	baseEditLink         = event.buildAdminLink( linkTo="datamanager.editRecord", querystring="object=#args.objectName#&id=#args.recordId#&version=" );
	loadVersionLinkTitle = translateResource( "cms:datamanager.recordhistory.loadversion.link" );
</cfscript>

<cfoutput>
	<div class="table-responsive">
		<table id="record-history-table-#LCase( args.objectName )#" class="table table-hover record-history-table">
			<thead>
				<tr>
					<cfloop array="#args.gridFields#" index="fieldName">
						<th data-field="#fieldName#">#translateResource( uri="preside-objects.#args.objectName#:field.#fieldName#.title", defaultValue=translateResource( "cms:preside-objects.default.field.#fieldName#.title" ) )#</th>
					</cfloop>
					<th>&nbsp;</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr a:nth-of-type(1)">
				<cfloop query="args.history">
					<tr class="clickable">
						<cfloop array="#args.gridFields#" index="fieldName">
							<td>
								#renderField( args.objectName, fieldName, args.history[ fieldName ], "adminDataTable" )#
							</td>
						</cfloop>
						<td>
							<a href="#baseEditLink##args.history._version_number#">
								<i class="fa fa-pencil" title="#loadVersionLinkTitle#"></i>
							</a>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>
<cfscript>
	healthchecks = args.healthchecks ?: {};
</cfscript>

<cfoutput>
	<cfif !healthchecks.count()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:systemInformation.no.healthchecks.configured" )#
		</p>
	<cfelse>
		<div class="table-responsive">
			<table class="table table-striped">
				<thead>
					<tr>
						<th>#translateResource( "cms:systemInformation.healthchecks.table.title.th"   )#</th>
						<th>#translateResource( "cms:systemInformation.healthchecks.table.up.th"      )#</th>
						<th>#translateResource( "cms:systemInformation.healthchecks.table.description.th" )#</th>
					</tr>
				</thead>
				<tbody>
					<cfloop collection="#healthchecks#" item="up" index="serviceId">
						<tr>
							<td>#translateResource( uri="healthcheckServices:#LCase( serviceId )#.title", defaultValue=serviceId )#</td>
							<td>#renderContent( "boolean", up, [ "adminDatatable", "admin" ] )#</td>
							<td>#translateResource( uri="healthcheckServices:#LCase( serviceId )#.description", defaultValue="" )#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>
<cfscript>
	logs = prc.logs ?: [];
</cfscript>

<cfoutput>
	<cfif logs.recordcount>
		<table class="table table-striped table-hover">
			<thead>
				<tr>
					<th>Date</th>
					<th>Details</th>
					<th>Action</th>
					<th>Type</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
				<cfloop query="logs">
					<tr class="clickable" data-context-container="1">
						<td>#datecreated#</td>
						<td>#detail#</td>
						<td>#action#</td>
						<td>#type#</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	<cfelse>
		<p><em>There are no audit logs to see here.</em></p>
	</cfif>
</cfoutput>
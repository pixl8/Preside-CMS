<cfscript>
	extensions = args.extensions ?: [];
</cfscript>

<cfoutput>
	<cfif !extensions.len()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:systemInformation.no.extensions.installed" )#
		</p>
	<cfelse>
		<div class="table-responsive">
			<table class="table table-striped">
				<thead>
					<tr>
						<th>#translateResource( "cms:systemInformation.extensions.table.title.th"   )#</th>
						<th>#translateResource( "cms:systemInformation.extensions.table.id.th"      )#</th>
						<th>#translateResource( "cms:systemInformation.extensions.table.version.th" )#</th>
						<th>#translateResource( "cms:systemInformation.extensions.table.author.th"  )#</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#extensions#" item="extension" index="i">
						<tr>
							<td>#extension.title#</td>
							<td>#extension.id#</td>
							<td>#extension.version#</td>
							<td>#extension.author#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>
<cfparam name="args.responses" type="array"/>

<cfif args.responses.len()>
	<cfoutput>
		<table class="table formbuilder-response table-striped">
			<cfloop array="#args.responses#" item="response" index="i">
				<tr>
					<th>#( response.item.configuration.label ?: response.item.configuration.name )#:</th>
					<td>
						<cfif Len( Trim( response.rendered ) )>
							#response.rendered#
						<cfelse>
							<em class="grey">#translateResource( "formbuilder:no.response.placeholder" )#</em>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
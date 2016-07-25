<cfparam name="args.responses" type="array"/>

<cfif args.responses.len()>
	<cfoutput>
		<cfloop array="#args.responses#" item="response" index="i">
			<tr>
				<th valign="top" style="width:35%;padding-right:5px;">#( response.item.configuration.label ?: response.item.configuration.name )#:</th>
				<td valign="top">
					<cfif Len( Trim( response.rendered ) )>
						#response.rendered#
					<cfelse>
						<em class="grey">#translateResource( "formbuilder:no.response.placeholder" )#</em>
					</cfif>
				</td>
			</tr>
		</cfloop>
	</cfoutput>
</cfif>
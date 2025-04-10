<!---@feature admin and formbuilder--->
<cfparam name="args.responses"  type="array"  default=[] />
<cfparam name="args.noResponse" type="string" default="#translateResource( "formbuilder:no.response.placeholder" )#" />

<cfoutput>
	<cfif ArrayLen( args.responses )>
		<table class="table formbuilder-response table-striped">
			<cfloop array="#args.responses#" item="response" index="i">
				<tr>
					<th>#( response.item.configuration.label ?: response.item.configuration.name )#:</th>
					<td>
						<cfif Len( Trim( response.rendered ) )>
							#response.rendered#
						<cfelse>
							<em class="grey">#args.noResponse#</em>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		<em class="grey">#args.noResponse#</em>
	</cfif>
</cfoutput>
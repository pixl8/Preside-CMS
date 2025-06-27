<!---@feature admin and formbuilder--->
<cfparam name="args.responses"  type="array"  default=[] />
<cfparam name="args.noResponse" type="string" default="#translateResource( "formbuilder:no.response.placeholder" )#" />

<cfif ArrayLen( args.responses )>
	<cfoutput>
		<cfloop array="#args.responses#" item="response" index="i">
			<cfset hasRendered=StructKeyExists( response, "rendered" ) />
			<cfset labelAttributes=( hasRendered ? 'style="width:35%;padding-right:5px;"' : 'style="padding-top:18px;padding-bottom:9px;" colspan="2"' ) />
			<tr>
				<th valign="top" #labelAttributes#>#( response.item.configuration.label ?: response.item.configuration.name )#<cfif hasRendered>:</cfif></th>
				<cfif hasRendered>
					<td valign="top">
						<cfif Len( Trim( response.rendered ) )>
							#response.rendered#
						<cfelse>
							<em class="grey">#args.noResponse#</em>
						</cfif>
					</td>
				</cfif>
			</tr>
		</cfloop>
	</cfoutput>
</cfif>
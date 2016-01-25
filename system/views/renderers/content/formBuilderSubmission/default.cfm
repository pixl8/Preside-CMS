<cfparam name="args.responses" type="array"/>

<cfif args.responses.len()>
	<cfoutput>
		<dl class="dl-horizontal formbuilder-response">
			<cfloop array="#args.responses#" item="response" index="i">
				<dt>#( response.item.configuration.label ?: response.item.configuration.name )#</dt>
				<dd>
					<cfif Len( Trim( response.rendered ) )>
						#response.rendered#
					<cfelse>
						<em class="grey">#translateResource( "formbuilder:no.response.placeholder" )#</em>
					</cfif>
				</dd>
			</cfloop>
		</dl>
	</cfoutput>
</cfif>
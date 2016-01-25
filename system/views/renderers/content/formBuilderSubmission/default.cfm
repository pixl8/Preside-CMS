<cfparam name="args.responses" type="array"/>

<cfif args.responses.len()>
	<cfoutput>
		<dl class="dl-unstyled formbuilder-response">
			<cfloop array="#args.responses#" item="response" index="i">
				<dt>#( response.item.configuration.label ?: response.item.configuration.name )#</dt>
				<dd>#response.rendered#</dd>
			</cfloop>
		</dl>
	</cfoutput>
</cfif>
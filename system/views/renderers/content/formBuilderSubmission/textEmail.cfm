<cfparam name="args.responses" type="array"/>

<cfif args.responses.len()>
	<cfoutput>
<cfloop array="#args.responses#" item="response" index="i">#( response.item.configuration.label ?: response.item.configuration.name )#:<cfif Len( Trim( response.rendered ) )>#response.rendered#<cfelse>#translateResource( "formbuilder:no.response.placeholder" )#</cfif>
</cfloop>
	</cfoutput>
</cfif>
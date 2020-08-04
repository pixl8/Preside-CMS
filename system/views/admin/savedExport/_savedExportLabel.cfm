<cfscript>
	icon        = args.icon        ?: "fa-database";
	label       = args.label       ?: "";
	description = args.description ?: "";
</cfscript>

<cfoutput>
	<div class="row no-padding">
		<strong>#label#</strong>

		<cfif !isEmptyString( description )>
			<p>#description#</p>
		</cfif>
	</div>
</cfoutput>
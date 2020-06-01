<cf_presideparam name="args.team" />
<cf_presideparam name="args.team_name" field="team.name" />

<cfscript>
	someVar = renderContent( renderer="someRenderer ", data=args );
</cfscript>

<cfoutput>
	<h1>#args.title#</h1>
	<p> #args.createdDate#</p>
</cfoutput>
<cfparam name="args.id"                  type="string" />
<cfparam name="args.type"                type="struct" />
<cfparam name="args.configuration.label" type="string" />

<cfoutput>
	#args.configuration.label# (#args.type.title#)
</cfoutput>
<cfparam name="args.id"                 type="string" />
<cfparam name="args.type"               type="struct" />
<cfparam name="args.configuration.name" type="string" />

<cfoutput>
	#args.type.title#: #args.configuration.name#
</cfoutput>
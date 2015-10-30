<cfparam name="args.url" 	default="" />
<cfparam name="args.width"  default="560" />
<cfparam name="args.height" default="315" />
<cfparam name="args.border" />

<cfif args.border EQ true >
	<cfset border = 1 />
<cfelse>
	<cfset border = 0 />
</cfif>

<cfoutput>
	<iframe width="#args.width#" height="#args.height#" src="#args.url#" frameborder="#border#"></iframe>
</cfoutput>
<cfparam name="args.title" default="" />
<cfparam name="args.embed_code" default="" />

<cfoutput>
	<cfif !isEmpty( args.title )>
		<h3>#args.title#</h3>
	</cfif>

	#args.embed_code#

	<br /> &nbsp;
</cfoutput>

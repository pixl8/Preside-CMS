<cfparam name="args.recordLink"  default="" />
<cfparam name="args.recordLabel" default="" />

<cfoutput>
	<cfif args.recordLink.len()>
		<a href="#args.recordLink#">#args.recordLabel#</a>
	<cfelse>
		#args.recordLabel#
	</cfif>
</cfoutput>
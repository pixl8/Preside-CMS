<cfparam name="args.recordLink"  default="" />
<cfparam name="args.renderedAsset" default="" />

<cfoutput>
	<cfif args.recordLink.len()>
		<a href="#args.recordLink#">#args.renderedAsset#</a>
	<cfelse>
		#args.renderedAsset#
	</cfif>
</cfoutput>
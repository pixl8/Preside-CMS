<cfparam name="args.recordLink"  default="" />
<cfparam name="args.recordLabel" default="" />

<cfoutput>
	<cfset recordLabel = isTrue( args.labelIsHtml ?: false ) ? args.recordLabel : EncodeForHtml( args.recordLabel ) />
	<cfif args.recordLink.len()>
		<a href="#EncodeForHtmlAttribute( args.recordLink )#">#recordLabel#</a>
	<cfelse>
		#recordLabel#
	</cfif>
</cfoutput>
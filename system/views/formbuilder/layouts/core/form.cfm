<cfparam name="args.renderedItems" type="string" />
<cfparam name="args.id"            type="string" />

<cfoutput>
	<form action="" id="#args.id#" method="post">
		<cfloop collection="#args#" item="argName">
			<cfif argName != "renderedItems" && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#
	</form>
</cfoutput>
<cfparam name="args.renderedItems" type="string" />

<cfoutput>
	<form action="">
		<cfloop collection="#args#" item="argName">
			<cfif argName != "renderedItems" && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#
	</form>
</cfoutput>
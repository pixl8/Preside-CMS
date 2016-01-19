<cfparam name="args.renderedItems" type="string" />
<cfparam name="args.id"            type="string" />
<cfparam name="args.validationJs"  type="string" default="" />

<cfoutput>
	<form action="" id="#args.id#" method="post">
		<cfloop collection="#args#" item="argName">
			<cfif argName != "renderedItems" && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#
	</form>

	<cfif Len( Trim( args.validationJs ) )>
		<cfsavecontent variable="validationJs">
			( function(){
				if ( typeof jQuery !== 'undefined' && typeof jQuery.validator !== 'undefined' ) {
					( function( $ ){
						$('###args.id#').validate( #args.validationJs# );
					} )( jQuery );
				}
			} )();
		</cfsavecontent>
		<cfset event.includeInlineJs( validationJs ) />
	</cfif>
</cfoutput>
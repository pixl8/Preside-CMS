<!---@feature formbuilder--->
<cfparam name="args.renderedItems"   type="string" />
<cfparam name="args.renderedButtons" type="string" />
<cfparam name="args.id"              type="string" />
<cfparam name="args.validationJs"    type="string" default="" />
<cfparam name="args.configuration"   type="struct" />

<cfoutput>
	<cfif Len( Trim( rc.errorMessage ?: "" ) ) >
		<div class="alert alert-danger">#rc.errorMessage#</div>
	</cfif>

	<form action="#event.buildLink( linkTo="formbuilder.core.submitAction" )#" id="#args.id#" method="post" enctype="multipart/form-data">
		<input type="hidden" name="csrfToken" value="#event.getCsrfToken()#">
		<cfloop collection="#args#" item="argName">
			<cfif not ArrayFindNoCase( [ "id", "validationJs", "renderedItems", "renderedButtons", "context", "layout", "formAction" ], argName ) && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#

		<cfif IsTrue( args.configuration.use_captcha ?: "" )>
			#renderView( '/formbuilder/general/captcha' )#
		</cfif>

		#args.renderedButtons#
	</form>

	<cfif Len( Trim( args.validationJs ) )>
		<cfsavecontent variable="formJs">
			if ( typeof executeWithFormBuilderDependencies !== 'undefined' ) {
				executeWithFormBuilderDependencies( function( $ ) {
					$( '###args.id#' ).validate( $.extend( #args.validationJs#, {
						highlight: function( element, errorClass ) {
							$( element ).closest( '.form-group' ).addClass( 'has-error' );
						},
						unhighlight: function( element, errorClass ) {
							$( element ).closest( '.form-group' ).removeClass( 'has-error' );
						}
					} ) );
				} );
			};
		</cfsavecontent>
		<cfset event.includeInlineJs( formJs ) />
	</cfif>
</cfoutput>
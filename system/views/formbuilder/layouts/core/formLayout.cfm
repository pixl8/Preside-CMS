<!---@feature formbuilder--->
<cfparam name="args.renderedItems"   type="string" />
<cfparam name="args.renderedButtons" type="string" />
<cfparam name="args.id"              type="string" />
<cfparam name="args.validationJs"    type="string" default="" />
<cfparam name="args.configuration"   type="struct" />
<cfparam name="args.formPageNumber"  type="numeric" default="0" />
<cfparam name="args.formPageCount"   type="numeric" default="0" />

<cfoutput>
	<cfif Len( Trim( rc.errorMessage ?: "" ) ) >
		<div class="alert alert-danger">#rc.errorMessage#</div>
	</cfif>

	<form action="#event.buildLink( linkTo="formbuilder.core.submitAction" )#" id="#args.id#" method="post" enctype="multipart/form-data">
		<input type="hidden" name="csrfToken" value="#event.getCsrfToken( force=true )#">
		<cfloop collection="#args#" item="argName">
			<cfif not ArrayFindNoCase( [ "id", "validationJs", "renderedItems", "renderedButtons", "renderedResponses", "context", "layout" ], argName ) && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		<cfif isTrue( args.configuration.use_progressbar ?: "" ) and args.formPageCount gt 0 and not isEmptyString( args.renderedItems )>
			#renderView( view="/formbuilder/general/progressbar", args=args )#
		</cfif>

		#args.renderedItems#

		<cfif isTrue( args.configuration.use_captcha ?: "" ) and ( args.formPageNumber eq 1 or args.formPageCount eq 0 )>
			#renderView( view="/formbuilder/general/captcha" )#
		</cfif>

		#args.renderedButtons#
	</form>

	<cfif Len( Trim( args.validationJs ) )>
		<cfsavecontent variable="formJs">
			if ( typeof executeWithFormBuilderDependencies !== 'undefined' ) {
				executeWithFormBuilderDependencies( function( $ ) {
					$( '###args.id#' ).validate( $.extend( #args.validationJs#, {
						highlight: function( element, errorClass ) {
							if ( $( this.submitButton ).attr( 'formnovalidate' ) == undefined ) {
								$( element ).closest( '.form-group' ).addClass( 'has-error' );
							}
						},
						unhighlight: function( element, errorClass ) {
							if ( $( this.submitButton ).attr( 'formnovalidate' ) == undefined ) {
								$( element ).closest( '.form-group' ).removeClass( 'has-error' );
							}
						}
					} ) );
				} );
			};
		</cfsavecontent>
		<cfset event.includeInlineJs( formJs ) />
	</cfif>
</cfoutput>
<cfparam name="args.renderedItems" type="string" />
<cfparam name="args.id"            type="string" />
<cfparam name="args.validationJs"  type="string" default="" />
<cfparam name="args.configuration" type="struct" />

<cfoutput>
	<form action="#event.buildLink( linkTo='formbuilder.core.submitAction' )#" id="#args.id#" method="post" enctype="multipart/form-data">
		<cfloop collection="#args#" item="argName">
			<cfif !( [ "id", "validationJs","renderedItems", "context", "layout" ].findNoCase( argName ) ) && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#

		<cfif IsTrue( args.configuration.use_captcha ?: "" )>
			#renderView( '/formbuilder/general/captcha' )#
		</cfif>

		<div class="form-group">
			<div class="col-md-offset-2">
				<div class="col-md-9">
					<button class="btn" tabindex="#getNextTabIndex()#">#( args.configuration.button_label ?: 'Submit' )#</button>
				</div>
			</div>
		</div>
	</form>

	<cfif Len( Trim( args.validationJs ) )>
		<cfsavecontent variable="formJs">
			if ( typeof executeWithFormBuilderDependencies !== 'undefined' ) {
				executeWithFormBuilderDependencies( function( $ ){
					$( '###args.id#' ).validate( #args.validationJs# );
				} );
			};
		</cfsavecontent>
		<cfset event.includeInlineJs( formJs ) />
	</cfif>
</cfoutput>
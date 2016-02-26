<cfparam name="args.renderedItems" type="string" />
<cfparam name="args.id"            type="string" />
<cfparam name="args.validationJs"  type="string" default="" />

<cfoutput>
	<form action="#event.buildLink( linkTo='formbuilder.core.submitAction' )#" id="#args.id#" method="post" enctype="multipart/form-data">
		<cfloop collection="#args#" item="argName">
			<cfif !( [ "id", "validationJs","renderedItems", "context", "layout" ].findNoCase( argName ) ) && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#
	</form>

	<cfsavecontent variable="formJs">
		( function(){
			if ( typeof jQuery !== 'undefined' ) {
				( function( $ ){
					var $form = $('###args.id#');
					$form.validate( #args.validationJs# );

					$form.presideFormBuilderForm();
				} )( jQuery );
			}
		} )();
	</cfsavecontent>
	<cfset event.includeInlineJs( formJs ) />
</cfoutput>
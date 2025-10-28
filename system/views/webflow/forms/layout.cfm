<!---@feature webflow--->
<cfscript>
	content               = args.content               ?: "";
	formName              = args.formName              ?: "";
	validationJs          = args.validationJs          ?: "";
	validationJsJqueryRef = args.validationJsJqueryRef ?: "presideJQuery";
	formId                = args.formId                ?: "";
</cfscript>

<cfoutput>
	<input type="hidden" name="$presideform" value="#formName#">

	#content#

	<cfif Len( Trim( formId ) ) and Len( Trim( validationJs ))>
		<cfsavecontent variable="validationJs">
			( function( $ ){
				var validator = $('###formId#').validate()
				  , options  = #validationJs#;

				if ( validator ) {
					validator.settings.rules    = $.extend( validator.settings.rules   , options.rules    );
					validator.settings.messages = $.extend( validator.settings.messages, options.messages );
				}
			} )( #validationJsJqueryRef# );
		</cfsavecontent>
		<cfset event.includeInlineJs( validationJs ) />
	</cfif>
</cfoutput>
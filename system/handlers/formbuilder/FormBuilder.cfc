component {

	property name="formBuilderValidationService" inject="formBuilderValidationService";
	property name="validationEngine"             inject="validationEngine";

	public any function submitAction( event, rc, prc ) {
		var formId = rc.form ?: "";

		if ( !Len( Trim( formId ) ) ) {
			event.notFound();
		}

		// TODO, better referer checking to ensure we're coming from the same
		// site, etc.
		if ( !Len( Trim( cgi.http_referer ) ) ) {
			event.notFound();
		}

		// TODO, actually process the submission

		// assuming we're all good...
		if ( event.isAjax() ) {
			event.renderData( data={ success=true, response="Wohoo! way to go you did it!" }, type="json" );
		} else {
			setNextEvent( url=cgi.http_referer, persistStruct={
				formBuilderFormSubmitted = formId
			} );
		}
	}

	private string function formLayout( event, rc, prc, args={} ) {
		if ( ( rc.formBuilderFormSubmitted ?: "" ) == ( args.form ?: "" ) ) {
			// TODO, render the editorial success message
			return "Wohoo! You did it (manually done here...)";
		}

		var validationRulesetName = formBuilderValidationService.getRulesetForFormItems( args.formItems ?: [] );
		if ( validationRulesetName.len() ) {
			args.validationJs = validationEngine.getJqueryValidateJs(
				  ruleset         = validationRulesetName
				, jqueryReference = "jQuery"
			);
		}

		event.include( assetId="/js/frontend/formbuilder/" );

		return renderView( view="/formbuilder/layouts/core/formLayout", args=args );
	}

}
component {

	property name="formBuilderService"           inject="formBuilderService";
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
			var successMessage = renderViewlet( event="formbuilder.formbuilder.successMessage", args={ formId=formId } );

			event.renderData( data={ success=true, response=successMessage }, type="json" );
		} else {
			setNextEvent( url=cgi.http_referer, persistStruct={
				formBuilderFormSubmitted = formId
			} );
		}
	}

	private string function formLayout( event, rc, prc, args={} ) {
		if ( ( rc.formBuilderFormSubmitted ?: "" ) == ( args.form ?: "" ) ) {
			return renderViewlet( event="formbuilder.formbuilder.successMessage", args={ formId=args.form } )
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

	private string function successMessage( event, rc, prc, args ) {
		args.successMessage = formBuilderService.getSubmissionSuccessMessage( args.formId ?: "" );
		args.successMessage = renderContent( renderer="richeditor", data=args.successMessage );

		return renderView( view="/formbuilder/layouts/core/successMessage", args=args );
	}

}
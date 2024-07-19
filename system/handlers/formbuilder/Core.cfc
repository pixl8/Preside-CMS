/**
 * @feature formBuilder
 */
component {

	property name="formBuilderService"           inject="formBuilderService";
	property name="formBuilderValidationService" inject="formBuilderValidationService";
	property name="validationEngine"             inject="validationEngine";
	property name="rulesEngineWebRequestService" inject="RulesEngineWebRequestService";
	property name="websiteLoginService"          inject="featureInjector:websiteUsers:websiteLoginService";

	public any function submitAction( event, rc, prc ) {
		var formId       = rc.form ?: "";
		var theForm      = formBuilderService.getForm( formId );
		var validRequest = theForm.recordCount == 1 && Len( Trim( cgi.http_referer ) ) && event.getHTTPMethod() == "POST";

		if ( !validRequest ) {
			event.notFound();
		}

		var submission  = event.getCollectionWithoutSystemVars();
		var persistData = submission;

		var checkAccess = formbuilderService.checkAccessAllowed( formId );
		if ( !checkAccess.allowed ) {
			if ( checkAccess.reason == "login" ) {
				formBuilderService.setTempStoredSubmission( formId, submission );
				if ( event.isAjax() ) {
					event.renderData( data={ success=false, response=checkAccess.message }, type="json" );
				} else {
					websiteLoginService.setPostLoginUrl( cgi.http_referer );
					setNextEvent( url=event.buildLink( page="login" ), persistStruct={ message="LOGIN_REQUIRED" } );
				}
			}
			if ( checkAccess.reason == "condition" ) {
				if ( event.isAjax() ) {
					event.renderData( data={ success=false, response=checkAccess.message }, type="json" );
				} else {
					event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
				}
			}
		}

		if ( !event.validateCsrfToken( rc.csrfToken ?: "" ) ) {
			persistData.errorMessage = translateResource( uri="cms:invalidCsrfToken.error" );
			setNextEvent( url=cgi.http_referer, persistStruct=persistData );
		}

		var validationResult = formBuilderService.saveFormSubmission(
			  formId      = formId
			, requestData = submission
			, instanceId  = ( rc.instanceId ?: "" )
		);

		if ( event.isAjax() ) {
			if ( validationResult.validated() ) {
				var successMessage = renderViewlet( event="formbuilder.core.successMessage", args={ formId=formId } );

				event.renderData( data={ success=true, response=successMessage }, type="json" );
			} else {
				var errors = {};
				var messages = validationResult.getMessages();
				for( var fieldName in messages ) {
					var message = messages[ fieldName ];
					errors[ fieldName ] = translateResource( uri=message.message, data=message.params );
				}
				event.renderData( data={ success=false, errors=errors }, type="json" );
			}
		} else {
			if ( validationResult.validated() ) {
				setNextEvent( url=cgi.http_referer, persistStruct={
					formBuilderFormSubmitted = formId
				} );
			} else {
				submission.validationResult = validationResult;
				setNextEvent( url=cgi.http_referer, persistStruct=submission );
			}
		}
	}

	private string function formLayout( event, rc, prc, args={} ) {
		if ( ( rc.formBuilderFormSubmitted ?: "" ) == ( args.form ?: "" ) ) {
			return renderViewlet( event="formbuilder.core.successMessage", args={ formId=args.form } )
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
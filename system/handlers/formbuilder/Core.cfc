/**
 * @feature formBuilder
 */
component {

	property name="formBuilderService"           inject="FormBuilderService";
	property name="formBuilderValidationService" inject="FormBuilderValidationService";
	property name="formBuilderRenderingService"  inject="FormBuilderRenderingService";
	property name="formBuilderItemTypesService"  inject="FormBuilderItemTypesService";
	property name="validationEngine"             inject="ValidationEngine";
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
				submission.checkAccess = true;
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

		var validationResult = validationEngine.newValidationResult();
		var persistStruct    = {}
		var formItemsInPage  = [];
		var formPageNext     = submission.formPageNext   ?: 1;
		var formPageNumber   = submission.formPageNumber ?: 0;
		var formPageCount    = submission.formPageCount  ?: 0;

		if ( formPageNumber > 0 ) {
			if ( formPageNext == 0 ) { // Reset
				formBuilderService.clearTempStoredSubmission( formId=formId );
				formPageNumber = 1;
			}

			var formPageIsLast     = formPageNumber >= formPageCount;
			var formUseSummaryPage = isTrue( theForm.use_summarypage ?: "" );
			var formPageIsBack     = formPageNext < 0;

			if ( formPageIsLast ) {
				if ( formPageIsBack || formUseSummaryPage ) {
					formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageIsBack ? formPageCount : formPageNumber );
				}
			} else {
				formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNumber );
			}
		}

		if ( ArrayLen( formItemsInPage ) ) {
			if ( formPageNext != 0 ) {
				var tempSubmission = formBuilderService.prepareTempSubmission( formId=formId, requestData=submission, formItems=formItemsInPage );

				validationResult = formBuilderService.saveTempSubmission(
					  formId       = formId
					, requestData  = tempSubmission
					, formItems    = formItemsInPage
					, pageNumber   = formPageNumber
					, pageNext     = formPageNext
				);
			}
		} else {
			var tempSubmission = formBuilderService.getTempStoredSubmission( formId=formId );

			StructAppend( submission, tempSubmission );

			validationResult = formBuilderService.saveFormSubmission(
				  formId       = formId
				, requestData  = submission
				, instanceId   = ( rc.instanceId   ?: "" )
				, instanceSite = ( rc.instanceSite ?: "" )
				, instanceUrl  = ( rc.instanceUrl  ?: "" )
				, instancePage = ( rc.instancePage ?: "" )
			);

			formBuilderService.clearTempStoredSubmission( formId=formId );

			persistStruct.formBuilderFormSubmitted = formId;
		}

		if ( event.isAjax() ) {
			if ( validationResult.validated() ) {
				var successMessage = renderViewlet( event="formbuilder.core.successMessage", args={ formId=formId } );

				event.renderData( data={ success=true, response=successMessage }, type="json" );
			} else {
				var errors = {};
				var messages = validationResult.getMessages();
				for ( var fieldName in messages ) {
					var message = messages[ fieldName ];
					errors[ fieldName ] = translateResource( uri=message.message, data=message.params );
				}
				event.renderData( data={ success=false, errors=errors }, type="json" );
			}
		} else {
			if ( !validationResult.validated() ) {
				persistStruct = submission;
				persistStruct.validationResult = validationResult;
			}

			setNextEvent( url=cgi.http_referer, persistStruct=persistStruct );
		}
	}

	private string function formLayout( event, rc, prc, args={} ) {
		var formId = args.form ?: "";

		if ( ( rc.formBuilderFormSubmitted ?: "" ) == formId ) {
			return renderViewlet( event="formbuilder.core.successMessage", args={ formId=formId } )
		}

		var validationRulesetName = formBuilderValidationService.getRulesetForFormItems( args.formItems ?: [] );
		if ( validationRulesetName.len() ) {
			args.validationJs = validationEngine.getJqueryValidateJs(
				  ruleset         = validationRulesetName
				, jqueryReference = "jQuery"
			);
		}

		args.renderedButtons = renderViewlet( event="formbuilder.core.formButtons", args=args );

		if ( isEmptyString( args.renderedItems ) ) {
			args.renderedItems = renderViewlet( event="formbuilder.core.formSummary", args=args );
		}

		event.include( assetId="/js/frontend/formbuilder/" );

		return renderView( view="/formbuilder/layouts/core/formLayout", args=args );
	}

	private string function formButtons( event, rc, prc, args={} ) {
		var formPageNumber     = args.formPageNumber ?: 0;
		var formPageCount      = args.formPageCount  ?: 0;
		var formUseSummaryPage = isTrue( args.configuration.use_summarypage ?: "" );

		args.isFormPage    = formPageNumber > 0;
		args.isFirstPage   = formPageNumber == 1;
		args.isLastPage    = formPageNumber == formPageCount && !formUseSummaryPage;
		args.isSummaryPage = formPageNumber > formPageCount  && formUseSummaryPage;

		return renderView( view="/formbuilder/layouts/core/formButtons", args=args );
	}

	private string function formSummary( event, rc, prc, args={} ) {
		return formBuilderService.renderSummary( formId=( args.form ?: "" ) );
	}

	private string function successMessage( event, rc, prc, args ) {
		args.successMessage = formBuilderService.getSubmissionSuccessMessage( args.formId ?: "" );
		args.successMessage = renderContent( renderer="richeditor", data=args.successMessage );

		return renderView( view="/formbuilder/layouts/core/successMessage", args=args );
	}

}
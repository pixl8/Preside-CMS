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
		var formUrl      = cgi.http_referer;
		var theForm      = formBuilderService.getForm( formId );
		var validRequest = theForm.recordCount == 1 && Len( Trim( formUrl ) ) && event.getHTTPMethod() == "POST";

		if ( !validRequest ) {
			event.notFound();
		}

		var submission  = event.getCollectionWithoutSystemVars();
		var persistData = submission;

		var storageKey = rc._sk ?: "";

		var checkAccess = formbuilderService.checkAccessAllowed( formId );
		if ( !checkAccess.allowed ) {
			if ( checkAccess.reason == "login" ) {
				submission.checkAccess = true;
				formBuilderService.setTempStoredSubmission( formId=formId, submission=submission, storageKey=storageKey );
				if ( event.isAjax() ) {
					event.renderData( data={ success=false, response=checkAccess.message }, type="json" );
				} else {
					websiteLoginService.setPostLoginUrl( formUrl );
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
			setNextEvent( url=formUrl, persistStruct=persistData );
		}

		var validationResult = validationEngine.newValidationResult();
		var persistStruct    = {}
		var formItemsInPage  = [];
		var formPageNext     = submission.formPageNext   ?: 1;
		var formPageNumber   = submission.formPageNumber ?: 0;
		var formPageCount    = submission.formPageCount  ?: 0;
		var tempSubmission   = {};

		if ( formPageNumber > 0 ) {
			if ( formPageNext == 0 ) { // Reset
				formBuilderService.clearTempStoredSubmission( formId=formId, storageKey=storageKey );
				formPageNumber = 1;
			}

			if ( formPageNumber >= formPageCount ) {
				formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNext < 0 ? formPageCount : formPageNumber );
			} else {
				formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNumber );
			}
		}

		// Handle save temp data.
		if ( ArrayLen( formItemsInPage ) ) {
			if ( formPageNext != 0 ) {
				tempSubmission = formBuilderService.prepareTempSubmission( formId=formId, requestData=submission, storageKey=storageKey, formItems=formItemsInPage );

				validationResult = formBuilderService.saveTempSubmission(
					  formId      = formId
					, requestData = tempSubmission
					, storageKey  = storageKey
					, formItems   = formItemsInPage
					, pageNumber  = formPageNumber
					, pageNext    = formPageNext
				);

				storageKey = tempSubmission.storageKey ?: "";

				tempSubmission = formBuilderService.getTempStoredSubmission( formId=formId, storageKey=storageKey );

				if ( ( tempSubmission.formPageNumber ?: 0 ) > formPageCount && !isTrue( theForm.use_summarypage ?: "" ) ) {
					formItemsInPage = []; // Trigger save submission.
				}
			}
		}

		// Handle save submission data.
		if ( !ArrayLen( formItemsInPage ) ) {
			tempSubmission = formBuilderService.getTempStoredSubmission( formId=formId, storageKey=storageKey );

			StructAppend( submission, tempSubmission );

			var submissionFormItems = [];

			if ( !isEmptyString( submission.instancePage ?: "" ) ) {
				var submissionPages = ListToArray( submission.instancePage );

				for ( var submissionPage in submissionPages ) {
					var formItemPage = formBuilderService.getPage( formId=formId, formItemId=submissionPage );
					ArrayAppend( submissionFormItems, formBuilderService.getFormItems( id=formId, pageNumber=formItemPage.page_number ), true );
				}
			}

			validationResult = formBuilderService.saveFormSubmission(
				  formId          = formId
				, requestData     = submission
				, instanceId      = ( submission.instanceId   ?: "" )
				, instanceSite    = ( submission.instanceSite ?: "" )
				, instanceUrl     = ( submission.instanceUrl  ?: "" )
				, instancePage    = ( submission.instancePage ?: "" )
				, validateCaptcha = formPageNumber <= 0
				, formItems       = submissionFormItems
			);

			formBuilderService.clearTempStoredSubmission( formId=formId, storageKey=storageKey );

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

			if ( !isEmptyString( persistStruct.formBuilderFormSubmitted ?: "" ) ) {
				StructAppend( persistStruct, submission );
			}

			formUrl = REReplaceNoCase( formUrl, "([?&])_sk=[^&]*", "\1_sk=#storageKey#" );

			if ( !REFindNoCase("([?&])_sk=", formUrl ) ) {
				formUrl = ListAppend( formUrl, "_sk=#storageKey#", Find( "?", formUrl ) ? "&" : "?" );
			}

			setNextEvent( url=formUrl, persistStruct=persistStruct );
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

		if ( isEmptyString( args.renderedItems ) && isTrue( args.configuration.use_summarypage ?: "" ) ) {
			args.renderedItems = renderViewlet( event="formbuilder.core.formSummary", args=args );
		}

		if ( !isEmptyString( args.renderedItems ) ) {
			args.renderedButtons = renderViewlet( event="formbuilder.core.formButtons", args=args );
		}

		if ( isEmptyString( args.renderedItems ?: "" ) && isEmptyString( args.renderedButtons ?: "" ) ) {
			return renderView( view="/formbuilder/layouts/core/emptyStateMessage", args=args );
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
		args.isLastPage    = formPageNumber == formPageCount && ( !formUseSummaryPage || !args.isFormPage );
		args.isSummaryPage = formPageNumber > formPageCount  && formUseSummaryPage;

		return renderView( view="/formbuilder/layouts/core/formButtons", args=args );
	}

	private string function formSummary( event, rc, prc, args={} ) {
		var summary = formBuilderService.renderSummary( formId=( args.form ?: "" ), storageKey=( args.storageKey ?: "" ) );

		if ( !isEmptyString( summary ) ) {
			return translateResource( uri="formbuilder:summary.description", defaultValue="" ) & summary;
		}

		return "";
	}

	private string function successMessage( event, rc, prc, args ) {
		args.successMessage = formBuilderService.getSubmissionSuccessMessage( args.formId ?: "" );
		args.successMessage = renderContent( renderer="richeditor", data=args.successMessage );

		return renderView( view="/formbuilder/layouts/core/successMessage", args=args );
	}

}
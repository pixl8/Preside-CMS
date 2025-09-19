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
		var formData     = {};
		var theForm      = formBuilderService.getForm( formId );
		var validRequest = theForm.recordCount == 1 && Len( Trim( formUrl ) ) && event.getHTTPMethod() == "POST";

		if ( !validRequest ) {
			event.notFound();
		}

		var submissionId = rc.submissionId ?: "";
		var submission   = event.getCollectionWithoutSystemVars();
		var persistData  = submission;

		var checkAccess = formbuilderService.checkAccessAllowed( formId );
		if ( !checkAccess.allowed ) {
			if ( checkAccess.reason == "login" ) {
				submission.checkAccess = true;
				formBuilderService.setTempStoredSubmission( formId, submission );
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

		if ( formPageNumber > 0 ) {
			if ( formPageNext == 0 ) {
				formBuilderService.clearSubmittedData( submissionId=submissionId ); // Trigger reset form.
				setNextEvent( url=formUrl );
			}

			if ( formPageNumber >= formPageCount ) {
				formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNext < 0 ? formPageCount : formPageNumber );
			} else {
				formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNumber );
			}

			formData = formBuilderService.getSubmittedData( submissionId=submissionId, filter="submitted_data != '' and submitted_data is not null" );

			if ( ArrayLen( formItemsInPage ) ) {
				var formNextPageNumber = formPageNumber + formPageNext;

				var payload = formBuilderService.getRequestDataForForm( formId=formId, requestData=submission, pageNumber=formPageNumber );

				// Clean up non simple value empty field to prevent override submitted data.
				for ( var key in payload ) {
					if ( !IsSimpleValue( payload[ key ] ) && IsEmpty( payload[ key ] ) ) {
						StructDelete( payload, key );
					}
				}

				StructAppend( formData, payload );

				formData.instancePage = formData.instancePage ?: "";
				var pageItem = formBuilderService.getPageByPageNumber( formId=formId, pageNumber=formPageNumber );
				if ( !isEmptyString( pageItem.id ?: "" ) ) {
					var index = ListFindNoCase( formData.instancePage, pageItem.id );
					if ( formPageNext < 0 && index > 0 ) {
						formData.instancePage = ListDeleteAt( formData.instancePage, index );
					} else if ( formPageNext >= 0 && index == 0 ) {
						formData.instancePage = ListAppend( formData.instancePage, pageItem.id );
					}
				}

				while ( !formBuilderService.evaluateConditionForPage( formId=formId, pageNumber=formNextPageNumber, payload=formData ) ) {
					formNextPageNumber += formPageNext;
				}

				formData.formPageNumber = formNextPageNumber;

				if ( formPageNumber >= formPageCount && !isTrue( theForm.use_summarypage ?: "" ) ) {
					formItemsInPage = [];
				}
			}
		}

		if ( !ArrayLen( formItemsInPage ) ) {
			StructAppend( submission, formData );
			formData = {};
			persistStruct.formBuilderFormSubmitted = formId; // Trigger success message.
		}

		if ( !isEmptyString( submission.instancePage ?: "" ) ) {
			formItemsInPage = [];

			// For validation, only form items that have been answered on the page
			for ( var submissionPage in ListToArray( submission.instancePage ) ) {
				var formItemPage = formBuilderService.getPage( formId=formId, formItemId=submissionPage );
				ArrayAppend( formItemsInPage, formBuilderService.getFormItems( id=formId, pageNumber=formItemPage.page_number ), true );
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
			, formItems       = formItemsInPage
			, data            = formData
			, submissionId    = submissionId
		);

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

			submissionId = formData.submissionId ?: "";

			formUrl = REReplaceNoCase( formUrl, "([?&])_fs=[^&]*", "\1_fs=#submissionId#" );

			if ( !REFindNoCase("([?&])_fs=", formUrl ) ) {
				formUrl = ListAppend( formUrl, "_fs=#submissionId#", Find( "?", formUrl ) ? "&" : "?" );
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
		args.isLastPage    = formPageNumber == formPageCount && !formUseSummaryPage;
		args.isSummaryPage = formPageNumber > formPageCount  && formUseSummaryPage;

		return renderView( view="/formbuilder/layouts/core/formButtons", args=args );
	}

	private string function formSummary( event, rc, prc, args={} ) {
		var formId       = args.form ?: "";
		var submissionId = args.submissionId ?: "";

		var summary = formBuilderService.renderSummary( formId=formId, submission=formBuilderService.getSubmittedData( submissionId=submissionId, filter="submitted_data != '' and submitted_data is not null" ) );

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
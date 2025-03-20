/**
 * @feature formBuilder
 */
component {

	property name="formBuilderService"           inject="FormBuilderService";
	property name="formBuilderValidationService" inject="FormBuilderValidationService";
	property name="formBuilderRenderingService"  inject="FormBuilderRenderingService";
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

		var tempSubmission   = formBuilderService.getTempStoredSubmission( formId=formId );
		var validationResult = validationEngine.newValidationResult();
		var persistStruct    = {}
		var formItemsInPage  = [];
		var formNextPage     = submission._formNextPage  ?: 1;
		var formPageNumber   = submission.formPageNumber ?: 0;

		if ( formPageNumber ) {
			if ( formNextPage == 0 ) {
				formBuilderService.clearTempStoredSubmission( formId=formId );
				formPageNumber = 1;
			}

			formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNumber );
		}

		if ( ArrayLen( formItemsInPage ) || ( formNextPage < 0 && submission.formPageNumber > submission.formPagesTotal ) ) {
			if ( formNextPage != 0 ) {
				validationResult = formBuilderValidationService.validateFormSubmission(
					  formItems      = formItemsInPage
					, submissionData = submission
				);

				if ( validationResult.validated() ) {
					formPageNumber += formNextPage;

					while ( !formBuilderService.evaluateConditionForPage( formId=formId, pageNumber=formPageNumber ) ) {
						formPageNumber += formNextPage;
					}

					submission.formPageNumber = formPageNumber;

					StructAppend( tempSubmission, submission );

					formBuilderService.setTempStoredSubmission( formId=formId, submission=tempSubmission );
				}
			}
		} else {
			StructAppend( submission, tempSubmission );

			validationResult = formBuilderService.saveFormSubmission(
				  formId       = formId
				, requestData  = submission
				, instanceId   = ( rc.instanceId   ?: "" )
				, instanceSite = ( rc.instanceSite ?: "" )
				, instanceUrl  = ( rc.instanceUrl  ?: "" )
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

		args.renderedResponses = "";
		if ( isEmptyString( args.renderedItems ) ) {
			var formItems      = formBuilderService.getFormItems( id=formId );
			var tempSubmission = formBuilderService.getTempStoredSubmission( formId );

			for ( var formItem in formItems ) {
				var formItemResponse = _getFormItemResponse( formItem=formItem, submission=tempSubmission );

				if ( StructKeyExists( tempSubmission, formItem.configuration.name ?: "" ) || formItem.item_type == "matrix" ) {
					formItem.configuration.renderedItem = renderViewlet(
						  event = formBuilderRenderingService.getItemTypeViewlet( itemType=formItem.item_type, context="response")
						, args  = {
							  response          = formItemResponse
							, itemConfiguration = formItem.configuration
						  }
					);

					if ( isEmptyString( formItem.configuration.renderedItem ) ) {
						formItem.configuration.renderedItem = translateResource( uri="formbuilder:no.response.placeholder" );
					}

					formItem.configuration.id = formItem.configuration.id ?: CreateUUID();

					if ( StructKeyExists( formItem.configuration, "layout" ) ) {
						formItem.configuration.renderedItem = renderViewlet(
							  event = formBuilderRenderingService.getFormFieldLayoutViewlet(
									  itemType = formItem.item_type
									, layout   = formItem.configuration.layout
							  )
							, args  = formItem.configuration
						);
					}

					args.renderedResponses &= formItem.configuration.renderedItem;
				}
			}
		}

		args.renderedButtons = renderViewlet( event="formbuilder.core.formButtons", args=args );

		event.include( assetId="/js/frontend/formbuilder/" );

		return renderView( view="/formbuilder/layouts/core/formLayout", args=args );
	}

	private string function formButtons( event, rc, prc, args={} ) {
		var formPageNumber = args.formPageNumber ?: 0;
		var formPagesTotal = args.formPagesTotal ?: 0;

		args.isFormPage  = formPageNumber > 0;
		args.isFirstPage = formPageNumber == 1;
		args.isLastPage  = formPageNumber > formPagesTotal;

		return renderView( view="/formbuilder/layouts/core/formButtons", args=args );
	}

	private string function successMessage( event, rc, prc, args ) {
		args.successMessage = formBuilderService.getSubmissionSuccessMessage( args.formId ?: "" );
		args.successMessage = renderContent( renderer="richeditor", data=args.successMessage );

		return renderView( view="/formbuilder/layouts/core/successMessage", args=args );
	}

	private string function _getFormItemResponse( required struct formItem,  struct submission={} ) {
		if ( arguments.formItem.item_type == "matrix" ) {
			return SerializeJson( arguments.submission );
		} else {
			return arguments.submission[ arguments.formItem.configuration.name ?: "" ] ?: "";
		}
	}

}
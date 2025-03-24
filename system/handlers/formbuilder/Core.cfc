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

		var validationResult  = validationEngine.newValidationResult();
		var persistStruct     = {}
		var formItemsInPage   = [];
		var formPageNext      = submission.formPageNext   ?: 1;
		var formPageNumber    = submission.formPageNumber ?: 0;
		var formPageCount     = submission.formPageCount  ?: 0;
		var formPageIsPreview = ( formPageNext < 0 && formPageNumber > formPageCount );

		if ( formPageNumber ) {
			if ( formPageNext == 0 ) { // Reset
				formBuilderService.clearTempStoredSubmission( formId=formId );
				formPageNumber = 1;
			}

			formItemsInPage = formBuilderService.getFormItems( id=formId, pageNumber=formPageNumber );
		}

		if ( ArrayLen( formItemsInPage ) || formPageIsPreview ) {
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

		args.renderedResponses = renderViewlet( event="formbuilder.core.formResponses", args=args );
		args.renderedButtons   = renderViewlet( event="formbuilder.core.formButtons", args=args );

		event.include( assetId="/js/frontend/formbuilder/" );

		return renderView( view="/formbuilder/layouts/core/formLayout", args=args );
	}

	private string function formButtons( event, rc, prc, args={} ) {
		var formPageNumber = args.formPageNumber ?: 0;
		var formPageCount  = args.formPageCount  ?: 0;

		args.isFormPage  = formPageNumber > 0;
		args.isFirstPage = formPageNumber == 1;
		args.isLastPage  = formPageNumber > formPageCount;

		return renderView( view="/formbuilder/layouts/core/formButtons", args=args );
	}

	private string function formResponses( event, rc, prc, args={} ) {
		var formId            = args.form ?: "";
		var renderedResponses = "";

		if ( isEmptyString( args.renderedItems ) ) {
			var formPageCount = formBuilderService.getPageCount( formId=formId );
			var tempSubmission = formBuilderService.getTempStoredSubmission( formId );

			for ( var pageNumber=1; pageNumber<=formPageCount; pageNumber++ ) {
				if ( formBuilderService.evaluateConditionForPage( formId=formId, pageNumber=pageNumber ) ) {
					var formItems = formBuilderService.getFormItems( id=formId, pageNumber=pageNumber );

					for ( var formItem in formItems ) {
						var formItemResponse = _getFormItemResponse( formItem=formItem, submission=tempSubmission );

						if ( formItem.type.isFormField ?: false ) {
							formItem.configuration.renderedItem = renderViewlet(
								  event = formBuilderRenderingService.getItemTypeViewlet( itemType=formItem.item_type, context="response" )
								, args  = {
									  response          = formItemResponse
									, itemConfiguration = formItem.configuration
									, buildLink         = false
								  }
							);

							if ( isEmptyString( formItem.configuration.renderedItem ) ) {
								formItem.configuration.renderedItem = translateResource( uri="formbuilder:response.empty.label" );
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

							renderedResponses &= formItem.configuration.renderedItem;
						}
					}
				}
			}
		}

		return renderedResponses;
	}

	private string function successMessage( event, rc, prc, args ) {
		args.successMessage = formBuilderService.getSubmissionSuccessMessage( args.formId ?: "" );
		args.successMessage = renderContent( renderer="richeditor", data=args.successMessage );

		return renderView( view="/formbuilder/layouts/core/successMessage", args=args );
	}

	private string function _getFormItemResponse( required struct formItem,  struct submission={} ) {
		var fieldName  = arguments.formItem.configuration.name ?: "";
		var fieldValue = arguments.submission[ fieldName ] ?: "";

		if ( IsSimpleValue( fieldValue ) ) {
			return fieldValue;
		} else {
			return fieldValue.fileName ?: "";
		}
	}

}
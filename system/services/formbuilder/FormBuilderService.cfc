/**
 * Provides logic for interacting with form builder forms
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component {

// CONSTRUCTOR
	/**
	 * @itemTypesService.inject             formbuilderItemTypesService
	 * @actionsService.inject               formbuilderActionsService
	 * @formBuilderRenderingService.inject  formBuilderRenderingService
	 * @formBuilderValidationService.inject formBuilderValidationService
	 * @formsService.inject                 formsService
	 * @validationEngine.inject             validationEngine
	 * @recaptchaService.inject             recaptchaService
	 * @spreadsheetLib.inject               spreadsheetLib
	 * @presideObjectService.inject         presideObjectService
	 * @rulesEngineFilterService.inject     rulesEngineFilterService
	 * @csvWriter.inject                    csvWriter
	 *
	 */
	public any function init(
		  required any itemTypesService
		, required any actionsService
		, required any formBuilderRenderingService
		, required any formBuilderValidationService
		, required any formsService
		, required any validationEngine
		, required any recaptchaService
		, required any spreadsheetLib
		, required any presideObjectService
		, required any rulesEngineFilterService
		, required any csvWriter
	) {
		_setItemTypesService( arguments.itemTypesService );
		_setActionsService( arguments.actionsService );
		_setFormBuilderRenderingService( arguments.formBuilderRenderingService );
		_setFormBuilderValidationService( arguments.formBuilderValidationService );
		_setFormsService( arguments.formsService );
		_setValidationEngine( arguments.validationEngine );
		_setRecaptchaService( arguments.recaptchaService );
		_setSpreadsheetLib( arguments.spreadsheetLib );
		_setPresideObjectService( arguments.presideObjectService );
		_setRulesEngineFilterService( arguments.rulesEngineFilterService );
		_setCsvWriter( arguments.csvWriter );

		return this;
	}

// PUBLIC API
	/**
	 * Returns the matching database record for the given form ID
	 *
	 * @autodoc
	 * @id.hint ID of the form you wish to get
	 *
	 */
	public query function getForm( required string id ) {
		return Len( Trim( arguments.id ) ) ? $getPresideObject( "formbuilder_form" ).selectData( id=arguments.id ) : QueryNew('');
	}

	/**
	 * Retuns a form's items in an ordered array
	 *
	 * @autodoc        true
	 * @id.hint        ID of the form whose sections and items you wish to get
	 * @itemTypes.hint Optional array of item types with which to filter the returned form items
	 */
	public array function getFormItems( required string id, array itemTypes=[] ) {
		var result = [];
		var items  = $getPresideObject( "formbuilder_formitem" ).selectData(
			  filter       = { form=arguments.id }
			, orderBy      = "sort_order"
			, selectFields = [
				  "id"
				, "item_type"
				, "configuration"
				, "form"
				, "question"
			  ]
		);

		for( var item in items ) {
			if ( !itemTypes.len() || itemTypes.findNoCase( item.item_type ) ) {
				var preparedItem = {
					  id            = item.id
					, formId        = item.form
					, questionId    = item.question
					, type          = _getItemTypesService().getItemTypeConfig( item.item_type )
					, configuration = DeSerializeJson( item.configuration )
				};

				if ( Len( item.question ) ) {
					StructAppend( preparedItem.configuration, _getItemConfigurationForV2Question( item.question ) );
				}

				ArrayAppend( result, preparedItem );
			}
		}

		return result;
	}

	/**
	 * Returns the matching database record for the given question ID
	 *
	 * @autodoc
	 * @id.hint ID of the question you wish to get
	 *
	 */
	public query function getQuestion( required string id ) {
		return Len( Trim( arguments.id ) ) ? $getPresideObject( "formbuilder_question" ).selectData( id=arguments.id ) : QueryNew('');
	}

	/**
	 * Retuns a form's item from the DB, converted to a useful struct. Keys are
	 * 'id', 'type' (a structure containing type configuration) and 'configuration'
	 * (a structure of configuration options for the item)
	 *
	 * @autodoc
	 * @id.hint ID of the item you wish to get
	 */
	public struct function getFormItem( required string id ) {
		var result = [];
		var items  = $getPresideObject( "formbuilder_formitem" ).selectData(
			  filter       = { id=arguments.id }
			, selectFields = [
				  "id"
				, "item_type"
				, "configuration"
				, "question"
				, "form"
			  ]
		);

		for( var item in items ) {
			return {
				  id            = item.id
				, type          = _getItemTypesService().getItemTypeConfig( item.item_type )
				, configuration = DeSerializeJson( item.configuration )
				, formId        = item.form
				, questionId    = item.question
			};
		}

		return {};
	}

	/**
	 * Returns the matching database record for the given question ID
	 *
	 * @autodoc
	 * @id.hint ID of the question you wish to get
	 *
	 */
	public query function getQuestion( required string id ) {
		return Len( Trim( arguments.id ) ) ? $getPresideObject( "formbuilder_question" ).selectData( id=arguments.id ) : QueryNew('');
	}


	/**
	 * Returns a form's item that matches the given input name.
	 *
	 * @autodoc
	 * @formId.hint    ID of the form whose item you wish to get
	 * @inputName.hint Name of the input
	 */
	public struct function getItemByInputName( required string formId, required string inputName ) {
		var items = getFormItems( arguments.formId );
		for( var item in items ) {
			if ( item.type.isFormField && ( item.configuration.name ?: "" ) == arguments.inputName ) {
				return item;
			}
		}
		return {};
	}

	/**
	 * Adds a new item to the form. Returns the ID of the
	 * newly generated item
	 *
	 * @autodoc
	 * @formId.hint        ID of the form to which to add the new item
	 * @itemtype.hint      ID of the item type, e.g. 'content' or 'textarea', etc.
	 * @configuration.hint Structure of configuration options for the item
	 */
	public string function addItem(
		  required string formId
		, required string itemType
		, required struct configuration
		,          string question = ""
	) {
		if ( isFormLocked( formId=arguments.formId ) ) {
			return "";
		}

		var formItemDao   = $getPresideObject( "formbuilder_formitem" );
		var existingItems = formItemDao.selectData( selectFields=[ "Max( sort_order ) as max_sort_order" ], filter={ form=arguments.formId } );

		return formItemDao.insertData( data={
			  form          = arguments.formId
			, item_type     = arguments.itemType
			, question      = arguments.question
			, sort_order    = Val( existingItems.max_sort_order ?: "" ) + 1
			, configuration = SerializeJson( arguments.configuration )
		} );
	}

	/**
	 * Updates the configuration of a given item in the form.
	 *
	 * @autodoc
	 * @id.hint            ID of the item to update
	 * @configuration.hint Configuration to save against the item
	 *
	 */
	public any function saveItem(
		  required string id
		, required struct configuration
		,          string question = ""
	) {
		if ( !arguments.id.len() || isFormLocked( itemId=arguments.id ) ) {
			return 0;
		}

		return $getPresideObject( "formbuilder_formitem" ).updateData( id=arguments.id, data={
			  configuration = SerializeJson( arguments.configuration )
			, question      = arguments.question
		} );
	}

	/**
	 * Validates the configuration for an item within a form. Returns
	 * a Preside validation result object.
	 *
	 * @autodoc
	 * @formId.hint   ID of the form to which the item belongs / will belong
	 * @itemType.hint Type of the form item, e.g. 'textinput', 'content', etc.
	 * @config.hint   Configuration struct to validate
	 * @itemId.hint   ID of the form item, should it already exist
	 *
	 */
	public any function validateItemConfig(
		  required string formId
		, required string itemType
		, required struct config
		,          string itemId = ""
	) {
		var itemTypeConfig   = _getItemTypesService().getItemTypeConfig( itemType );
		var validationResult = _getValidationEngine().newValidationResult();

		if ( itemTypeConfig.requiresConfiguration ) {
			validationResult = _getFormsService().validateForm(
				  formName         = itemTypeConfig.configFormName
				, formData         = config
				, validationResult = validationResult
			);

			if ( itemTypeConfig.isFormField && Len( Trim( arguments.config.name ?: "" ) ) ) {
				_validateFieldNameIsUniqueForFormItem( argumentCollection=arguments, validationResult=validationResult );
			}
		}

		return validationResult;
	}

	/**
	 * Deletes a configured item from a form. Returns true
	 * on success, false otherwise.
	 *
	 * @autodoc
	 * @id.hint The ID of the item you wish to delete
	 *
	 */
	public boolean function deleteItem( required string id ) {
		if ( Len( Trim( arguments.id ) ) && !isFormLocked( itemId=arguments.id ) ) {
			return $getPresideObject( "formbuilder_formitem" ).deleteData( id=arguments.id ) > 0;
		}

		return false;
	}

	/**
	 * Delete a form. Returns true
	 * on success, false otherwise.
	 *
	 * @autodoc
	 * @ids.hint ID of forms you wish to delete
	 *
	 */
	public boolean function deleteForms( required string ids ) {
		if ( Len( Trim( arguments.ids ) ) ) {
			var ids = listToArray( arguments.ids );
			$getPresideObject( "formbuilder_formitem" ).deleteData( filter={ form=ids } );
			$getPresideObject( "formbuilder_formsubmission" ).deleteData( filter={ form=ids } );
			$getPresideObject( "formbuilder_formaction" ).deleteData( filter={ form=ids } );
			return $getPresideObject( "formbuilder_form" ).deleteData( filter={ id=ids } ) > 0;
		}

		return false;
	}

	/**
	 * Returns boolean value true if form is exists
	 *
	 * @autodoc
	 * @id.hint ID of the form you wish to check
	 *
	 */
	public boolean function formExists( required string id ) {
		return Len( Trim( arguments.id ) ) ? $getPresideObject( "formbuilder_form" ).dataExists( id=arguments.id ) : false;
	}

	/**
	 * Sets the sort order of items within a form. Returns the number
	 * of items whose order has been set.
	 *
	 * @autodoc
	 * @items.hint Array of item ids in the order they should be set
	 *
	 */
	public numeric function setItemsSortOrder( required array items ) {
		var itemDao      = $getPresideObject( "formbuilder_formitem" );
		var updatedCount = 0;

		for( var i=1; i<=arguments.items.len(); i++ ){
			var id = arguments.items[ i ];

			if ( isFormLocked( itemId=id ) ) {
				return 0;
			}

			if ( IsSimpleValue( id ) && Len( Trim( id) ) ) {
				updatedCount += itemDao.updateData( id=id, data={ sort_order=i } );
			}
		}

		return updatedCount;
	}

	/**
	 * Activates the given form so that it can be embedded and used
	 * in editorial content.
	 *
	 * @autodoc
	 * @id.hint ID of the form you want to activate
	 */
	public numeric function activateForm( required string id ) {
		if ( !Len( Trim( arguments.id ) ) || isFormLocked( formId=arguments.id ) ) {
			return 0;
		}

		return $getPresideObject( "formbuilder_form" ).updateData(
			  id = arguments.id
			, data = { active = true }
		);
	}

	/**
	 * Deactivates the given form so that it can no longer be
	 * embedded and used in editorial content.
	 *
	 * @autodoc
	 * @id.hint ID of the form you want to deactivate
	 */
	public numeric function deactivateForm( required string id ) {
		if ( !Len( Trim( arguments.id ) ) || isFormLocked( formId=arguments.id ) ) {
			return 0;
		}

		return $getPresideObject( "formbuilder_form" ).updateData(
			  id = arguments.id
			, data = { active = false }
		);
	}

	/**
	 * Locks the given form so that it can no longer
	 * be edited.
	 *
	 * @autodoc
	 * @id.hint ID of the form you want to lock
	 */
	public numeric function lockForm( required string id ) {
		if ( !Len( Trim( arguments.id ) ) ) {
			return 0;
		}

		return $getPresideObject( "formbuilder_form" ).updateData(
			  id = arguments.id
			, data = { locked = true }
		);
	}

	/**
	 * Unlocks the given form so that it can once
	 * again be edited.
	 *
	 * @autodoc
	 * @id.hint ID of the form you want to unlock
	 */
	public numeric function unlockForm( required string id ) {
		if ( !Len( Trim( arguments.id ) ) ) {
			return 0;
		}

		return $getPresideObject( "formbuilder_form" ).updateData(
			  id = arguments.id
			, data = { locked = false }
		);
	}

	/**
	 * Returns whether or not the given form is locked
	 * for editing.
	 *
	 * @autodoc
	 * @formid.hint   ID of the form you want to check. Required if 'itemId' and 'actionid' not supplied.
	 * @itemId.hint   ID of the item that exists within the form you want to check. Required if 'id' and 'actionid' not supplied
	 * @actionId.hint ID of the action that exists within the form you want to check. Required if 'id' and 'itemid' not supplied
	 */
	public boolean function isFormLocked( string formid="", string itemId="", string actionId="" ) {
		if ( Len( Trim( arguments.itemId ) ) ) {
			var item = $getPresideObject( "formbuilder_formitem" ).selectData(
				  id           = arguments.itemId
				, selectFields = [ "form" ]
			);
			if ( !item.recordCount ) {
				return false;
			}

			arguments.formId = item.form;
		}

		if ( Len( Trim( arguments.actionId ) ) ) {
			var action = $getPresideObject( "formbuilder_formaction" ).selectData(
				  id           = arguments.itemId
				, selectFields = [ "form" ]
			);
			if ( !action.recordCount ) {
				return false;
			}

			arguments.formId = action.form;
		}

		if ( Len( Trim( arguments.formid ) ) ) {
			return $getPresideObject( "formbuilder_form" ).dataExists( filter={
				  id     = arguments.formId
				, locked = true
			} );
		}

		return false;
	}

	/**
	 * Returns whether or not the form is active. This will be a combination
	 * of the active flag and active from and to date range.
	 *
	 * @autodoc
	 * @formId.hint The ID of the form you wish to check
	 *
	 */
	public boolean function isFormActive( required string formId ) {
		var formRecord = getForm( id=arguments.formid );

		if ( !IsBoolean( formRecord.active ?: "" ) || !formRecord.active ) {
			return false;
		}

		if ( !IsNull( formRecord.active_from ) && IsDate( formRecord.active_from ) && formRecord.active_from > Now() ) {
			return false;
		}

		if ( !IsNull( formRecord.active_to ) && IsDate( formRecord.active_to ) && formRecord.active_to < Now() ) {
			return false;
		}

		return true;
	}

	/**
	 * Renders the given form within a passed layout
	 * and using any passed custom configuration data.
	 *
	 * @autodoc
	 * @formId.hint        The ID of the form to render
	 * @layout.hint        The form layout to use
	 * @configuration.hint Struct containing any custom configuration that may be used by the viewlets used to render the form
	 *
	 */
	public string function renderForm(
		  required string formId
		,          string layout           = "default"
		,          struct configuration    = {}
		,          any    validationResult = ""
	) {
		var formConfiguration = getForm( id=arguments.formId );
		var items             = getFormItems( id=arguments.formId );
		var renderedItems     = CreateObject( "java", "java.lang.StringBuffer" );
		var coreLayoutArgs    = Duplicate( arguments.configuration );
		var coreLayoutViewlet = "formbuilder.core.formLayout";
		var formLayoutArgs    = Duplicate( arguments.configuration );
		var formLayoutViewlet = _getFormBuilderRenderingService().getFormLayoutViewlet( layout=arguments.layout );
		var idPrefixForFields = _createIdPrefix();

		for( var item in items ) {
			var config    = Duplicate( item.configuration );
			var fieldName = config.name ?: CreateUUId();

			config.id = idPrefixForFields & fieldName;

			if ( !IsSimpleValue( validationResult ) && validationResult.fieldHasError( fieldName ) ) {
				config.error = $translateResource(
					  uri  = validationResult.getError( fieldName )
					, data = validationResult.listErrorParameterValues( fieldName )
				);
			}

			renderedItems.append( renderFormItem(
				  itemType      = item.type.id
				, configuration = config
			) );
		}

		coreLayoutArgs.renderedItems = renderedItems.toString();
		coreLayoutArgs.id            = idPrefixForFields;
		coreLayoutArgs.formItems     = items;
		for( var f in formConfiguration ) {
			coreLayoutArgs.configuration = f;
		}

		formLayoutArgs.renderedForm  = $renderViewlet(
			  event = coreLayoutViewlet
			, args  = coreLayoutArgs
		);


		return $renderViewlet(
			  event = formLayoutViewlet
			, args  = formLayoutArgs
		);
	}

	/**
	 * Renders the given form item with its configuration
	 * options.
	 *
	 * @autodoc
	 * @itemType.hint      The type of the item to render
	 * @configuration.hint The configuration struct of the item to render
	 */
	public string function renderFormItem( required string itemType, required struct configuration ) {
		var renderingService = _getFormBuilderRenderingService();
		var itemViewlet      = renderingService.getItemTypeViewlet( itemType=arguments.itemType, context="input" );
		var renderedItem     = $renderViewlet( event=itemViewlet, args=arguments.configuration );

		if ( StructKeyExists( arguments.configuration, "layout" ) ) {
			var layoutArgs    = Duplicate( arguments.configuration );
			var layoutViewlet = renderingService.getFormFieldLayoutViewlet(
				  itemType = arguments.itemType
				, layout   = arguments.configuration.layout
			);

			layoutArgs.renderedItem = renderedItem;
			renderedItem = $renderViewlet( event=layoutViewlet, args=layoutArgs );
		}

		return renderedItem;
	}

	/**
	 * Renders the response for a particular form response
	 *
	 * @autodoc
	 * @formid.hint     ID of the form that this response has been submitted against
	 * @inputName.hint  Name of the form item that contains the response
	 * @inputValue.hint Value of the response
	 */
	public string function renderResponse(
		  required string formId
		, required string inputName
		, required string inputValue
	) {
		var item = getItemByInputName(
			  formId    = arguments.formid
			, inputName = arguments.inputName
		);
		if ( !item.count() ) {
			return arguments.inputValue;
		}

		var viewlet = _getFormBuilderRenderingService().getItemTypeViewlet(
			  itemType = item.type.id
			, context  = "response"
		);

		return $renderViewlet( event=viewlet, args={
			  response          = arguments.inputValue
			, itemConfiguration = item.configuration
		} );
	}

	/**
	 * Gets responses to v2 forms in a format ready close to that
	 * of the original v1 raw responses format
	 *
	 * @autodoc      true
	 * @formId       The ID of the form
	 * @submissionId The ID of the submission that has responses
	 */
	public struct function getV2Responses( required string formId, required string submissionId ) {
		var itemTypes = getFormItems( arguments.formId );
		var responses = $getPresideObject( "formbuilder_question_response" ).selectData(
			  filter  = { submission=arguments.submissionId }
			, orderBy = "question,sort_order"
		);
		var responsesByQuestion = {};

		for( var response in responses ) {
			if ( Len( response.question_subreference ) ) {
				if ( !IsStruct( responsesByQuestion[ response.question ] ?: "" ) ) {
					responsesByQuestion[ response.question ] = {};
				}

				responsesByQuestion[ response.question ][ response.question_subreference ] = response.response;
			} else {
				if ( !IsSimpleValue( responsesByQuestion[ response.question ] ?: {} ) ) {
					responsesByQuestion[ response.question ] = "";
				}
				responsesByQuestion[ response.question ] = ListAppend( responsesByQuestion[ response.question ], response.response );
			}
		}

		responses = {};
		for( var item in itemTypes ) {
			if ( Len( item.questionId ) ) {
				if ( StructKeyExists( responsesByQuestion, item.questionId ) ) {
					responses[ item.questionId ] = responsesByQuestion[ item.questionId ];
				} else {
					responses[ item.questionId ] = "";
				}

				if ( !IsSimpleValue( responses[ item.questionId ] ) ) {
					responses[ item.questionId ] = SerializeJson( responses[ item.questionId ] );
				}
			}
		}

		return responses;
	}

	/**
	 * Gets responses to v2 forms in a format ready close to that
	 * of the original v1 raw responses format
	 *
	 * @autodoc      true
	 * @formId       The ID of the form
	 * @submissionId The ID of the submission that has responses
	 */
	public string function getV2QuestionResponses( required string formId, required string submissionId, required questionId ) {


		var responses = $getPresideObject( "formbuilder_question_response" ).selectData(
			  filter  = { submission=arguments.submissionId, question=arguments.questionId }

		);
		var responseForQuestion={};

		for( var response in responses ) {
			if ( Len( response.question_subreference ) ) {
				responseForQuestion[ response.question_subreference ] = response.response;
			} else {
				if ( !IsSimpleValue( responseForQuestion ?: {} ) ) {
					responseForQuestion = "";
				}
				responseForQuestion = ListAppend( responseForQuestion, response.response );
			}
		}

		return  SerializeJson( responseForQuestion );
	}

	public string function renderV2QuestionResponses( required string formId, required string submissionId, required questionId, required itemType ) {
		var question = $getPresideObject( "formbuilder_question" ).selectData(
			filter = { id=questionId }
		);
		var responseValue = getV2QuestionResponses( formId, submissionId, questionId );

		var viewlet = _getFormBuilderRenderingService().getItemTypeViewlet(
			  itemType = itemType
			, context  = "response"
		);
		var render = $renderViewlet( event=viewlet, args={
			  response          = responseValue
			, itemConfiguration = DeserializeJson( question.item_type_config )
		} );

		return render;
	}


	/**
	 * Returns the submission success message saved
	 * against the form for the given form ID
	 *
	 * @autodoc
	 * @formId.hint ID of the form whose message you wish to get
	 *
	 */
	public string function getSubmissionSuccessMessage( required string formId ) {
		if ( !Len( Trim( arguments.formId ) ) ) {
			return "";
		}

		var dbRecord = $getPresideObject( "formbuilder_form" ).selectData(
			  id         = arguments.formId
			, selectData = [ "form_submitted_message" ]
		);

		return dbRecord.form_submitted_message ?: "";
	}

	/**
	 * Given incoming request params, returns a structure
	 * containing only the params relevent for the given form
	 *
	 * @autodoc
	 * @formId.hint      The ID of the form
	 * @requestData.hint A struct containing request data parameters
	 *
	 */
	public struct function getRequestDataForForm( required string formId, required struct requestData ) {
		var formData  = {};
		var formItems = getFormItems( id=arguments.formId );

		for( var item in formItems ) {
			var itemName = item.configuration.name ?: "";
			if ( item.type.isFormField && Len( Trim( itemName ) ) ) {
				var itemValue = getItemDataFromRequest(
					  itemType          = item.type.id
					, inputName         = itemName
					, requestData       = arguments.requestData
					, itemConfiguration = item.configuration
				);

				if ( !IsNull( local.itemValue ) ) {
					formData[ itemName ] = itemValue;
				}
			}
		}

		return formData;
	}

	/**
	 * Attempts to retrieve the submitted response for a given item from
	 * the form request, processing any custom preprocessor logic that
	 * is defined for the item type in the process.
	 *
	 * @autodoc
	 * @itemType.hint          The type ID of the item
	 * @inputName.hint         The configured input name of the item
	 * @requestData.hint       The submitted data to the request
	 * @itemConfiguration.hint Configuration data associated with the item
	 *
	 */
	public any function getItemDataFromRequest(
		  required string itemType
		, required string inputName
		, required struct requestData
		, required struct itemConfiguration
	) {
		var processorHandler = "formbuilder.item-types.#arguments.itemType#.getItemDataFromRequest";
		var coldbox          = $getColdbox();

		if ( coldbox.handlerExists( processorHandler ) ) {
			return coldbox.runEvent(
				  event          = processorHandler
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args={ inputName=arguments.inputName, requestData=requestData, itemConfiguration=arguments.itemConfiguration } }
			);
		}

		return arguments.requestData[ arguments.inputName ] ?: NullValue();
	}

	/**
	 * Saves a form submission. Returns a validation result. If validation
	 * failed, no data will be saved in the database.
	 *
	 * @autodoc
	 * @formId.hint      The ID of the form builder form
	 * @requestData.hint A struct containing request data
	 * @instanceId.hint  Free text string representing the instance of a form builder form in the website (see form builder form widget)
	 * @ipAddress.hint   IP address of the visitor making the submission
	 * @userAgent.hint   User agent of the visitor making the submission
	 *
	 */
	public any function saveFormSubmission(
		  required string formId
		, required struct requestData
		,          string instanceId  = ""
		,          string ipAddress   = Trim( ListLast( cgi.remote_addr ?: "" ) )
		,          string userAgent   = ( cgi.http_user_agent ?: "" )
	) {
		setFormBuilderSubmissionContextData( arguments.formId, arguments.requestData );

		var submissionId      = "";
		var formConfiguration = getForm( arguments.formId );
		var formItems         = getFormItems( arguments.formId );
		var formData          = getRequestDataForForm( arguments.formId, arguments.requestData );
		var validationResult  = _getFormBuilderValidationService().validateFormSubmission(
			  formItems      = formItems
			, submissionData = formData
		);

		if ( IsBoolean( formConfiguration.use_captcha ?: "" ) && formConfiguration.use_captcha ) {
			if ( !_getRecaptchaService().validate( arguments.requestData[ "g-recaptcha-response" ] ?: "" ) ){
				validationResult.addError( fieldName="recaptcha", message="formbuilder:recaptcha.error.message" );
			}
		}

		$announceInterception( "preFormBuilderFormSubmission", {
			  formData          = formData
			, requestData       = arguments.requestData
			, validationResult  = validationResult
			, formId            = arguments.formId
			, formConfiguration = formConfiguration
			, formItems         = formItems
		} );

		if ( validationResult.validated() ) {
			if ( isV2Form( arguments.formid ) ) {
				submissionId = $getPresideObject( "formbuilder_formsubmission" ).insertData( data={
					  form           = arguments.formId
					, submitted_by   = $getWebsiteLoggedInUserId()
					, form_instance  = arguments.instanceId
					, ip_address     = arguments.ipAddress
					, user_agent     = arguments.userAgent
				} );
				saveV2Responses( formId=arguments.formId, formData=formData, formItems=formItems, submissionId=submissionId );
			} else {
				formData = renderResponsesForSaving( formId=arguments.formId, formData=formData, formItems=formItems );
				submissionId = $getPresideObject( "formbuilder_formsubmission" ).insertData( data={
					  form           = arguments.formId
					, submitted_by   = $getWebsiteLoggedInUserId()
					, submitted_data = SerializeJson( formData )
					, form_instance  = arguments.instanceId
					, ip_address     = arguments.ipAddress
					, user_agent     = arguments.userAgent
				} );

			}
			var submission = getSubmission( submissionId );
			for( var s in submission ) { submission = s; }

			_getActionsService().triggerSubmissionActions(
				  formId         = arguments.formId
				, submissionData = submission
			);

			$recordWebsiteUserAction(
				  type       = "formbuilder"
				, action     = "submitform"
				, identifier = arguments.formId
				, detail     = submission
			);

			$announceInterception( "postFormBuilderFormSubmission", {
				  formData          = formData
				, requestData       = arguments.requestData
				, formId            = arguments.formId
				, formConfiguration = formConfiguration
				, formItems         = formItems
				, submissionId      = submissionId
				, submission        = submission
			} );
		}

		return validationResult;
	}

	/**
	 * Returns the number of submissions made for
	 * a given form
	 *
	 * @autodoc
	 * @formid.hint The ID of the form whose submissions you want to count
	 *
	 */
	public numeric function getSubmissionCount( required string formId ) {
		var submissions = $getPresideObject( "formbuilder_formsubmission" ).selectData(
			  filter       = { form=formId }
			, selectFields = [ "Count( id ) as submission_count" ]
		);
		return Val( submissions.submission_count ?: "" );
	}

	/**
	 * Returns the submission record matching the given ID
	 *
	 * @autodoc
	 * @submissionId.hint The ID of the submission you wish to get
	 *
	 */
	public query function getSubmission( required string submissionId ) {
		return $getPresideObject( "formbuilder_formsubmission" ).selectData(
			filter = { id=submissionId }
		);
	}

	/**
	 * Returns form submissions in a result format that is ready
	 * for display in grid table
	 *
	 * @autodoc
	 * @formid.hint      ID of the form whose submissions you wish to get
	 * @startRow.hint    Start row of recordset (for pagination)
	 * @maxRows.hint     Max rows to fetch (for pagination)
	 * @orderBy.hint     Order by field
	 * @searchQuery.hint Search query with which to filter
	 *
	 */
	public struct function getSubmissionsForGridListing(
		  required string  formId
		,          numeric startRow              = 1
		,          numeric maxRows               = 10
		,          string  orderBy               = ""
		,          string  searchQuery           = ""
		,          string  savedFilterExpIdLists = ""
	) {
		var submissionsDao = $getPresideObject( "formbuilder_formsubmission" );
		var result         = { totalRecords=0, records="" };
		var extraFilters   = [];
		var sortBy         = ListFirst( arguments.orderBy, " " );
		var sortOrder      = ListLast( arguments.orderBy, " " );

		switch( sortBy ) {
			case "submitted_by":
				sortBy = "submitted_by.display_name";
				break;
			case "datecreated":
			case "instanceId":
			case "submitted_data":
				break;

			default:
				sortBy = "datecreated";
		}
		switch( sortorder ) {
			case "asc":
			case "desc":
				break;
			default:
				sortorder = "asc";
		}

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			extraFilters.append({
				  filter       = "submitted_by.display_name like :q or formbuilder_formsubmission.form_instance like :q or formbuilder_formsubmission.submitted_data like :q"
				, filterParams = { q = { type="cf_sql_varchar", value="%#arguments.searchQuery#%" } }
			});
		}
		if ( Len( Trim( sFilterExpression ?: "" ) ) ) {

			try {
				extraFilters.append( _getRulesEngineFilterService().prepareFilter(
					  objectName = "formbuilder_formsubmission"
					, expressionArray = DeSerializeJson( sFilterExpression ?: "" )
				) );
			} catch( any e ){}
		}

		if ( Len( Trim( arguments.savedFilterExpIdLists ?: "" ) ) ) {
			var savedFilters = _getPresideObjectService().selectData(
				  objectName   = "rules_engine_condition"
				, selectFields = [ "expressions" ]
				, filter       = { id=ListToArray( arguments.savedFilterExpIdLists ?: "" ) }
			);

			for( var filter in savedFilters ) {
				extraFilters.append( _getRulesEngineFilterService().prepareFilter(
					  objectName      = 'formbuilder_formsubmission'
					, expressionArray = DeSerializeJson( filter.expressions )
				) );
			}
		}

		result.records = submissionsDao.selectData(
			  filter       = { form = arguments.formId }
			, extraFilters = extraFilters
			, startRow     = arguments.startRow
			, maxRows      = arguments.maxRows
			, orderBy      = "#sortby# #sortorder#"
			, selectFields = [
				  "formbuilder_formsubmission.id"
				, "formbuilder_formsubmission.submitted_data"
				, "formbuilder_formsubmission.form_instance"
				, "formbuilder_formsubmission.datecreated"
				, "submitted_by.id as submitted_by"
			]
		);

		result.totalRecords = result.records.recordCount;

		return result;
	}

	/**
	 * Deletes the given submissions from the database
	 *
	 * @autodoc
	 * @submissionIds.hint an array of submission IDs to delete
	 *
	 */
	public numeric function deleteSubmissions( required array submissionIds ) {
		return $getPresideObject( "formbuilder_formsubmission" ).deleteData(
			filter = { id = arguments.submissionIds }
		);
	}

	/**
	 * Returns question responses in a result format that is ready
	 * for display in grid table
	 *
	 * @autodoc
	 * @formid.hint      ID of the question whose responses you wish to get
	 * @startRow.hint    Start row of recordset (for pagination)
	 * @maxRows.hint     Max rows to fetch (for pagination)
	 * @orderBy.hint     Order by field
	 * @searchQuery.hint Search query with which to filter
	 *
	 */
	public struct function getQuestionResponsesForGridListing(
		  required string  questionId
		,          numeric startRow              = 1
		,          numeric maxRows               = 10
		,          string  orderBy               = ""
		,          string  searchQuery           = ""
		,          string  sFilterExpression     = ""
		,          string  savedFilterExpIdLists = ""
	) {
		var questionResponsesDao = $getPresideObject( "formbuilder_question_response" );

		var result         = { totalRecords=0, records="" };
		var extraFilters   = [];
		var sortBy         = ListFirst( arguments.orderBy, " " );
		var sortOrder      = ListLast( arguments.orderBy, " " );

		switch( sortBy ) {
			case "submitted_by":
				sortBy = "submitted_by";
				break;
			case "datecreated":
			case "instanceId":
			case "submitted_data":
				break;

			default:
				sortBy = "datecreated";
		}
		switch( sortorder ) {
			case "asc":
			case "desc":
				break;
			default:
				sortorder = "asc";
		}

		if ( Len( Trim( sFilterExpression ?: "" ) ) ) {
			try {
				extraFilters.append( _getRulesEngineFilterService().prepareFilter(
					  objectName = "formbuilder_question_response"
					, expressionArray = DeSerializeJson( sFilterExpression ?: "" )
				) );
			} catch( any e ){


			}
		}

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			extraFilters.append({
				  filter       = "submitted_by like :q or formbuilder_question_response.response like :q"
				, filterParams = { q = { type="cf_sql_varchar", value="%#arguments.searchQuery#%" } }
			});
		}

		if ( Len( Trim( arguments.savedFilterExpIdLists ?: "" ) ) ) {
			var savedFilters = _getPresideObjectService().selectData(
				  objectName   = "rules_engine_condition"
				, selectFields = [ "expressions" ]
				, filter       = { id=ListToArray( arguments.savedFilterExpIdLists ?: "" ) }
			);

			for( var filter in savedFilters ) {
				extraFilters.append( _getRulesEngineFilterService().prepareFilter(
					  objectName      = 'formbuilder_formsubmission'
					, expressionArray = DeSerializeJson( filter.expressions )
				) );
			}
		}

		result.records = questionResponsesDao.selectData(
			  filter       = { question = arguments.questionId }
			, extraFilters = extraFilters
			, startRow     = arguments.startRow
			, maxRows      = arguments.maxRows
			, orderBy      = "#sortby# #sortorder#"
			, groupBy      = "submission, question"
			, selectFields = [
				  "formbuilder_question_response.id"
				, "formbuilder_question_response.submission"
				, "formbuilder_question_response.question"
				, "formbuilder_question_response.response"
				, "formbuilder_question_response.datecreated"
				, "formbuilder_question_response.submitted_by"
				, "formbuilder_question_response.website_user"
				, "formbuilder_question_response.is_website_user"
				, "formbuilder_question_response.admin_user"
				, "formbuilder_question_response.is_admin_user"
				, "formbuilder_question_response.submission_type"
				, "formbuilder_question_response.submission_reference"
				, "submission$form.name as form_name"
				, "question.item_type"
			]
		);

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			result.totalRecords = questionResponsesDao.selectData(
				  selectFields = [ "count( * ) as nRows" ]
				, filter       = { question = arguments.questionId }
			).nRows;
		}

		return result;
	}

	/**
	 * Exports the responses to the given form to an excel spreadsheet. Returns
	 * a workbook object (see [[spreadsheets]]).
	 *
	 * @autodoc     true
	 * @formid      ID of the form you wish to produce spreadsheet for
	 * @writeToFile Whether or not to write output to file. If true, output is written to file and the file path is returned. If false, workbook object is returned.
	 * @logger      Logger for background task export logging
	 * @progress    Progress reporter object for background task progress reporting
	 *
	 */
	public any function exportResponsesToExcel(
		  required string  formId
		,          boolean writeToFile = false
		,          any     logger
		,          any     progress
	) {
		var formDefinition = getForm( arguments.formId );
		var isV2           = isV2Form( arguments.formId );

		if ( !formDefinition.recordCount ) {
			if ( canReportProgress ) {
				throw( type="formbuilder.form.not.found", message="The form with the ID, [#arguments.formId#], could not be found" );
			}
			return;
		}

		var canLog            = StructKeyExists( arguments, "logger" );
		var canInfo           = canLog && logger.canInfo();
		var canReportProgress = StructKeyExists( arguments, "progress" );
		var renderingService  = _getFormBuilderRenderingService();
		var formItems         = getFormItems( arguments.formId );
		var spreadsheetLib    = _getSpreadsheetLib();
		var workbook          = spreadsheetLib.new();
		var headers           = [ "Submission ID", "Submission date", "Submitted by logged in user", "Form instance ID" ];
		var itemColumnMap     = {};
		var itemsToRender     = [];
		var submissions       = $getPresideObject( "formbuilder_formsubmission" ).selectData(
			  filter  = { form = arguments.formId }
			, orderBy = "datecreated"
		);

		if ( canInfo ) {
			logger.info( "Fetched [#NumberFormat( submissions.recordcount )#] submissions, preparing to export..." );
		}
		for( var i=1; i <= formItems.len(); i++ ) {
			if ( formItems[i].type.isFormField ) {
				var exclude = isBoolean( formItems[i].configuration.exclude_export ?: "" ) && formItems[i].configuration.exclude_export;
				var columns = !exclude ? renderingService.getItemTypeExportColumns( formItems[i].type.id, formItems[i].configuration ) : [];

				if ( columns.len() && !exclude ) {
					itemsToRender.append( formItems[i] );
					itemColumnMap[ formItems[ i ].id ] = columns;
					headers.append( columns, true );

				}
			}
		}

		headers.append( "IP Address" );
		headers.append( "User agent" );

		spreadsheetLib.renameSheet( workbook, $translateResource( uri="formbuilder:spreadsheet.main.sheet.title", data=[ formDefinition.name ] ), 1 );
		for( var i=1; i <= headers.len(); i++ ){
			spreadsheetLib.setCellValue( workbook, headers[i], 1, i, "string" );
		}

		var row = 1;
		for( var submission in submissions ) {
			var column      = 4;
			var submittedBy = Len( submission.submitted_by ) ? $renderLabel( "website_user", submission.submitted_by ) : "";
			row++;
			spreadsheetLib.setCellValue( workbook, submission.id, row, 1, "string" );
			spreadsheetLib.setCellValue( workbook, DateTimeFormat( submission.datecreated, "yyyy-mm-dd HH:nn:ss" ), row, 2, "string" );
			spreadsheetLib.setCellValue( workbook, submittedBy, row, 3, "string" );
			spreadsheetLib.setCellValue( workbook, submission.form_instance, row, 4, "string" );

			if ( itemsToRender.len() ) {
				var data = isV2 ? getV2Responses( arguments.formId, submission.id ) : DeSerializeJson( submission.submitted_data );
				for( item in itemsToRender ) {
					var itemKey = isV2 ? item.questionId : ( item.configuration.name ?: "" );
					var viewlet = _getFormBuilderRenderingService().getItemTypeViewlet(
						  itemType = item.type.id
						, context  = "responseForExport"
					);
					var itemColumns = $renderViewlet( event=viewlet, args={
						  response          = data[ itemKey ] ?: ""
						, itemConfiguration = item.configuration
					} );
					var mappedColumns = itemColumnMap[ item.id ];

					for( var i=1; i<=mappedColumns.len(); i++ ) {
						if ( itemColumns.len() >= i ) {
							spreadsheetLib.setCellValue( workbook, itemColumns[ i ], row, ++column, "string" );
						} else {
							spreadsheetLib.setCellValue( workbook, "", row, ++column );
						}
					}
				}
			}

			spreadsheetLib.setCellValue( workbook, submission.ip_address, row, ++column, "string" );
			spreadsheetLib.setCellValue( workbook, submission.user_agent, row, ++column, "string" );

			if ( !row mod 100 && ( canInfo || canReportProgress ) ) {
				if ( canReportProgress ) {
					if ( progress.isCancelled() ) {
						abort;
					}
					progress.setProgress( ( 100 / submissions.recordCount ) * row );
				}
				if ( canInfo ) {
					logger.info( "Processed [#NumberFormat( row )#] of [#NumberFormat( submissions.recordCount )#] records..." );
				}
			}
		}

		spreadsheetLib.formatRow( workbook, { bold=true }, 1 );
		spreadsheetLib.addFreezePane( workbook, 0, 1 );
		for( var i=1; i <= headers.len(); i++ ){
			spreadsheetLib.autoSizeColumn( workbook, i );
		}

		if ( canReportProgress ) {
			progress.setProgress( 100 );
		}

		if ( arguments.writeToFile ) {
			var tmpFile = getTempDirectory() & "/FormBuilderExport" & CreateUUId() & ".xls";
			spreadsheetLib.write( workbook, tmpFile, false );

			if ( canReportProgress ) {
				progress.setResult( {
					  filePath       = tmpFile
					, exportFileName = LCase( ReReplace( formDefinition.name, "[\W]", "_", "all" ) ) & "_" & DateTimeFormat( Now(), "yyyymmdd_HHnn" ) & ".xls"
					, mimetype       = "application/msexcel"
				} );
			}

			return tmpFile;
		}
		return workbook;
	}

	public any function exportQuestionResponses(
		  required string  questionId
		, required string  exportFields
		, required string  exporter
		,          string  filterExpressions
		,          string  savedFilters
		,          boolean writeToFile = false
		,          any     logger
		,          any     progress
	) {
		if ( exporter=="Excel" ) {
			return exportQuestionResponsesToExcel( argumentCollection = arguments );
		} else {
			return exportQuestionResponsesToCsv( argumentCollection = arguments );
		}

	}

	/**
	 * Exports the responses to the given question to an excel spreadsheet. Returns
	 * a workbook object (see [[spreadsheets]]).
	 *
	 * @autodoc     true
	 * @questionid      ID of the question you wish to produce spreadsheet for
	 * @writeToFile Whether or not to write output to file. If true, output is written to file and the file path is returned. If false, workbook object is returned.
	 * @logger      Logger for background task export logging
	 * @progress    Progress reporter object for background task progress reporting
	 *
	 */
	public any function exportQuestionResponsesToExcel(
		  required string  questionId
		, required string  exportFields
		,          string  filterExpressions
		,          string  savedFilters
		,          boolean writeToFile = false
		,          any     logger
		,          any     progress
	) {
		var questionDefinition = getQuestion( arguments.questionId );
		var exportFieldList = listToArray( arguments.exportFields );

		if ( !questionDefinition.recordCount ) {
			if ( canReportProgress ) {
				throw( type="formbuilder.question.not.found", message="The question with the ID, [#arguments.questionId#], could not be found" );
			}
			return;
		}

		var canLog            = StructKeyExists( arguments, "logger" );
		var canInfo           = canLog && logger.canInfo();
		var canReportProgress = StructKeyExists( arguments, "progress" );
		var renderingService  = _getFormBuilderRenderingService();
		var spreadsheetLib    = _getSpreadsheetLib();
		var workbook          = spreadsheetLib.new();
		var headers           = [];


		for ( var field in exportFields ) {
			headers.append( $translateResource( uri="preside-objects.formbuilder_question_response:field.#field#.title" ) );
		}

		var itemColumnMap     = {};
		var itemsToRender     = [];
		var item_type         = questionDefinition.item_type;
		var item_type_config  = questionDefinition.item_type_config ?: "{}"
		if ( !len(item_type_config) ) {
			item_type_config = "{}";
		}

		var responses = _getQuestionExportQuery( argumentCollection = arguments );


		if ( canInfo ) {
			logger.info( "Fetched [#NumberFormat( responses.recordcount )#] responses, preparing to export..." );
		}

		itemColumnMap = renderingService.getItemTypeExportColumns( questionDefinition.item_type, DeserializeJson( item_type_config ) );
		if ( len(itemColumnMap)==1 && itemColumnMap[1]=="" ) {
			itemColumnMap[1]="Response";
		}

		headers.append( itemColumnMap, true );

		spreadsheetLib.renameSheet( workbook, $translateResource( uri="formbuilder:spreadsheet.main.sheet.title", data=[ questionDefinition.field_label ] ), 1 );
		for( var i=1; i <= headers.len(); i++ ){
			spreadsheetLib.setCellValue( workbook, headers[i], 1, i, "string" );
		}

		var row = 1;
		for( var response in responses ) {
			var column      = 0;
			var submittedBy = Len( response.submitted_by ) ? $renderLabel( "website_user", response.submitted_by ) : "";
			row++;

			if ( ArrayContains( exportFieldList, "id" ) ) {
				spreadsheetLib.setCellValue( workbook, response.id, row, ++column, "string" );
			}
			if ( ArrayContains( exportFieldList, "submission_type" ) ) {
				spreadsheetLib.setCellValue( workbook, response.submission_type, row, ++column, "string" );
			}
			if ( ArrayContains( exportFieldList, "submission_reference" ) ) {
				spreadsheetLib.setCellValue( workbook, response.submission_reference, row, ++column, "string" );
			}
			if ( ArrayContains( exportFieldList, "submitted_by" ) ) {
				spreadsheetLib.setCellValue( workbook, response.submitted_by, row, ++column, "string" );
			}
			if ( ArrayContains( exportFieldList, "datecreated" ) ) {
				spreadsheetLib.setCellValue( workbook, DateTimeFormat( response.datecreated, "yyyy-mm-dd HH:nn:ss" ), row, ++column, "string" );
			}
			if ( ArrayContains( exportFieldList, "is_website_user" ) ) {
				spreadsheetLib.setCellValue( workbook, response.is_website_user, row, ++column, "string" );
			}
			if ( ArrayContains( exportFieldList, "parent_name" ) ) {
				spreadsheetLib.setCellValue( workbook, response.parent_name, row, ++column, "string" );
			}



			var responseValue = getV2QuestionResponses( response.submission_reference, response.submission, questionId );

			var viewlet = _getFormBuilderRenderingService().getItemTypeViewlet(
				  itemType = item_type
				, context  = "responseForExport"
			);


			var itemColumns = $renderViewlet( event=viewlet, args={
				  response          = responseValue
				, itemConfiguration = DeserializeJson( item_type_config )
			} );


			var mappedColumns = itemColumnMap;

					for( var i=1; i<=mappedColumns.len(); i++ ) {
						if ( itemColumns.len() >= i ) {
							spreadsheetLib.setCellValue( workbook, itemColumns[ i ], row, ++column, "string" );
						} else {
							spreadsheetLib.setCellValue( workbook, "", row, ++column );
						}
					}


			if ( !row mod 100 && ( canInfo || canReportProgress ) ) {
				if ( canReportProgress ) {
					if ( progress.isCancelled() ) {
						abort;
					}
					progress.setProgress( ( 100 / submissions.recordCount ) * row );
				}
				if ( canInfo ) {
					logger.info( "Processed [#NumberFormat( row )#] of [#NumberFormat( submissions.recordCount )#] records..." );
				}
			}
		}

		spreadsheetLib.formatRow( workbook, { bold=true }, 1 );
		spreadsheetLib.addFreezePane( workbook, 0, 1 );
		for( var i=1; i <= headers.len(); i++ ){
			spreadsheetLib.autoSizeColumn( workbook, i );
		}

		if ( canReportProgress ) {
			progress.setProgress( 100 );
		}

		if ( arguments.writeToFile ) {
			var tmpFile = getTempDirectory() & "/FormBuilderExport" & CreateUUId() & ".xls";
			spreadsheetLib.write( workbook, tmpFile, false );

			if ( canReportProgress ) {
				progress.setResult( {
					  filePath       = tmpFile
					, exportFileName = LCase( ReReplace( questionDefinition.field_label, "[\W]", "_", "all" ) ) & "_" & DateTimeFormat( Now(), "yyyymmdd_HHnn" ) & ".xls"
					, mimetype       = "application/msexcel"
				} );
			}

			return tmpFile;
		}
		return workbook;
	}

	/**
	 * Exports the responses to the given question to an excel spreadsheet. Returns
	 * a workbook object (see [[spreadsheets]]).
	 *
	 * @autodoc     true
	 * @questionid      ID of the question you wish to produce spreadsheet for
	 * @writeToFile Whether or not to write output to file. If true, output is written to file and the file path is returned. If false, workbook object is returned.
	 * @logger      Logger for background task export logging
	 * @progress    Progress reporter object for background task progress reporting
	 *
	 */
	public any function exportQuestionResponsesToCsv(
		  required string  questionId
		, required string  exportFields
		,          string  filterExpressions
		,          string  savedFilters
		,          boolean writeToFile = false
		,          any     logger
		,          any     progress
	) {
		var questionDefinition = getQuestion( arguments.questionId );
		var exportFieldList = listToArray( arguments.exportFields );

		if ( !questionDefinition.recordCount ) {
			if ( canReportProgress ) {
				throw( type="formbuilder.question.not.found", message="The question with the ID, [#arguments.questionId#], could not be found" );
			}
			return;
		}

		var extraFilters   = [];
		var canLog            = StructKeyExists( arguments, "logger" );
		var canInfo           = canLog && logger.canInfo();
		var canReportProgress = StructKeyExists( arguments, "progress" );
		var renderingService  = _getFormBuilderRenderingService();
		var headers           = [];

		var tmpFile = getTempDirectory() & "/FormBuilderExport" & CreateUUId() & ".xls";
		var writer   = _getCsvWriter().newWriter( tmpFile, "," );

		for ( var field in exportFields ) {
			headers.append( $translateResource( uri="preside-objects.formbuilder_question_response:field.#field#.title" ) );
		}

		var itemColumnMap     = {};
		var itemsToRender     = [];
		var item_type         = questionDefinition.item_type;
		var item_type_config  = questionDefinition.item_type_config ?: "{}"
		if ( !len(item_type_config) ) {
			item_type_config = "{}";
		}

		var responses = _getQuestionExportQuery( argumentCollection = arguments );

		if ( canInfo ) {
			logger.info( "Fetched [#NumberFormat( responses.recordcount )#] responses, preparing to export..." );
		}

		itemColumnMap = renderingService.getItemTypeExportColumns( questionDefinition.item_type, DeserializeJson( item_type_config ) );
		if ( len(itemColumnMap)==1 && itemColumnMap[1]=="" ) {
			itemColumnMap[1]="Response";
		}

		headers.append( itemColumnMap, true );


		try {
			var row = [];

			for( var i=1; i <= headers.len(); i++ ){
				row.append( headers[i] );
			}
			writer.writeNext( row );
			writer.flush();

			var rowNumber=1;
			for( var response in responses ) {
				row=[];
				var submittedBy = Len( response.submitted_by ) ? $renderLabel( "website_user", response.submitted_by ) : "";


				if ( ArrayContains( exportFieldList, "id" ) ) {
					row.append( response.id );
				}
				if ( ArrayContains( exportFieldList, "submission_type" ) ) {
					row.append( response.submission_type );
				}
				if ( ArrayContains( exportFieldList, "submission_reference" ) ) {
					row.append( response.submission_reference );
				}
				if ( ArrayContains( exportFieldList, "submitted_by" ) ) {
					row.append( response.submitted_by );
				}
				if ( ArrayContains( exportFieldList, "datecreated" ) ) {
					row.append( DateTimeFormat( response.datecreated, "yyyy-mm-dd HH:nn:ss" ) );
				}
				if ( ArrayContains( exportFieldList, "is_website_user" ) ) {
					row.append( response.is_website_user );
				}
				if ( ArrayContains( exportFieldList, "parent_name" ) ) {
					row.append( response.parent_name );
				}

				var responseValue = getV2QuestionResponses( response.submission_reference, response.submission, questionId );

				var viewlet = _getFormBuilderRenderingService().getItemTypeViewlet(
					  itemType = item_type
					, context  = "responseForExport"
				);


				var itemColumns = $renderViewlet( event=viewlet, args={
					  response          = responseValue
					, itemConfiguration = DeserializeJson( item_type_config )
				} );


				var mappedColumns = itemColumnMap;

				for( var i=1; i<=mappedColumns.len(); i++ ) {
					if ( itemColumns.len() >= i ) {
						row.append( itemColumns[ i ] );
					} else {
						row.append( "" );
					}
				}
				writer.writeNext( row );

				++rowNumber;
				if ( !rowNumber mod 100 && ( canInfo || canReportProgress ) ) {
					if ( canReportProgress ) {
						if ( progress.isCancelled() ) {
							abort;
						}
						progress.setProgress( ( 100 / submissions.recordCount ) * rowNumber );
					}
					if ( canInfo ) {
						logger.info( "Processed [#NumberFormat( rowNumber )#] of [#NumberFormat( submissions.recordCount )#] records..." );
					}
				}

				writer.flush();
			}
		} catch ( any e ) {
			rethrow;
		} finally {
			writer.close();
		}


		if ( canReportProgress ) {
			progress.setProgress( 100 );
		}


			if ( canReportProgress ) {
				progress.setResult( {
					  filePath       = tmpFile
					, exportFileName = LCase( ReReplace( questionDefinition.field_label, "[\W]", "_", "all" ) ) & "_" & DateTimeFormat( Now(), "yyyymmdd_HHnn" ) & ".csv"
					, mimetype       = "application/csv"
				} );
			}

			return tmpFile;

	}

	public struct function renderResponsesForSaving( required string formId, required struct formData, required array formItems ) {
		var rendererService = _getFormBuilderRenderingService();
		var coldbox         = $getColdbox();

		for( var i=1; i <= arguments.formItems.len(); i++ ) {
			var formItem = formItems[i];
			var itemName = formItem.configuration.name ?: "";

			if ( formItem.type.isFormField && StructKeyExists( arguments.formData, itemName ) ) {
				var rendererViewlet = rendererService.getItemTypeViewlet(
					  itemType = formItem.type.id
					, context  = "responseToPersist"
				);

				if ( coldbox.viewletExists( rendererViewlet ) ) {
					arguments.formData[ itemName ] = $renderViewlet( event=rendererViewlet, args={
						  response      = arguments.formData[ itemName ]
						, configuration = formItem.configuration
						, formId        = arguments.formId
					} );
				}
			}
		}

		return arguments.formData;
	}

	public void function saveV2Responses(
		  required string formId
		, required struct formData
		, required array  formItems
		, required string submissionId
	) {
		var rendererService = _getFormBuilderRenderingService();
		var coldbox         = $getColdbox();
		var responses       = "";

		for( var i=1; i <= arguments.formItems.len(); i++ ) {
			var formItem = formItems[i];
			var itemName = formItem.configuration.name ?: "";
			var dataType = "";

			if ( formItem.type.isFormField && StructKeyExists( arguments.formData, itemName ) ) {
				var dataTypeViewlet = "formbuilder.item-types.#formItem.type.id#.getQuestionDataType";
				var rendererViewlet = rendererService.getItemTypeViewlet(
					  itemType = formItem.type.id
					, context  = "v2ResponsesForDb"
				);

				if ( coldbox.viewletExists( rendererViewlet ) ) {
					responses = $renderViewlet( event=rendererViewlet, args={
						  response      = arguments.formData[ itemName ]
						, question      = formItem.questionId
						, configuration = formItem.configuration
						, formId        = arguments.formId
					} );
				} else {
					responses = arguments.formData[ itemName ];
				}

				if ( coldbox.viewletExists( dataTypeViewlet ) ) {
					dataType = $renderViewlet( event=dataTypeViewlet, args={
						  question      = formItem.questionId
						, configuration = formItem.configuration
					} );
					if ( !IsSimpleValue( local.dataType ?: {} ) ) {
						dataType = "";
					}
				}

				_saveV2Response(
					  response             = responses
					, questionId           = formItem.questionId
					, formId               = arguments.formId
					, submissionId         = arguments.submissionId
					, dataType             = dataType
				);
			}
		}
	}

	public struct function getFormBuilderSubmissionContextData() {
		return $getRequestContext().getValue( name="_formBuilderContext", private=true, defaultValue={} );
	}
	public void function setFormBuilderSubmissionContextData( required string formId, required struct data ) {
		$getRequestContext().setValue(
			  name    = "_formBuilderContext"
			, value   = { id=arguments.formId, data=arguments.data }
			, private = true
		);
	}

	/**
	 * Returns whether or not the given form is a "V2" form.
	 * V2 of the forms data model was introduced in Preside 10.13.0
	 * and uses a shared set of questions. When the v2 forms feature
	 * is enabled, all newly created forms will be a "V2" form while old
	 * forms will remain V1.
	 *
	 * @autodoc     true
	 * @formId.hint The ID of the form to check
	 */
	public boolean function isV2Form( required string formid ) {
		return $isFeatureEnabled( "formbuilder2" ) && $getPresideObject( "formbuilder_form" ).dataExists(
			  filter = { id=arguments.formId, uses_global_questions=true }
		);
	}

// PRIVATE HELPERS
	private void function _validateFieldNameIsUniqueForFormItem(
		  required string formId
		, required struct config
		, required string itemId
		, required any    validationResult
	) {
		var filter = "form = :form";
		var filterParams = { form=arguments.formid };

		if ( Len( Trim( arguments.itemId ) ) ) {
			filter &= " and id != :id";
			filterParams.id = arguments.itemId;
		}

		var existingItems = $getPresideObject( "formbuilder_formitem" ).selectData(
			  filter       = filter
			, filterParams = filterParams
			, selectFields = [ "configuration" ]
		);

		for( var item in existingItems ) {
			try {
				item = DeserializeJson( item.configuration );
			} catch ( any e ) {
				item = {};
			}
			if ( ( item.name ?: "" ) == arguments.config.name ) {
				validationResult.addError( fieldName="name", message="formbuilder:validation.non.unique.field.name" );
			}
		}
	}

	public string function cloneForm(
		  required string basedOnFormId
		, required string name
		, required string description
	) {
		var originalFormData = getForm( id=arguments.basedOnFormId );
		var cloneFormData    = { name=arguments.name, description=arguments.description };

		for( var column in originalFormData.columnList ) {
			if( !listFindNoCase( "id,name,description,datecreated,datemodified,_version_is_draft,_version_has_drafts", column ) ) {
				cloneFormData[ column ] = originalFormData[ column ];
			}
		}

		// for cloning form details
		var newFormId = $getPresideObject( "formbuilder_form" ).insertData( data=cloneFormData );

		// for cloning form items
		var originalFormItems = getFormItems( id=arguments.basedOnFormId );
		if( arrayLen( originalFormItems ) ) {
			for( var formItem in originalFormItems ) {
				addItem( formId=newFormId, itemType=formItem.type.id, configuration=formItem.configuration );
			}
		}

		// for cloning form actions
		var originalFormActions = _getActionsService().getFormActions( id=arguments.basedOnFormId );
		if( arrayLen( originalFormActions ) ) {
			for( var formAction in originalFormActions ) {
				_getActionsService().addAction( formId=newFormId, action=formAction.action.id, configuration=formAction.configuration );
			}
		}

		return newFormId;
	}

	private string function _createIdPrefix() {
		return "formbuilder_" & LCase( Hash( Now() ) );
	}

	private struct function _getItemConfigurationForV2Question( required string questionId ) {
		var question = $getPresideObject( "formbuilder_question" ).selectdata( id=arguments.questionId );

		for( var q in question ) {
			var config = {
				  label = ( len( q.full_question_text ) ? q.full_question_text : q.field_label )
				, name  = q.field_id
				, help  = q.help_text
			};
			try {
				if ( IsJson( q.item_type_config ) ) {
					StructAppend( config, DeserializeJson( q.item_type_config ) );
				}
			} catch( any e ) {
				$raiseError( e );
			}

			return config;
		}

		return {};
	}

	private void function _saveV2Response(
		  required any    response
		, required string questionId
		, required string formId
		, required string submissionId
		, required string dataType
		,          string sortOrder = ""
		,          string questionSubReference = ""
	) {
		if ( IsArray( arguments.response ) ) {
			for( var i=1; i<=ArrayLen( arguments.response ); i++ ) {
				_saveV2Response(
					  argumentCollection = arguments
					, response           = arguments.response[ i ]
					, sortOrder          = i
				);
			}
			return;
		}

		if ( IsStruct( arguments.response ) ) {
			for( var fieldName in arguments.response ) {
				_saveV2Response(
					  argumentCollection   = arguments
					, response             = arguments.response[ fieldName ]
					, questionSubReference = fieldName
				);
			}
			return;
		}

		if ( IsSimpleValue( arguments.response ) ) {
			var responseData = {
				  question              = arguments.questionId
				, submission_type       = "formbuilder"
				, submission_reference  = arguments.formid
				, question_subreference = arguments.questionSubReference
				, response              = arguments.response
				, sort_order            = arguments.sortOrder
				, submission            = arguments.submissionId
				, website_user          = $getWebsiteLoggedInUserId()
				, admin_user            = $getAdminLoggedInUserId()
				, submitted_by          = _getSubmitterNamePlainText()
			};

			switch( arguments.dataType ) {
				case "shorttext":
				case "date":
				case "bool":
				case "int":
				case "float":
					responseData[ "#arguments.dataType#_response" ] = arguments.response;
			}

			$announceInterception( "preSaveFormbuilderQuestionResponse", responseData );

			$getPresideObject( "formbuilder_question_response" ).insertData( responseData );
		}

	}

	private string function _getSubmitterNamePlainText() {
		var userId = $getWebsiteLoggedInUserId();
		if ( Len( Trim( userId ) ) ) {
			return $renderLabel( "website_user", userId );
		}

		userId = $getAdminLoggedInUserId();
		if ( Len( Trim( userId ) ) ) {
			return $renderLabel( "security_user", userId );
		}

		return "";
	}

	private any function _getQuestionExportQuery(
		  required string  questionId
		, required string  exportFields
		,          string  filterExpressions
		,          string  savedFilters
	) {
		var extraFilters = [];
		if ( Len( Trim( arguments.savedFilters ?: "" ) ) ) {
			var savedFilters = _getPresideObjectService().selectData(
				  objectName   = "rules_engine_condition"
				, selectFields = [ "expressions" ]
				, filter       = { id=ListToArray( arguments.savedFilters ?: "" ) }
			);

			for( var filter in savedFilters ) {
				extraFilters.append( _getRulesEngineFilterService().prepareFilter(
					  objectName      = 'formbuilder_formsubmission'
					, expressionArray = DeSerializeJson( filter.expressions )
				) );
			}
		}

		if ( Len( Trim( arguments.filterExpressions ?: "" ) ) ) {
			try {
				extraFilters.append( _getRulesEngineFilterService().prepareFilter(
					  objectName = "formbuilder_question_response"
					, expressionArray = DeSerializeJson( filterExpressions ?: "" )
				) );
			} catch( any e ){


			}
		}

		var questionResponsesDao = $getPresideObject( "formbuilder_question_response" );
		var responses = questionResponsesDao.selectData(
			  filter       = { question = arguments.questionId }
			, orderBy      = "datecreated"
			, groupBy      = "submission, question"
			, extraFilters = extraFilters
			, selectFields = [
				  "formbuilder_question_response.id"
				, "formbuilder_question_response.submission"
				, "formbuilder_question_response.question"
				, "formbuilder_question_response.response"
				, "formbuilder_question_response.datecreated"
				, "formbuilder_question_response.submitted_by"
				, "lformbuilder_question_response.is_website_user"
				, "formbuilder_question_response.is_admin_user"
				, "formbuilder_question_response.submission_type"
				, "formbuilder_question_response.submission_reference"
				, "formbuilder_question_response.parent_name"
			]
		);

		return responses;
	}

// GETTERS AND SETTERS
	private any function _getItemTypesService() {
		return _itemTypesService;
	}
	private void function _setItemTypesService( required any itemTypesService ) {
		_itemTypesService = arguments.itemTypesService;
	}

	private any function _getActionsService() {
		return _actionsService;
	}
	private void function _setActionsService( required any actionsService ) {
		_actionsService = arguments.actionsService;
	}

	private any function _getFormBuilderRenderingService() {
		return _formBuilderRenderingService;
	}
	private void function _setFormBuilderRenderingService( required any formBuilderRenderingService ) {
		_formBuilderRenderingService = arguments.formBuilderRenderingService;
	}

	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}

	private any function _getValidationEngine() {
		return _validationEngine;
	}
	private void function _setValidationEngine( required any validationEngine ) {
		_validationEngine = arguments.validationEngine;
	}

	private any function _getFormBuilderValidationService() {
		return _formBuilderValidationService;
	}
	private void function _setFormBuilderValidationService( required any formBuilderValidationService ) {
		_formBuilderValidationService = arguments.formBuilderValidationService;
	}

	private any function _getRecaptchaService() {
		return _recaptchaService;
	}
	private void function _setRecaptchaService( required any recaptchaService ) {
		_recaptchaService = arguments.recaptchaService;
	}

	private any function _getSpreadsheetLib() {
		return _spreadsheetLib;
	}
	private void function _setSpreadsheetLib( required any spreadsheetLib ) {
		_spreadsheetLib = arguments.spreadsheetLib;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getRulesEngineFilterService() {
		return _rulesEngineFilterService;
	}
	private void function _setRulesEngineFilterService( required any rulesEngineFilterService ) {
		_rulesEngineFilterService = arguments.rulesEngineFilterService;
	}
	private any function _getCsvWriter() {
		return _csvWriter;
	}
	private void function _setCsvWriter( required any csvWriter ) {
		_csvWriter = arguments.csvWriter;
	}
}
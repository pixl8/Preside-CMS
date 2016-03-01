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
	) {
		_setItemTypesService( arguments.itemTypesService );
		_setActionsService( arguments.actionsService );
		_setFormBuilderRenderingService( arguments.formBuilderRenderingService );
		_setFormBuilderValidationService( arguments.formBuilderValidationService );
		_setFormsService( arguments.formsService );
		_setValidationEngine( arguments.validationEngine );
		_setRecaptchaService( arguments.recaptchaService );
		_setSpreadsheetLib( arguments.spreadsheetLib );

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
	 * @autodoc
	 * @id.hint ID of the form who's sections and items you wish to get
	 */
	public array function getFormItems( required string id ) {
		var result = [];
		var items  = $getPresideObject( "formbuilder_formitem" ).selectData(
			  filter       = { form=arguments.id }
			, orderBy      = "sort_order"
			, selectFields = [
				  "id"
				, "item_type"
				, "configuration"
			  ]
		);

		for( var item in items ) {
			result.append( {
				  id            = item.id
				, type          = _getItemTypesService().getItemTypeConfig( item.item_type )
				, configuration = DeSerializeJson( item.configuration )
			} );
		}

		return result;
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
			  ]
		);

		for( var item in items ) {
			return {
				  id            = item.id
				, type          = _getItemTypesService().getItemTypeConfig( item.item_type )
				, configuration = DeSerializeJson( item.configuration )
			};
		}

		return {};
	}

	/**
	 * Retuns a form's item that matches the given input name.
	 *
	 * @autodoc
	 * @formId.hint    ID of the form who's item you wish to get
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
	) {
		if ( isFormLocked( formId=arguments.formId ) ) {
			return "";
		}

		var formItemDao   = $getPresideObject( "formbuilder_formitem" );
		var existingItems = formItemDao.selectData( selectFields=[ "Max( sort_order ) as max_sort_order" ], filter={ form=arguments.formId } );

		return formItemDao.insertData( data={
			  form          = arguments.formId
			, item_type     = arguments.itemType
			, configuration = SerializeJson( arguments.configuration )
			, sort_order    = Val( existingItems.max_sort_order ?: "" ) + 1
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
	public any function saveItem( required string id, required struct configuration ) {
		if ( !arguments.id.len() || isFormLocked( itemId=arguments.id ) ) {
			return 0;
		}

		return $getPresideObject( "formbuilder_formitem" ).updateData( id=arguments.id, data={
			configuration = SerializeJson( arguments.configuration )
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
	 * Sets the sort order of items within a form. Returns the number
	 * of items who's order has been set.
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

		if ( arguments.configuration.keyExists( "layout" ) ) {
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
	 * Returns the submission success message saved
	 * against the form for the given form ID
	 *
	 * @autodoc
	 * @formId.hint ID of the form who's message you wish to get
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

				if ( !IsNull( itemValue ) ) {
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
			formItems = renderResponsesForSaving( formId=arguments.formId, formData=formData, formItems=formItems );
			var submissionId = $getPresideObject( "formbuilder_formsubmission" ).insertData( data={
				  form           = arguments.formId
				, submitted_by   = $getWebsiteLoggedInUserId()
				, submitted_data = SerializeJson( formData )
				, form_instance  = arguments.instanceId
				, ip_address     = arguments.ipAddress
				, user_agent     = arguments.userAgent
			} );
			var submission = getSubmission( submissionId );
			for( var s in submission ) { submission = s; }

			_getActionsService().triggerSubmissionActions(
				  formId         = arguments.formId
				, submissionData = submission
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
	 * @formid.hint The ID of the form who's submissions you want to count
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
	 * @formid.hint      ID of the form who's submissions you wish to get
	 * @startRow.hint    Start row of recordset (for pagination)
	 * @maxRows.hint     Max rows to fetch (for pagination)
	 * @orderBy.hint     Order by field
	 * @searchQuery.hint Search query with which to filter
	 *
	 */
	public struct function getSubmissionsForGridListing(
		  required string  formId
		,          numeric startRow     = 1
		,          numeric maxRows      = 10
		,          string  orderBy      = ""
		,          string  searchQuery  = ""
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

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			result.totalRecords = submissionsDao.selectData(
				  selectFields = [ "count( * ) as nRows" ]
				, filter       = { form = arguments.formId }
			).nRows;
		}

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
	 * Exports the responses to the given form to an excel spreadsheet. Returns
	 * a workbook object (see [[spreadsheets]]).
	 *
	 * @autodoc
	 * @formid.hint ID of the form you wish to produce spreadsheet for
	 *
	 */
	public any function exportResponsesToExcel( required string formId ) {
		var formDefinition = getForm( arguments.formId );

		if ( !formDefinition.recordCount ) {
			return;
		}

		var renderingService = _getFormBuilderRenderingService();
		var formItems        = getFormItems( arguments.formId );
		var spreadsheetLib   = _getSpreadsheetLib();
		var workbook         = spreadsheetLib.new();
		var headers          = [ "Submission ID", "Submission date", "Submitted by logged in user", "Form instance ID" ];
		var itemColumnMap    = {};
		var itemsToRender    = [];
		var submissions      = $getPresideObject( "formbuilder_formsubmission" ).selectData(
			  filter  = { form = arguments.formId }
			, orderBy = "datecreated"
		);

		for( var i=1; i <= formItems.len(); i++ ) {
			if ( formItems[i].type.isFormField ) {
				var columns = renderingService.getItemTypeExportColumns( formItems[i].type.id, formItems[i].configuration );

				if ( columns.len() ) {
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
			spreadsheetLib.setCellValue( workbook, headers[i], 1, i );
		}

		var row = 1;
		for( var submission in submissions ) {
			var column = 4;
			row++;
			spreadsheetLib.setCellValue( workbook, submission.id, row, 1 );
			spreadsheetLib.setCellValue( workbook, DateTimeFormat( submission.datecreated, "yyyy-mm-dd HH:nn:ss" ), row, 2 );
			spreadsheetLib.setCellValue( workbook, submission.submitted_by, row, 3 );
			spreadsheetLib.setCellValue( workbook, submission.form_instance, row, 4 );

			if ( itemsToRender.len() ) {
				var data   = DeSerializeJson( submission.submitted_data );
				for( item in itemsToRender ) {
					var viewlet = _getFormBuilderRenderingService().getItemTypeViewlet(
						  itemType = item.type.id
						, context  = "responseForExport"
					);
					var itemColumns = $renderViewlet( event=viewlet, args={
						  response          = data[ item.configuration.name ?: "" ] ?: ""
						, itemConfiguration = item.configuration
					} );
					var mappedColumns = itemColumnMap[ item.id ];

					for( var i=1; i<=mappedColumns.len(); i++ ) {
						if ( itemColumns.len() >= i ) {
							spreadsheetLib.setCellValue( workbook, itemColumns[ i ], row, ++column );
						} else {
							spreadsheetLib.setCellValue( workbook, "", row, ++column );
						}
					}
				}
			}

			spreadsheetLib.setCellValue( workbook, submission.ip_address, row, ++column );
			spreadsheetLib.setCellValue( workbook, submission.user_agent, row, ++column );
		}

		spreadsheetLib.formatRow( workbook, { bold=true }, 1 );
		spreadsheetLib.addFreezePane( workbook, 0, 1 );
		for( var i=1; i <= headers.len(); i++ ){
			spreadsheetLib.autoSizeColumn( workbook, i );
		}

		return workbook;
	}

	public struct function renderResponsesForSaving( required string formId, required struct formData, required array formItems ) {
		var rendererService = _getFormBuilderRenderingService();
		var coldbox         = $getColdbox();

		for( var i=1; i <= arguments.formItems.len(); i++ ) {
			var formItem = formItems[i];
			var itemName = formItem.configuration.name ?: "";

			if ( formItem.type.isFormField && arguments.formData.keyExists( itemName ) ) {
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
				item = DeserializeJson( item.configuration )
			} catch ( any e ) {
				item = {};
			}
			if ( ( item.name ?: "" ) == arguments.config.name ) {
				validationResult.addError( fieldName="name", message="formbuilder:validation.non.unique.field.name" );
			}
		}
	}

	private string function _createIdPrefix() {
		return "formbuilder_" & LCase( Hash( Now() ) );
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
}
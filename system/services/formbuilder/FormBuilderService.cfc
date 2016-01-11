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
	 * @itemTypesService.inject formbuilderItemTypesService
	 * @formsService.inject     formsService
	 * @validationEngine.inject validationEngine
	 *
	 */
	public any function init( required any itemTypesService, required any formsService, required any validationEngine ) {
		_setItemTypesService( arguments.itemTypesService );
		_setFormsService( arguments.formsService );
		_setValidationEngine( arguments.validationEngine );

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
			, sortOrder    = "sort_order"
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
	 * Retuns a form's item from the DB converted to a useful struct. Keys are
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
			, sortOrder    = "sort_order"
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
		if ( !arguments.id.len() ) {
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
		if ( Len( Trim( arguments.id ) ) ) {
			return $getPresideObject( "formbuilder_formitem" ).deleteData( id=arguments.id ) > 0;
		}

		return false;
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

// GETTERS AND SETTERS
	private any function _getItemTypesService() {
		return _itemTypesService;
	}
	private void function _setItemTypesService( required any itemTypesService ) {
		_itemTypesService = arguments.itemTypesService;
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
}
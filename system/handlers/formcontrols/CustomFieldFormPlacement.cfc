/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function index( event, rc, prc, args={} ) {
		var savedData  = args.savedData ?: {};
		var objectName = Trim( savedData.target_object ?: "" );

		if ( !Len( objectName ) && Len( Trim( savedData.id ?: "" ) ) ) {
			var field = customFieldsService.getField( savedData.id );
			objectName = field.target_object ?: "";
		}

		args.objectName     = objectName;
		args.tabId          = Trim( savedData.form_tab ?: "" );
		args.tabLabel       = Trim( savedData.form_tab_label ?: "" );
		args.fieldsetId     = Trim( savedData.form_fieldset ?: "" );
		args.fieldsetLabel  = Trim( savedData.form_fieldset_label ?: "" );
		args.catalogue      = _catalogueWithCurrent(
			  catalogue      = Len( objectName ) ? customFieldsService.getFormPlacementCatalogue( objectName ) : []
			, tabId          = args.tabId
			, tabLabel       = args.tabLabel
			, fieldsetId     = args.fieldsetId
			, fieldsetLabel  = args.fieldsetLabel
		);

		return renderView( view="formcontrols/customFieldFormPlacement/index", args=args );
	}

	private array function _catalogueWithCurrent(
		  required array  catalogue
		, required string tabId
		, required string tabLabel
		, required string fieldsetId
		, required string fieldsetLabel
	) {
		var tabs = Duplicate( arguments.catalogue );

		if ( !Len( arguments.tabId ) || arguments.tabId == "__new__" ) {
			return tabs;
		}

		var tab = _findItem( tabs, arguments.tabId );
		if ( StructIsEmpty( tab ) ) {
			tab = {
				  id        = arguments.tabId
				, label     = Len( arguments.tabLabel ) ? arguments.tabLabel : arguments.tabId
				, created   = true
				, fieldsets = []
			};
			ArrayAppend( tabs, tab );
		}

		if ( Len( arguments.fieldsetId ) && arguments.fieldsetId != "__new__" && StructIsEmpty( _findItem( tab.fieldsets ?: [], arguments.fieldsetId ) ) ) {
			ArrayAppend( tab.fieldsets, {
				  id      = arguments.fieldsetId
				, label   = Len( arguments.fieldsetLabel ) ? arguments.fieldsetLabel : arguments.fieldsetId
				, created = true
			} );
		}

		return tabs;
	}

	private struct function _findItem( required array items, required string id ) {
		for( var item in arguments.items ) {
			if ( ( item.id ?: "" ) == arguments.id ) {
				return item;
			}
		}

		return {};
	}

}

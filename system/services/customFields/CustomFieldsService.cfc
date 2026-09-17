/**
 * CRUD and value persistence for admin-defined custom fields.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customFields
 */
component {

	property name="presideObjectService"          inject="delayedInjector:presideObjectService";
	property name="customFieldTypesService"       inject="delayedInjector:customFieldTypesService";
	property name="customFieldsPropertyInjector"  inject="delayedInjector:customFieldsPropertyInjector";
	property name="customFieldsValueTableService" inject="delayedInjector:customFieldsValueTableService";
	property name="formsService"                  inject="delayedInjector:formsService";
	property name="enumService"                   inject="delayedInjector:enumService";
	property name="rulesEngineFilterService"      inject="delayedInjector:rulesEngineFilterService";

	public any function init() {
		return this;
	}

	/**
	 * Whether the given preside object has opted in to custom fields.
	 *
	 * @autodoc true
	 */
	public boolean function isObjectEnabled( required string objectName ) {
		if ( !$isFeatureEnabled( "customFields" ) || !presideObjectService.objectExists( arguments.objectName ) ) {
			return false;
		}

		return $helpers.isTrue( presideObjectService.getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "customFieldsEnabled"
		) );
	}

	public array function listEnabledObjects() {
		var objects = [];

		if ( !$isFeatureEnabled( "customFields" ) ) {
			return objects;
		}

		for( var objectName in presideObjectService.listObjects() ) {
			if ( isObjectEnabled( objectName ) ) {
				ArrayAppend( objects, objectName );
			}
		}

		return objects;
	}

	public array function listEnabledObjectOptions() {
		var options = [];

		for( var objectName in listEnabledObjects() ) {
			ArrayAppend( options, {
				  id    = objectName
				, label = $translateResource( uri="preside-objects.#objectName#:title", defaultValue=objectName )
			} );
		}

		return options;
	}

	public struct function getObjectConfig( required string objectName ) {
		var customFieldsSettings = $getColdbox().getSetting( "customFields" );
		var configured           = IsStruct( customFieldsSettings ) ? ( customFieldsSettings.objects ?: {} ) : {};
		if ( !IsStruct( configured ) ) {
			configured = {};
		}

		var defaults = {
			  defaultSlot = "custom"
			, slots       = {
				custom = { viewGroup="customFields" }
			  }
		};

		if ( StructKeyExists( configured, arguments.objectName ) && IsStruct( configured[ arguments.objectName ] ) ) {
			defaults.append( configured[ arguments.objectName ], true );
			if ( StructKeyExists( configured[ arguments.objectName ], "slots" ) ) {
				defaults.slots.append( configured[ arguments.objectName ].slots, true );
			}
		}

		return defaults;
	}

	public string function getSlotViewGroup( required string objectName, string slot="custom" ) {
		var config = getObjectConfig( arguments.objectName );
		var slots  = config.slots ?: {};
		var slotId = Len( Trim( arguments.slot ) ) ? arguments.slot : ( config.defaultSlot ?: "custom" );

		if ( StructKeyExists( slots, slotId ) ) {
			return slots[ slotId ].viewGroup ?: "customFields";
		}

		return "customFields";
	}

	public array function listSlots( required string objectName ) {
		var config = getObjectConfig( arguments.objectName );
		var slots  = config.slots ?: {};
		var result = [];

		for( var slotId in slots ) {
			ArrayAppend( result, {
				  id        = slotId
				, viewGroup = slots[ slotId ].viewGroup ?: "customFields"
				, forms     = slots[ slotId ].forms     ?: {}
				, label     = slots[ slotId ].label     ?: slotId
			} );
		}

		return result;
	}

	public boolean function fieldHasInlineForm( required string objectName, required string slot ) {
		var config = getObjectConfig( arguments.objectName );
		var slots  = config.slots ?: {};
		var slotId = Len( Trim( arguments.slot ) ) ? arguments.slot : "custom";

		if ( !StructKeyExists( slots, slotId ) ) {
			return false;
		}

		var forms = slots[ slotId ].forms ?: {};
		return IsStruct( forms ) && StructCount( forms ) > 0;
	}

	public struct function getInlineFormPlacement( required string objectName, required string slot, required string formName ) {
		var config = getObjectConfig( arguments.objectName );
		var slots  = config.slots ?: {};
		var slotId = Len( Trim( arguments.slot ) ) ? arguments.slot : "custom";

		if ( StructKeyExists( slots, slotId ) ) {
			var forms = slots[ slotId ].forms ?: {};
			if ( StructKeyExists( forms, arguments.formName ) ) {
				return forms[ arguments.formName ];
			}
		}

		return {};
	}

	public array function listFields(
		  required string  objectName
		,          boolean includeInactive = false
		,          string  kind            = ""
	) {
		if ( !isObjectEnabled( arguments.objectName ) || !_storageReady() ) {
			return [];
		}

		var extraFilters = [];
		if ( !arguments.includeInactive ) {
			ArrayAppend( extraFilters, { filter={ active=true } } );
		}
		if ( Len( Trim( arguments.kind ) ) ) {
			ArrayAppend( extraFilters, { filter={ kind=arguments.kind } } );
		}

		var records = $getPresideObject( "custom_field" ).selectData(
			  filter       = { target_object=arguments.objectName }
			, extraFilters = extraFilters
			, orderBy      = "sort_order, label"
		);
		var fields = [];

		for( var record in records ) {
			ArrayAppend( fields, _recordToStruct( record ) );
		}

		return fields;
	}

	public array function listFieldsForRecord( required string objectName, required any record, string kind="" ) {
		return listFields( objectName=arguments.objectName, kind=arguments.kind );
	}

	public struct function getField( required string fieldId ) {
		var record = $getPresideObject( "custom_field" ).selectData( id=arguments.fieldId );
		if ( !record.recordCount ) {
			return {};
		}

		return _recordToStruct( record );
	}

	public string function getFieldListingLabel( required struct field ) {
		return arguments.field.label ?: ( arguments.field.key ?: "" );
	}

	public array function listLookupOptions( required string fieldId ) {
		var records = $getPresideObject( "custom_field_lookup" ).selectData(
			  filter  = { field=arguments.fieldId }
			, orderBy = "sort_order, label"
		);
		var options = [];

		for( var record in records ) {
			ArrayAppend( options, { id=record.value, label=record.label } );
		}

		return options;
	}

	public array function listConditionalRules( required string fieldId ) {
		if ( !$isFeatureEnabled( "rulesEngine" ) ) {
			return [];
		}

		var records = $getPresideObject( "custom_field_conditional_rule" ).selectData(
			  filter  = { field=arguments.fieldId }
			, orderBy = "sort_order"
		);
		var rules = [];

		for( var record in records ) {
			ArrayAppend( rules, record );
		}

		return rules;
	}

	public struct function extractCustomFieldValues( required string objectName, required struct data ) {
		var extracted = {};
		if ( !isObjectEnabled( arguments.objectName ) ) {
			return extracted;
		}

		var fields = listFields( objectName=arguments.objectName, kind="static" );
		for( var field in fields ) {
			if ( StructKeyExists( arguments.data, field.key ) ) {
				extracted[ field.key ] = arguments.data[ field.key ];
			}
		}

		return extracted;
	}

	public void function saveValues(
		  required string  objectName
		, required string  recordId
		, required struct  values
		,          any     record
		,          boolean replaceAll = false
	) {
		if ( !isObjectEnabled( arguments.objectName ) || !Len( Trim( arguments.recordId ) ) ) {
			return;
		}
		if ( !customFieldsValueTableService.valueObjectExists( arguments.objectName ) ) {
			return;
		}

		var fields = listFields( objectName=arguments.objectName, kind="static" );
		for( var field in fields ) {
			if ( !StructKeyExists( arguments.values, field.key ) ) {
				if ( arguments.replaceAll ) {
					_deleteValue(
						  field      = field
						, objectName = arguments.objectName
						, recordId   = arguments.recordId
					);
				}
				continue;
			}

			_upsertValue(
				  field      = field
				, objectName = arguments.objectName
				, recordId   = arguments.recordId
				, value      = arguments.values[ field.key ]
			);
		}
	}

	public struct function getValues( required string objectName, required string recordId ) {
		if ( !customFieldsValueTableService.valueObjectExists( arguments.objectName ) ) {
			return {};
		}

		var records = presideObjectService.selectData(
			  objectName   = customFieldsValueTableService.getValueObjectName( arguments.objectName )
			, filter       = { record=arguments.recordId }
			, selectFields = [ "field.key", "field_value" ]
		);
		var values = {};

		for( var record in records ) {
			values[ record.key ] = record.field_value;
		}

		return values;
	}

	public void function snapshotRecordValues( required string objectName, required string recordId ) {
		if ( !isObjectEnabled( arguments.objectName ) || !Len( Trim( arguments.recordId ) ) ) {
			return;
		}

		customFieldsValueTableService.snapshotValuesOntoLatestVersion(
			  objectName = arguments.objectName
			, recordId   = arguments.recordId
			, values     = getValues( arguments.objectName, arguments.recordId )
		);
	}

	public void function deleteValuesForRecord( required string objectName, required string recordId ) {
		if ( !customFieldsValueTableService.valueObjectExists( arguments.objectName ) ) {
			return;
		}

		presideObjectService.deleteData(
			  objectName = customFieldsValueTableService.getValueObjectName( arguments.objectName )
			, filter     = { record=arguments.recordId }
		);
	}

	public string function buildValueEditFormName( required string objectName, required any record ) {
		var fields       = listFieldsForRecord( objectName=arguments.objectName, record=arguments.record, kind="static" );
		var targetObject = arguments.objectName;

		return formsService.createForm( function( formDefinition ){
			formDefinition.setAttributes( i18nBaseUri="customFields:" );
			formDefinition.addTab( id="default" );
			formDefinition.addFieldset( id="default", tab="default" );

			for( var field in fields ) {
				if ( fieldHasInlineForm( targetObject, field.slot ?: "custom" ) ) {
					continue;
				}

				var type    = customFieldTypesService.getType( field.data_type ?: "text" );
				var control = type.control ?: "textinput";
				var args    = {
					  name      = field.key
					, fieldset  = "default"
					, tab       = "default"
					, control   = control
					, label     = field.label
					, help      = field.help_text ?: ""
					, required  = false
				};

				if ( ( field.data_type ?: "" ) == "lookup" ) {
					var options = listLookupOptions( field.id );
					var values  = [];
					var labels  = [];
					for( var option in options ) {
						ArrayAppend( values, option.id );
						ArrayAppend( labels, option.label );
					}
					args.control = "select";
					args.values  = values;
					args.labels  = labels;
				}

				if ( ( field.data_type ?: "" ) == "object_ref" && Len( Trim( field.related_object ?: "" ) ) ) {
					args.control = "objectPicker";
					args.object  = field.related_object;
				}

				formDefinition.addField( argumentCollection=args );
			}
		} );
	}

	public string function mergeInlineFieldsIntoForm(
		  required string formName
		, required string objectName
		,          any    record = {}
	) {
		var fields     = listFieldsForRecord( objectName=arguments.objectName, record=arguments.record, kind="static" );
		var toMerge    = [];

		for( var field in fields ) {
			var placement = getInlineFormPlacement( arguments.objectName, field.slot ?: "custom", arguments.formName );
			if ( StructIsEmpty( placement ) ) {
				continue;
			}
			ArrayAppend( toMerge, { field=field, placement=placement } );
		}

		if ( !ArrayLen( toMerge ) ) {
			return "";
		}

		return formsService.createForm( function( formDefinition ){
			for( var item in toMerge ) {
				var field     = item.field;
				var placement = item.placement;
				var type      = customFieldTypesService.getType( field.data_type ?: "text" );
				var args      = {
					  name     = field.key
					, tab      = placement.tab      ?: "default"
					, fieldset = placement.fieldset ?: "default"
					, control  = type.control ?: "textinput"
					, label    = field.label
					, help     = field.help_text ?: ""
				};

				if ( Len( Trim( placement.after ?: "" ) ) ) {
					args.after = placement.after;
				}

				if ( ( field.data_type ?: "" ) == "lookup" ) {
					var options = listLookupOptions( field.id );
					var values  = [ "" ];
					var labels  = [ "" ];
					for( var option in options ) {
						ArrayAppend( values, option.id );
						ArrayAppend( labels, option.label );
					}
					args.control = "select";
					args.values  = values;
					args.labels  = labels;
				}

				if ( ( field.data_type ?: "" ) == "object_ref" && Len( Trim( field.related_object ?: "" ) ) ) {
					args.control = "objectPicker";
					args.object  = field.related_object;
				}

				formDefinition.addField( argumentCollection=args );
			}
		} );
	}

	public array function listAggregateCandidateProperties( required string objectName ) {
		var properties = presideObjectService.getObjectProperties( arguments.objectName );
		var result     = [];

		for( var propName in properties ) {
			var rel = properties[ propName ].relationship ?: "";
			if ( ListFindNoCase( "many-to-many,one-to-many", rel ) ) {
				ArrayAppend( result, {
					  id         = propName
					, label      = $translatePropertyName( arguments.objectName, propName )
					, relatedTo  = properties[ propName ].relatedTo ?: ""
					, rel        = rel
				} );
			}
		}

		return result;
	}

	public array function listNumericRelatedProperties( required string relatedObject ) {
		if ( !Len( Trim( arguments.relatedObject ) ) || !presideObjectService.objectExists( arguments.relatedObject ) ) {
			return [];
		}

		var properties = presideObjectService.getObjectProperties( arguments.relatedObject );
		var result     = [];

		for( var propName in properties ) {
			var prop = properties[ propName ];
			if ( ( prop.type ?: "" ) == "numeric" && ( prop.relationship ?: "none" ) == "none" && !Len( Trim( prop.formula ?: "" ) ) ) {
				ArrayAppend( result, {
					  id    = propName
					, label = $translatePropertyName( arguments.relatedObject, propName )
				} );
			}
		}

		return result;
	}

	public string function evaluateConditionalLabel( required string encodedValue ) {
		var parts = ListToArray( arguments.encodedValue, "." );
		if ( ArrayLen( parts ) < 2 ) {
			return "";
		}

		var fieldId  = parts[ 1 ];
		var recordId = ArrayToList( ArraySlice( parts, 2 ), "." );
		var field    = getField( fieldId );
		if ( StructIsEmpty( field ) ) {
			return "";
		}

		var rules = listConditionalRules( fieldId );
		if ( !ArrayLen( rules ) ) {
			return "";
		}

		var objectName = field.target_object ?: "";
		for( var rule in rules ) {
			if ( !Len( Trim( rule.filter ?: "" ) ) ) {
				return rule.id;
			}
			if ( $isFeatureEnabled( "rulesEngine" ) && presideObjectService.dataExists(
				  objectName   = objectName
				, id           = recordId
				, extraFilters = [ rulesEngineFilterService.prepareFilter(
					  objectName = objectName
					, filterId   = rule.filter
				  ) ]
			) ) {
				return rule.id;
			}
		}

		return "";
	}

	public struct function getConditionalRuleById( required string ruleId ) {
		if ( !Len( Trim( arguments.ruleId ) ) ) {
			return {};
		}

		var record = $getPresideObject( "custom_field_conditional_rule" ).selectData( id=arguments.ruleId );
		if ( !record.recordCount ) {
			return {};
		}

		return _recordToStruct( record );
	}

	public string function getFieldKeyValidationError(
		  required string objectName
		, required string key
		,          string excludeId = ""
	) {
		var fieldKey = Trim( LCase( arguments.key ) );
		if ( !Len( fieldKey ) || !ReFind( "^[a-z][a-z0-9_]*$", fieldKey ) ) {
			return $translateResource( uri="customFields:validation.key.format", defaultValue="Key must start with a letter and use only lowercase letters, numbers and underscores." );
		}

		if ( Left( fieldKey, 1 ) == "_" || _isReservedKey( arguments.objectName, fieldKey ) ) {
			return $translateResource( uri="customFields:validation.key.reserved", data=[ fieldKey ], defaultValue="Key '#fieldKey#' is reserved." );
		}

		if ( presideObjectService.objectExists( arguments.objectName ) ) {
			var properties = presideObjectService.getObjectProperties( arguments.objectName );
			if ( StructKeyExists( properties, fieldKey ) && !$helpers.isTrue( properties[ fieldKey ].customField ?: "" ) ) {
				return $translateResource( uri="customFields:validation.key.collision", data=[ fieldKey ], defaultValue="Key '#fieldKey#' is already a property on this object." );
			}
		}

		var extraFilters = [];
		if ( Len( Trim( arguments.excludeId ) ) ) {
			ArrayAppend( extraFilters, { filter="id != :id", filterParams={ id=arguments.excludeId } } );
		}

		if ( $getPresideObject( "custom_field" ).dataExists(
			  filter       = { target_object=arguments.objectName, key=fieldKey }
			, extraFilters = extraFilters
		) ) {
			return $translateResource( uri="customFields:validation.key.duplicate", data=[ fieldKey ], defaultValue="A custom field with key '#fieldKey#' already exists on this object." );
		}

		return "";
	}

	private boolean function _isReservedKey( required string objectName, required string key ) {
		var reserved = [ "id", "label", "datecreated", "datemodified" ];

		if ( presideObjectService.objectExists( arguments.objectName ) ) {
			ArrayAppend( reserved, presideObjectService.getIdField( arguments.objectName ) );
			ArrayAppend( reserved, presideObjectService.getLabelField( arguments.objectName ) );
			ArrayAppend( reserved, presideObjectService.getDateCreatedField( arguments.objectName ) );
			ArrayAppend( reserved, presideObjectService.getDateModifiedField( arguments.objectName ) );
		}

		return ArrayFindNoCase( reserved, arguments.key ) > 0;
	}

	private void function _upsertValue(
		  required struct field
		, required string objectName
		, required string recordId
		, required any    value
	) {
		var valueObject = customFieldsValueTableService.getValueObjectName( arguments.objectName );
		var typed       = customFieldTypesService.mapValueToTypedColumns( arguments.field.data_type ?: "text", arguments.value );
		var filter      = {
			  record = arguments.recordId
			, field  = arguments.field.id
		};
		var existing = presideObjectService.selectData(
			  objectName   = valueObject
			, filter       = filter
			, selectFields = [ "id" ]
		);

		typed.record = arguments.recordId;
		typed.field  = arguments.field.id;

		if ( existing.recordCount ) {
			presideObjectService.updateData( objectName=valueObject, id=existing.id, data=typed );
		} else {
			presideObjectService.insertData( objectName=valueObject, data=typed );
		}
	}

	private void function _deleteValue(
		  required struct field
		, required string objectName
		, required string recordId
	) {
		presideObjectService.deleteData(
			  objectName = customFieldsValueTableService.getValueObjectName( arguments.objectName )
			, filter     = {
				  record = arguments.recordId
				, field  = arguments.field.id
			  }
		);
	}

	private struct function _recordToStruct( required any record ) {
		if ( IsStruct( arguments.record ) ) {
			return arguments.record;
		}

		if ( IsQuery( arguments.record ) ) {
			for( var row in arguments.record ) {
				return row;
			}
		}

		return {};
	}

	private boolean function _storageReady() {
		if ( $helpers.isTrue( variables._customFieldStorageReady ?: false ) ) {
			return true;
		}

		try {
			$getPresideObject( "custom_field" ).selectData( maxRows=0, selectFields=[ "id" ] );
			variables._customFieldStorageReady = true;
			return true;
		} catch ( any e ) {
			return false;
		}
	}

}

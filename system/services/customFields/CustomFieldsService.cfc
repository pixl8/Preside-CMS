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
	property name="formsService"                      inject="delayedInjector:formsService";
	property name="dataManagerCustomizationService"   inject="delayedInjector:dataManagerCustomizationService";
	property name="enumService"                       inject="delayedInjector:enumService";
	property name="rulesEngineFilterService"      inject="delayedInjector:rulesEngineFilterService";

	variables.CREATED_ITEM_SORTORDER       = 1000000000;
	variables.CUSTOM_FIELDS_TAB_SORTORDER  = 1000000010;

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

	/**
	 * The name an admin must type to confirm deletion of a field.
	 *
	 * @autodoc true
	 */
	public string function getDeletionConfirmationName( required struct field ) {
		var name = Trim( arguments.field.label ?: "" );

		if ( !Len( name ) ) {
			name = Trim( arguments.field.key ?: "" );
		}

		return name;
	}

	/**
	 * Whether the typed confirmation matches the field name.
	 *
	 * @autodoc true
	 */
	public boolean function deletionConfirmationMatches( required struct field, required string typedName ) {
		var expected = getDeletionConfirmationName( arguments.field );

		return Len( expected ) && Compare( Trim( arguments.typedName ), expected ) == 0;
	}

	/**
	 * How many records have a non-empty stored value for a static field.
	 * Other field kinds do not store their own values.
	 *
	 * @autodoc true
	 */
	public numeric function countStoredValues( required struct field ) {
		if ( ( arguments.field.kind ?: "" ) != "static" ) {
			return 0;
		}

		var objectName = Trim( arguments.field.target_object ?: "" );
		if ( !Len( objectName ) || !customFieldsValueTableService.valueObjectExists( objectName ) ) {
			return 0;
		}

		return presideObjectService.selectData(
			  objectName      = customFieldsValueTableService.getValueObjectName( objectName )
			, filter          = { field=arguments.field.id ?: "" }
			, extraFilters    = [ { filter="field_value is not null and field_value <> ''" } ]
			, selectFields    = [ "1 as record" ]
			, recordCountOnly = true
		);
	}

	/**
	 * Removes stored values, lookup options and conditional rules for a field.
	 * The value table has no database cascade, so this runs before the field row is deleted.
	 *
	 * @autodoc true
	 */
	public void function deleteFieldData( required struct field ) {
		var fieldId = arguments.field.id ?: "";
		if ( !Len( Trim( fieldId ) ) ) {
			return;
		}

		var objectName = Trim( arguments.field.target_object ?: "" );
		if ( ( arguments.field.kind ?: "" ) == "static" && Len( objectName ) && customFieldsValueTableService.valueObjectExists( objectName ) ) {
			presideObjectService.deleteData(
				  objectName = customFieldsValueTableService.getValueObjectName( objectName )
				, filter     = { field=fieldId }
			);
		}

		if ( presideObjectService.objectExists( "custom_field_lookup" ) ) {
			presideObjectService.deleteData( objectName="custom_field_lookup", filter={ field=fieldId } );
		}
		if ( presideObjectService.objectExists( "custom_field_conditional_rule" ) ) {
			presideObjectService.deleteData( objectName="custom_field_conditional_rule", filter={ field=fieldId } );
		}
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
		var fields = listFieldsForRecord( objectName=arguments.objectName, record=arguments.record, kind="static" );

		return formsService.createForm( function( formDefinition ){
			formDefinition.setAttributes( i18nBaseUri="customFields:" );
			formDefinition.addTab( id="default" );
			formDefinition.addFieldset( id="default", tab="default" );

			for( var field in fields ) {
				var args = _staticValueFieldArgs( field );
				args.tab      = "default";
				args.fieldset = "default";
				formDefinition.addField( argumentCollection=args );
			}
		} );
	}

	/**
	 * Tabs and fieldsets an admin can place a custom field on.
	 * Built from the object's add and edit forms, plus tabs created by other custom fields.
	 *
	 * @autodoc true
	 */
	public array function getFormPlacementCatalogue( required string objectName ) {
		if ( !isObjectEnabled( arguments.objectName ) ) {
			return [];
		}

		var forms = [];

		for( var action in [ "getAddRecordFormName", "getEditRecordFormName" ] ) {
			var formName = _recordFormNameFromCustomization( arguments.objectName, action );
			if ( !Len( formName ) ) {
				continue;
			}

			try {
				ArrayAppend( forms, formsService.getForm( formName ) );
			} catch ( any e ) {}
		}

		return buildFormPlacementCatalogueFromSources(
			  sourceForms = forms
			, fields      = listFields( objectName=arguments.objectName, includeInactive=true )
		);
	}

	/**
	 * Merges add or edit form tabs with tabs and fieldsets declared by custom fields.
	 *
	 * @autodoc true
	 */
	public array function buildFormPlacementCatalogueFromSources( required array sourceForms, required array fields ) {
		var tabs       = [];
		var placements = Duplicate( arguments.fields );

		for( var sourceForm in arguments.sourceForms ) {
			for( var sourceTab in ( sourceForm.tabs ?: [] ) ) {
				if ( !Len( Trim( sourceTab.id ?: "" ) ) || ( IsBoolean( sourceTab.deleted ?: "" ) && sourceTab.deleted ) ) {
					continue;
				}

				var existing = _findCatalogueItem( tabs, sourceTab.id );
				if ( StructIsEmpty( existing ) ) {
					existing = {
						  id        = sourceTab.id
						, label     = _formItemLabel( sourceTab )
						, created   = false
						, fieldsets = []
					};
					ArrayAppend( tabs, existing );
				}

				for( var fieldset in ( sourceTab.fieldsets ?: [] ) ) {
					if ( !Len( Trim( fieldset.id ?: "" ) ) || ( IsBoolean( fieldset.deleted ?: "" ) && fieldset.deleted ) ) {
						continue;
					}
					if ( StructIsEmpty( _findCatalogueItem( existing.fieldsets, fieldset.id ) ) ) {
						ArrayAppend( existing.fieldsets, {
							  id      = fieldset.id
							, label   = _formItemLabel( fieldset )
							, created = false
						} );
					}
				}
			}
		}

		placements.sort( function( left, right ){
			var order = Val( left.sort_order ?: 0 ) - Val( right.sort_order ?: 0 );
			if ( order != 0 ) {
				return order;
			}

			return CompareNoCase( left.label ?: "", right.label ?: "" );
		} );

		for( var field in placements ) {
			if ( ( field.form_placement ?: "" ) != "manual" ) {
				continue;
			}
			if ( !Len( Trim( field.form_tab ?: "" ) ) || !Len( Trim( field.form_fieldset ?: "" ) ) ) {
				continue;
			}

			var tab = _findCatalogueItem( tabs, field.form_tab );
			if ( StructIsEmpty( tab ) ) {
				tab = {
					  id             = field.form_tab
					, label          = Len( Trim( field.form_tab_label ?: "" ) ) ? field.form_tab_label : field.form_tab
					, created        = true
					, labelFromField = Len( Trim( field.form_tab_label ?: "" ) ) > 0
					, fieldsets      = []
				};
				ArrayAppend( tabs, tab );
			} else if ( ( tab.created ?: false ) && Len( Trim( field.form_tab_label ?: "" ) ) && !( tab.labelFromField ?: false ) ) {
				tab.label          = field.form_tab_label;
				tab.labelFromField = true;
			}

			var fieldset = _findCatalogueItem( tab.fieldsets, field.form_fieldset );
			if ( StructIsEmpty( fieldset ) ) {
				ArrayAppend( tab.fieldsets, {
					  id      = field.form_fieldset
					, label   = Len( Trim( field.form_fieldset_label ?: "" ) ) ? field.form_fieldset_label : field.form_fieldset
					, created = true
				} );
			}
		}

		return tabs;
	}

	/**
	 * Turns a posted placement into stored column values.
	 * error is a resource URI when the manual placement is incomplete.
	 *
	 * @autodoc true
	 */
	public struct function prepareFormPlacement( required struct formData, required array catalogue ) {
		var placement = ( arguments.formData.form_placement ?: "auto" ) == "manual" ? "manual" : "auto";
		var result    = {
			  include_in_add_form  = _booleanWithDefault( arguments.formData.include_in_add_form  ?: "", true )
			, include_in_edit_form = _booleanWithDefault( arguments.formData.include_in_edit_form ?: "", true )
			, form_placement       = placement
			, form_tab             = ""
			, form_tab_label       = ""
			, form_fieldset        = ""
			, form_fieldset_label  = ""
			, errorField           = ""
			, error                = ""
		};

		if ( placement != "manual" ) {
			return result;
		}

		var tabId    = Trim( arguments.formData.form_tab ?: "" );
		var tabLabel = Trim( arguments.formData.form_tab_label ?: "" );
		var tab      = _findCatalogueItem( arguments.catalogue, tabId );

		if ( tabId == "__new__" || !Len( tabId ) ) {
			if ( !Len( tabLabel ) ) {
				result.errorField = "form_tab_label";
				result.error      = "customFields:formPlacement.validation.tabLabel";
				return result;
			}

			result.form_tab       = _uniqueCatalogueId( arguments.catalogue, _placementSlug( tabLabel ) );
			result.form_tab_label = tabLabel;
			tab = { id=result.form_tab, fieldsets=[] };
		} else if ( StructIsEmpty( tab ) ) {
			result.errorField = "form_tab";
			result.error      = "customFields:formPlacement.validation.tab";
			return result;
		} else {
			result.form_tab = tab.id;
			if ( tab.created ?: false ) {
				result.form_tab_label = tab.label ?: "";
			}
		}

		var fieldsetId    = Trim( arguments.formData.form_fieldset ?: "" );
		var fieldsetLabel = Trim( arguments.formData.form_fieldset_label ?: "" );
		var fieldsets     = tab.fieldsets ?: [];
		var fieldset      = _findCatalogueItem( fieldsets, fieldsetId );

		if ( fieldsetId == "__new__" || !Len( fieldsetId ) ) {
			if ( !Len( fieldsetLabel ) ) {
				result.errorField = "form_fieldset_label";
				result.error      = "customFields:formPlacement.validation.fieldsetLabel";
				return result;
			}

			result.form_fieldset       = _uniqueCatalogueId( fieldsets, _placementSlug( fieldsetLabel ) );
			result.form_fieldset_label = fieldsetLabel;
		} else if ( StructIsEmpty( fieldset ) ) {
			result.errorField = "form_fieldset";
			result.error      = "customFields:formPlacement.validation.fieldset";
			return result;
		} else {
			result.form_fieldset = fieldset.id;
			if ( fieldset.created ?: false ) {
				result.form_fieldset_label = fieldset.label ?: "";
			}
		}

		return result;
	}

	/**
	 * Static fields that should appear on the add or edit form.
	 *
	 * @autodoc true
	 */
	public array function filterFieldsForRecordForm( required array fields, required string operation ) {
		var included = [];

		for( var field in arguments.fields ) {
			if ( ( field.kind ?: "static" ) != "static" ) {
				continue;
			}
			if ( _includedOnForm( field, arguments.operation ) ) {
				ArrayAppend( included, field );
			}
		}

		return included;
	}

	/**
	 * Form fragment that places static custom fields onto an add or edit form.
	 *
	 * @autodoc true
	 */
	public struct function buildRecordFormDefinition( required array fields ) {
		var formDefinition = new preside.system.services.forms.FormDefinition();

		appendRecordFormFields( formDefinition, arguments.fields );

		return formDefinition.getRawDefinition();
	}

	/**
	 * Adds static custom fields to a dynamic form definition.
	 *
	 * @autodoc true
	 */
	public void function appendRecordFormFields( required any formDefinition, required array fields ) {
		var hasAuto = false;

		for( var field in arguments.fields ) {
			if ( ( field.form_placement ?: "auto" ) != "manual" ) {
				hasAuto = true;
				break;
			}
		}

		if ( hasAuto ) {
			arguments.formDefinition.addTab(
				  id        = "customFields"
				, sortorder = CUSTOM_FIELDS_TAB_SORTORDER
				, title     = "customFields:formtab.customFields.title"
			);
			arguments.formDefinition.addFieldset(
				  id        = "customFields"
				, tab       = "customFields"
				, sortorder = 10
				, title     = "customFields:formtab.customFields.title"
			);
		}

		for( var field in arguments.fields ) {
			var placement  = ( field.form_placement ?: "auto" ) == "manual" ? "manual" : "auto";
			var tabId      = "customFields";
			var fieldsetId = "customFields";

			if ( placement == "manual" ) {
				tabId      = Trim( field.form_tab      ?: "" );
				fieldsetId = Trim( field.form_fieldset ?: "" );
				if ( !Len( tabId ) || !Len( fieldsetId ) ) {
					continue;
				}

				var tabLabel      = Trim( field.form_tab_label      ?: "" );
				var fieldsetLabel = Trim( field.form_fieldset_label ?: "" );

				if ( Len( tabLabel ) ) {
					arguments.formDefinition.modifyTab( id=tabId, title=tabLabel, sortorder=CREATED_ITEM_SORTORDER );
				} else {
					arguments.formDefinition.modifyTab( id=tabId );
				}

				if ( Len( fieldsetLabel ) ) {
					arguments.formDefinition.modifyFieldset( id=fieldsetId, tab=tabId, title=fieldsetLabel, sortorder=CREATED_ITEM_SORTORDER );
				} else {
					arguments.formDefinition.modifyFieldset( id=fieldsetId, tab=tabId );
				}
			}

			var args = _staticValueFieldArgs( field );
			args.tab      = tabId;
			args.fieldset = fieldsetId;
			arguments.formDefinition.addField( argumentCollection=args );
		}
	}

	/**
	 * Returns the add or edit form name, merged with the custom field fragment when there is anything to show.
	 *
	 * @autodoc true
	 */
	public string function getMergedRecordFormName(
		  required string objectName
		, required string baseFormName
		, required string operation
	) {
		if ( !isObjectEnabled( arguments.objectName ) || !Len( Trim( arguments.baseFormName ) ) ) {
			return arguments.baseFormName;
		}

		var fields = filterFieldsForRecordForm(
			  fields    = listFields( objectName=arguments.objectName, kind="static" )
			, operation = arguments.operation
		);

		if ( !ArrayLen( fields ) ) {
			return arguments.baseFormName;
		}

		var service     = this;
		var dynamicName = formsService.createForm( function( formDefinition ){
			service.appendRecordFormFields( formDefinition, fields );
		} );

		var mergedName     = formsService.getMergedFormName( arguments.baseFormName, dynamicName );
		var formDefinition = formsService.getForm( mergedName );

		formDefinition.customFieldObject = arguments.objectName;
		_ensureVisibleTabTitles( mergedName );

		return mergedName;
	}

	/**
	 * Object whose add or edit form this is, including merged dynamic forms.
	 *
	 * @autodoc true
	 */
	public string function objectNameFromRecordForm( required string formName ) {
		var match = ReMatchNoCase( "^preside-objects\.([a-z0-9_]+)\.admin\.(add|edit)($|\.)", arguments.formName );

		if ( ArrayLen( match ) ) {
			return ListGetAt( arguments.formName, 2, "." );
		}

		if ( !FindNoCase( "dynamicform-", arguments.formName ) ) {
			return "";
		}

		try {
			return Trim( formsService.getForm( arguments.formName ).customFieldObject ?: "" );
		} catch ( any e ) {
			return "";
		}
	}

	public array function listAggregateCandidateProperties( required string objectName ) {
		var result = [];

		if ( !Len( Trim( arguments.objectName ) ) || !presideObjectService.objectExists( arguments.objectName ) ) {
			return result;
		}

		var properties = presideObjectService.getObjectProperties( arguments.objectName );

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

	public boolean function objectHasAggregateRelationships( required string objectName ) {
		return ArrayLen( listAggregateCandidateProperties( arguments.objectName ) ) > 0;
	}

	public string function getRelatedObjectForAggregateProperty( required string objectName, required string propertyName ) {
		if ( !Len( Trim( arguments.objectName ) ) || !Len( Trim( arguments.propertyName ) ) || !presideObjectService.objectExists( arguments.objectName ) ) {
			return "";
		}

		return presideObjectService.getObjectPropertyAttribute(
			  objectName    = arguments.objectName
			, propertyName  = arguments.propertyName
			, attributeName = "relatedTo"
			, defaultValue  = ""
		);
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

	public boolean function objectHasRelatedDataRelationships( required string objectName ) {
		return ArrayLen( listRelatedDataRelationshipPaths( objectName=arguments.objectName, maxHops=1 ) ) > 0;
	}

	public array function listRelatedDataRelationshipPaths( required string objectName, numeric maxHops=3 ) {
		var result = [];

		_collectRelatedDataRelationshipPaths(
			  objectName    = arguments.objectName
			, prefix        = ""
			, prefixLabel   = ""
			, remainingHops = arguments.maxHops
			, result        = result
		);

		return result;
	}

	public string function getRelatedObjectForRelatedDataPath( required string objectName, required string relationshipPath ) {
		if ( !Len( Trim( arguments.objectName ) ) || !Len( Trim( arguments.relationshipPath ) ) || !presideObjectService.objectExists( arguments.objectName ) ) {
			return "";
		}

		var currentObject = arguments.objectName;

		for( var hop in ListToArray( arguments.relationshipPath, "." ) ) {
			if ( !_isUsableRelatedDataPropertyName( hop ) ) {
				return "";
			}

			var properties = presideObjectService.getObjectProperties( currentObject );
			if ( !StructKeyExists( properties, hop ) || !_isManyToOneProperty( properties[ hop ] ) ) {
				return "";
			}

			var relatedTo = _relatedTo( properties[ hop ], hop );
			if ( !Len( relatedTo ) || !presideObjectService.objectExists( relatedTo ) ) {
				return "";
			}

			currentObject = relatedTo;
		}

		return currentObject;
	}

	public array function listRelatedDataProperties( required string objectName, required string relationshipPath ) {
		var relatedObject = getRelatedObjectForRelatedDataPath( arguments.objectName, arguments.relationshipPath );
		if ( !Len( relatedObject ) ) {
			return [];
		}

		var properties = presideObjectService.getObjectProperties( relatedObject );
		var names      = StructKeyArray( properties );
		var result     = [];

		ArraySort( names, "textnocase" );

		for( var propName in names ) {
			if ( !_isUsableRelatedDataPropertyName( propName ) || !_isRelatedDataValueProperty( properties[ propName ] ) ) {
				continue;
			}

			ArrayAppend( result, {
				  id    = propName
				, label = _relatedDataPropertyLabel( relatedObject, propName, properties[ propName ] )
			} );
		}

		return result;
	}

	public array function listRelatedDataTreeNodes(
		  required string  objectName
		,          string  relationshipPath = ""
		,          numeric maxHops          = 3
	) {
		var currentObject = arguments.objectName;
		var isRoot        = !Len( Trim( arguments.relationshipPath ) );

		if ( !isRoot ) {
			currentObject = getRelatedObjectForRelatedDataPath( arguments.objectName, arguments.relationshipPath );
		}

		if ( !Len( currentObject ) || !presideObjectService.objectExists( currentObject ) ) {
			return [];
		}

		var properties       = presideObjectService.getObjectProperties( currentObject );
		var names            = StructKeyArray( properties );
		var hopCount         = ListLen( arguments.relationshipPath, "." );
		var canExpandFurther = hopCount < arguments.maxHops;
		var relationships    = [];
		var fields           = [];

		ArraySort( names, "textnocase" );

		for( var propName in names ) {
			if ( !_isUsableRelatedDataPropertyName( propName ) ) {
				continue;
			}

			var prop  = properties[ propName ];
			var isM2o = _isManyToOneProperty( prop );

			if ( isRoot ) {
				if ( !isM2o ) {
					continue;
				}

				var relatedTo = _relatedTo( prop, propName );
				if ( !Len( relatedTo ) || !presideObjectService.objectExists( relatedTo ) ) {
					continue;
				}

				ArrayAppend( relationships, _relatedDataTreeNode(
					  type             = "relationship"
					, propertyName     = propName
					, label            = _relatedDataPropertyLabel( currentObject, propName, prop )
					, relationshipPath = ""
					, path             = propName
					, hasChildren      = true
				) );
				continue;
			}

			if ( !_isRelatedDataValueProperty( prop ) ) {
				continue;
			}

			if ( isM2o ) {
				var relatedTo = _relatedTo( prop, propName );
				if ( !Len( relatedTo ) || !presideObjectService.objectExists( relatedTo ) ) {
					continue;
				}

				ArrayAppend( relationships, _relatedDataTreeNode(
					  type             = "relationship"
					, propertyName     = propName
					, label            = _relatedDataPropertyLabel( currentObject, propName, prop )
					, relationshipPath = arguments.relationshipPath
					, path             = arguments.relationshipPath & "." & propName
					, hasChildren      = canExpandFurther
				) );
				continue;
			}

			ArrayAppend( fields, _relatedDataTreeNode(
				  type             = "property"
				, propertyName     = propName
				, label            = _relatedDataPropertyLabel( currentObject, propName, prop )
				, relationshipPath = arguments.relationshipPath
				, path             = arguments.relationshipPath & "." & propName
				, hasChildren      = false
			) );
		}

		for( var field in fields ) {
			ArrayAppend( relationships, field );
		}

		return relationships;
	}

	public string function getRelatedDataSelectionLabel(
		  required string objectName
		, required string relationshipPath
		, required string propertyName
	) {
		if ( !Len( Trim( arguments.objectName ) ) || !Len( Trim( arguments.relationshipPath ) ) || !Len( Trim( arguments.propertyName ) ) ) {
			return "";
		}

		var currentObject = arguments.objectName;
		var labels        = [];

		for( var hop in ListToArray( arguments.relationshipPath, "." ) ) {
			if ( !presideObjectService.objectExists( currentObject ) ) {
				return "";
			}

			var properties = presideObjectService.getObjectProperties( currentObject );
			if ( !StructKeyExists( properties, hop ) || !_isManyToOneProperty( properties[ hop ] ) ) {
				return "";
			}

			ArrayAppend( labels, _relatedDataPropertyLabel( currentObject, hop, properties[ hop ] ) );
			currentObject = _relatedTo( properties[ hop ], hop );
		}

		if ( !Len( currentObject ) || !presideObjectService.objectExists( currentObject ) ) {
			return "";
		}

		var terminalProperties = presideObjectService.getObjectProperties( currentObject );
		if ( !StructKeyExists( terminalProperties, arguments.propertyName ) ) {
			return "";
		}

		ArrayAppend( labels, _relatedDataPropertyLabel( currentObject, arguments.propertyName, terminalProperties[ arguments.propertyName ] ) );

		return ArrayToList( labels, " → " );
	}

	public struct function resolveRelatedDataPath(
		  required string objectName
		, required string relationshipPath
		, required string propertyName
	) {
		var result = {
			  valid         = false
			, path          = ""
			, relatedObject = ""
			, type          = "string"
			, renderer      = ""
			, relatedTo     = ""
			, relationship  = "none"
			, formula       = ""
			, dataType      = "text"
		};

		var relatedObject = getRelatedObjectForRelatedDataPath( arguments.objectName, arguments.relationshipPath );
		if ( !Len( relatedObject ) || !Len( Trim( arguments.propertyName ) ) || !_isUsableRelatedDataPropertyName( arguments.propertyName ) ) {
			return result;
		}

		var properties = presideObjectService.getObjectProperties( relatedObject );
		if ( !StructKeyExists( properties, arguments.propertyName ) || !_isRelatedDataValueProperty( properties[ arguments.propertyName ] ) ) {
			return result;
		}

		var terminal         = properties[ arguments.propertyName ];
		result.valid         = true;
		result.relatedObject = relatedObject;
		result.path          = arguments.relationshipPath & "." & arguments.propertyName;
		result.relationship  = LCase( terminal.relationship ?: "none" );
		result.type          = terminal.type ?: "string";
		result.formula       = Trim( terminal.formula ?: "" );
		result.renderer      = Trim( terminal.renderer ?: "" );
		result.dataType      = _inferCustomFieldDataType( terminal );

		if ( result.relationship == "many-to-one" ) {
			result.relatedTo = _relatedTo( terminal, arguments.propertyName );
			if ( !Len( result.renderer ) ) {
				result.renderer = "manyToOne";
			}
		}

		return result;
	}

	public boolean function isValidRelatedDataPath(
		  required string objectName
		, required string relationshipPath
		, required string propertyName
	) {
		return $helpers.isTrue( resolveRelatedDataPath(
			  objectName       = arguments.objectName
			, relationshipPath = arguments.relationshipPath
			, propertyName     = arguments.propertyName
		).valid ?: false );
	}

	public string function evaluateConditionalLabel( required string encodedValue ) {
		var matchingRules = evaluateConditionalLabels( arguments.encodedValue );

		return ArrayLen( matchingRules ) ? matchingRules[ 1 ] : "";
	}

	public array function evaluateConditionalLabels( required string encodedValue ) {
		var parts = ListToArray( arguments.encodedValue, "." );
		if ( ArrayLen( parts ) < 2 ) {
			return [];
		}

		var fieldId  = parts[ 1 ];
		var recordId = ArrayToList( ArraySlice( parts, 2 ), "." );
		var field    = getField( fieldId );
		if ( StructIsEmpty( field ) ) {
			return [];
		}

		var rules   = listConditionalRules( fieldId );
		var matches = [];
		if ( !ArrayLen( rules ) ) {
			return matches;
		}

		for( var rule in rules ) {
			if ( !Len( Trim( rule.filter ?: "" ) ) ) {
				continue;
			}
			if ( _conditionalRuleMatches( field=field, rule=rule, recordId=recordId ) ) {
				ArrayAppend( matches, rule.id );

				if ( ( field.conditional_label_mode ?: "single" ) != "multiple" ) {
					break;
				}
			}
		}

		return matches;
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

	public array function listConditionalRuleOptions( required string fieldId ) {
		var options = [];

		for( var rule in listConditionalRules( arguments.fieldId ) ) {
			if ( Len( Trim( rule.filter ?: "" ) ) ) {
				ArrayAppend( options, { id=rule.id, label=rule.label_text ?: rule.id } );
			}
		}

		return options;
	}

	public struct function prepareConditionalLabelFilter(
		  required string objectName
		, required string fieldId
		, required string ruleId
	) {
		var field = getField( arguments.fieldId );
		if (
			   StructIsEmpty( field )
			|| ( field.kind ?: "" ) != "conditional_label"
			|| ( field.target_object ?: "" ) != arguments.objectName
		) {
			return { filter="1=0", filterParams={} };
		}

		var clauses      = [];
		var filterParams = {};
		var selectedRule = {};
		var earlierRules = [];

		for( var rule in listConditionalRules( arguments.fieldId ) ) {
			if ( ( rule.id ?: "" ) == arguments.ruleId ) {
				selectedRule = rule;
				break;
			}
			if ( Len( Trim( rule.filter ?: "" ) ) ) {
				ArrayAppend( earlierRules, rule );
			}
		}

		if ( StructIsEmpty( selectedRule ) || !Len( Trim( selectedRule.filter ?: "" ) ) ) {
			return { filter="1=0", filterParams={} };
		}

		var selectedFilter = _conditionalRuleExistsFilter(
			  objectName = arguments.objectName
			, rule       = selectedRule
		);
		ArrayAppend( clauses, selectedFilter.filter );
		StructAppend( filterParams, selectedFilter.filterParams );

		if ( ( field.conditional_label_mode ?: "single" ) != "multiple" ) {
			for( var earlierRule in earlierRules ) {
				var earlierFilter = _conditionalRuleExistsFilter(
					  objectName = arguments.objectName
					, rule       = earlierRule
					, negate     = true
				);
				ArrayAppend( clauses, earlierFilter.filter );
				StructAppend( filterParams, earlierFilter.filterParams );
			}
		}

		return {
			  filter       = "( #ArrayToList( clauses, ' and ' )# )"
			, filterParams = filterParams
		};
	}

	private boolean function _conditionalRuleMatches(
		  required struct field
		, required struct rule
		, required string recordId
	) {
		var objectName = arguments.field.target_object ?: "";

		return $isFeatureEnabled( "rulesEngine" ) && presideObjectService.dataExists(
			  objectName   = objectName
			, id           = arguments.recordId
			, extraFilters = [ rulesEngineFilterService.prepareFilter(
				  objectName = objectName
				, filterId   = arguments.rule.filter
			  ) ]
		);
	}

	private struct function _conditionalRuleExistsFilter(
		  required string  objectName
		, required struct  rule
		,          boolean negate = false
	) {
		var dbAdapter = presideObjectService.getDbAdapterForObject( arguments.objectName );
		var idField   = presideObjectService.getIdField( arguments.objectName );
		var subQuery  = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ idField ]
			, extraFilters        = [ rulesEngineFilterService.prepareFilter(
				  objectName = arguments.objectName
				, filterId   = arguments.rule.filter
			  ) ]
			, autoGroupBy         = true
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);
		var subQueryAlias  = dbAdapter.escapeEntity( "conditional_label_#Replace( LCase( CreateUUID() ), '-', '', 'all' )#" );
		var escapedId      = dbAdapter.escapeEntity( idField );
		var escapedOuterId = dbAdapter.escapeEntity( "#arguments.objectName#.#idField#" );
		var existsKeyword  = arguments.negate ? "not exists" : "exists";
		var filterSql      = $helpers.obfuscateSqlForPreside( "
			select #escapedId#
			from ( #subQuery.sql# ) as #subQueryAlias#
			where #escapedOuterId# = #subQueryAlias#.#escapedId#
		" );

		return {
			  filter       = "#existsKeyword# ( #filterSql# )"
			, filterParams = subQuery.params
		};
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

	private struct function _staticValueFieldArgs( required struct field ) {
		var type = customFieldTypesService.getType( arguments.field.data_type ?: "text" );
		var args = {
			  name      = arguments.field.key
			, control   = type.control ?: "textinput"
			, label     = arguments.field.label ?: ""
			, help      = arguments.field.help_text ?: ""
			, required  = false
			, sortorder = Val( arguments.field.sort_order ?: 0 )
		};

		if ( ( arguments.field.data_type ?: "" ) == "lookup" ) {
			var options = listLookupOptions( arguments.field.id ?: "" );
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

		if ( ( arguments.field.data_type ?: "" ) == "object_ref" && Len( Trim( arguments.field.related_object ?: "" ) ) ) {
			args.control = "objectPicker";
			args.object  = arguments.field.related_object;
		}

		return args;
	}

	private string function _recordFormNameFromCustomization( required string objectName, required string action ) {
		var defaultHandler = arguments.action == "getAddRecordFormName" ? "admin.datamanager._getAddRecordFormName" : "admin.datamanager._getEditRecordFormName";
		var formName       = "";

		try {
			formName = dataManagerCustomizationService.runCustomization(
				  objectName     = arguments.objectName
				, action         = arguments.action
				, defaultHandler = defaultHandler
				, args           = { objectName=arguments.objectName }
			);
		} catch ( any e ) {
			return "";
		}

		return Trim( formName ?: "" );
	}

	private boolean function _includedOnForm( required struct field, required string operation ) {
		var key = arguments.operation == "add" ? "include_in_add_form" : "include_in_edit_form";

		if ( !StructKeyExists( arguments.field, key ) ) {
			return true;
		}

		return _booleanWithDefault( arguments.field[ key ], true );
	}

	private boolean function _booleanWithDefault( required any value, required boolean defaultValue ) {
		if ( !IsSimpleValue( arguments.value ) || !Len( Trim( arguments.value ) ) ) {
			return arguments.defaultValue;
		}

		return $helpers.isTrue( arguments.value );
	}

	private struct function _findCatalogueItem( required array items, required string id ) {
		if ( !Len( arguments.id ) || arguments.id == "__new__" ) {
			return {};
		}

		for( var item in arguments.items ) {
			if ( ( item.id ?: "" ) == arguments.id ) {
				return item;
			}
		}

		return {};
	}

	private string function _formItemLabel( required struct item ) {
		var title = Trim( arguments.item.title ?: "" );
		var id    = arguments.item.id ?: "";

		if ( !Len( title ) ) {
			return _fallbackItemLabel( id );
		}
		if ( Find( ":", title ) ) {
			var translated = $translateResource( uri=title, defaultValue="" );
			return Len( translated ) ? translated : _fallbackItemLabel( id );
		}

		return title;
	}

	private string function _fallbackItemLabel( required string id ) {
		if ( arguments.id == "default" ) {
			return $translateResource( uri="customFields:formtab.general.title", defaultValue=arguments.id );
		}

		return arguments.id;
	}

	private void function _ensureVisibleTabTitles( required string formName ) {
		var formDefinition = formsService.getForm( arguments.formName );

		for( var tab in ( formDefinition.tabs ?: [] ) ) {
			if ( !_tabTitleIsVisible( tab ) ) {
				tab.title = "customFields:formtab.general.title";
			}
		}
	}

	private boolean function _tabTitleIsVisible( required struct tab ) {
		var title = Trim( arguments.tab.title ?: "" );

		if ( !Len( title ) ) {
			return false;
		}
		if ( Find( ":", title ) ) {
			return Len( $translateResource( uri=title, defaultValue="" ) ) > 0;
		}

		return true;
	}

	private string function _placementSlug( required string label ) {
		var slug = LCase( ReReplace( arguments.label, "[^a-zA-Z0-9]+", "_", "all" ) );

		slug = ReReplace( slug, "^_+|_+$", "", "all" );
		if ( !Len( slug ) || !ReFind( "^[a-z]", slug ) ) {
			slug = "item_#slug#";
		}

		return "cf_#slug#";
	}

	private string function _uniqueCatalogueId( required array items, required string preferredId ) {
		var candidate = arguments.preferredId;
		var suffix    = 2;

		while ( !StructIsEmpty( _findCatalogueItem( arguments.items, candidate ) ) ) {
			candidate = arguments.preferredId & "_" & suffix;
			suffix++;
		}

		return candidate;
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

	private void function _collectRelatedDataRelationshipPaths(
		  required string  objectName
		, required string  prefix
		, required string  prefixLabel
		, required numeric remainingHops
		, required array   result
	) {
		if ( arguments.remainingHops < 1 || !Len( Trim( arguments.objectName ) ) || !presideObjectService.objectExists( arguments.objectName ) ) {
			return;
		}

		var properties = presideObjectService.getObjectProperties( arguments.objectName );
		var names      = StructKeyArray( properties );

		ArraySort( names, "textnocase" );

		for( var propName in names ) {
			if ( !_isUsableRelatedDataPropertyName( propName ) || !_isManyToOneProperty( properties[ propName ] ) ) {
				continue;
			}

			var relatedTo = _relatedTo( properties[ propName ], propName );
			if ( !Len( relatedTo ) || !presideObjectService.objectExists( relatedTo ) ) {
				continue;
			}

			var id    = Len( arguments.prefix ) ? arguments.prefix & "." & propName : propName;
			var label = Len( arguments.prefixLabel ) ? arguments.prefixLabel & " → " & $translatePropertyName( arguments.objectName, propName ) : $translatePropertyName( arguments.objectName, propName );

			ArrayAppend( arguments.result, {
				  id        = id
				, label     = label
				, relatedTo = relatedTo
			} );

			_collectRelatedDataRelationshipPaths(
				  objectName    = relatedTo
				, prefix        = id
				, prefixLabel   = label
				, remainingHops = arguments.remainingHops - 1
				, result        = arguments.result
			);
		}
	}

	private struct function _relatedDataTreeNode(
		  required string  type
		, required string  propertyName
		, required string  label
		, required string  relationshipPath
		, required string  path
		, required boolean hasChildren
	) {
		return {
			  "id"               = arguments.path
			, "label"            = arguments.label
			, "type"             = arguments.type
			, "path"             = arguments.path
			, "property"         = arguments.propertyName
			, "relationshipPath" = arguments.relationshipPath
			, "hasChildren"      = arguments.hasChildren
		};
	}

	private boolean function _isUsableRelatedDataPropertyName( required string propertyName ) {
		return Len( Trim( arguments.propertyName ) ) && Left( arguments.propertyName, 1 ) != "_";
	}

	private boolean function _isManyToOneProperty( required struct prop ) {
		return LCase( arguments.prop.relationship ?: "none" ) == "many-to-one";
	}

	private boolean function _isRelatedDataValueProperty( required struct prop ) {
		return !ListFindNoCase( "one-to-many,many-to-many,select-data-view", LCase( arguments.prop.relationship ?: "none" ) );
	}

	private string function _relatedTo( required struct prop, required string propertyName ) {
		var relatedTo = Trim( arguments.prop.relatedTo ?: ( arguments.prop.relatedto ?: "" ) );

		return Len( relatedTo ) ? relatedTo : arguments.propertyName;
	}

	private string function _relatedDataPropertyLabel( required string objectName, required string propertyName, required struct prop ) {
		var label = Trim( arguments.prop.customFieldLabel ?: "" );

		if ( Len( label ) ) {
			return label;
		}

		return $translatePropertyName( arguments.objectName, arguments.propertyName );
	}

	private string function _inferCustomFieldDataType( required struct prop ) {
		if ( _isManyToOneProperty( arguments.prop ) ) {
			return "object_ref";
		}

		var type   = LCase( arguments.prop.type ?: "string" );
		var dbtype = LCase( arguments.prop.dbtype ?: "" );

		if ( type == "boolean" ) {
			return "boolean";
		}
		if ( type == "numeric" ) {
			return ListFindNoCase( "float,double,decimal,numeric", dbtype ) ? "float" : "integer";
		}
		if ( type == "date" ) {
			return ListFindNoCase( "datetime,timestamp", dbtype ) ? "datetime" : "date";
		}
		if ( ListFindNoCase( "text,longtext,mediumtext", dbtype ) ) {
			return "textarea";
		}

		return "text";
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

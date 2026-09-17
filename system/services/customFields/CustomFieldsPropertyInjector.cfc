/**
 * Injects custom field definitions onto opted-in Preside objects as virtual formula properties.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customFields
 */
component {

	property name="presideObjectService"             inject="delayedInjector:presideObjectService";
	property name="customFieldsService"              inject="delayedInjector:customFieldsService";
	property name="customFieldsValueTableService"    inject="delayedInjector:customFieldsValueTableService";
	property name="customFieldTypesService"          inject="delayedInjector:customFieldTypesService";
	property name="adminDataViewsService"            inject="delayedInjector:adminDataViewsService";
	property name="rulesEngineExpressionService"     inject="delayedInjector:rulesEngineExpressionService";

	public any function init() {
		return this;
	}

	public void function applyAll() {
		if ( !$isFeatureEnabled( "customFields" ) ) {
			return;
		}

		for( var objectName in customFieldsService.listEnabledObjects() ) {
			refreshObject( objectName );
		}
	}

	public void function refreshObject( required string objectName ) {
		if ( !$isFeatureEnabled( "customFields" ) || !customFieldsService.isObjectEnabled( arguments.objectName ) ) {
			return;
		}
		if ( !presideObjectService.objectExists( arguments.objectName ) ) {
			return;
		}

		var properties    = presideObjectService.getObjectProperties( arguments.objectName );
		var propertyNames = Duplicate( presideObjectService.getObjectAttribute( arguments.objectName, "propertyNames" ) );
		if ( !IsArray( propertyNames ) ) {
			propertyNames = [];
			for( var propName in properties ) {
				ArrayAppend( propertyNames, propName );
			}
		}

		_removeInjectedProperties( properties, propertyNames );

		var fields = [];
		try {
			fields = customFieldsService.listFields( objectName=arguments.objectName, includeInactive=false );
		} catch ( any e ) {
			return;
		}

		for( var field in fields ) {
			if ( StructKeyExists( properties, field.key ) ) {
				continue;
			}

			properties[ field.key ] = buildPropertyDefinition(
				  field      = field
				, objectName = arguments.objectName
			);
			ArrayAppend( propertyNames, field.key );
		}

		presideObjectService.setObjectAttribute( arguments.objectName, "propertyNames", propertyNames );
		presideObjectService.setObjectAttribute( arguments.objectName, "formulaFieldList", _calculateFormulaFieldList( properties ) );

		if ( $isFeatureEnabled( "admin" ) ) {
			try {
				adminDataViewsService.clearCache();
			} catch ( any e ) {}
		}
		if ( $isFeatureEnabled( "rulesEngine" ) ) {
			try {
				rulesEngineExpressionService.clearDynamicExpressionsForObject( arguments.objectName );
			} catch ( any e ) {}
		}
	}

	public struct function buildPropertyDefinition( required struct field, required string objectName ) {
		var field      = arguments.field;
		var kind       = field.kind ?: "static";
		var definition = {
			  name                   = field.key
			, formula                = buildFormula( field=field, objectName=arguments.objectName )
			, dbtype                 = "none"
			, control                = "none"
			, required               = false
			, relationship           = "none"
			, relatedto              = "none"
			, generator              = "none"
			, customField            = true
			, customFieldId          = field.id
			, customFieldKind        = kind
			, customFieldLabel       = customFieldsService.getFieldListingLabel( field )
			, customFieldHelp        = field.help_text ?: ""
			, datamanagerUserColumn  = true
			, excludeDataExport      = !$helpers.isTrue( field.data_exportable ?: true )
			, batchEditable          = false
			, adminViewGroup         = customFieldsService.getSlotViewGroup( arguments.objectName, field.slot ?: "custom" )
			, sortOrder              = Val( field.sort_order ?: 0 )
		};

		if ( kind == "static" ) {
			var dataType                   = field.data_type ?: "text";
			var type                       = customFieldTypesService.getType( dataType );
			definition.type                = type.type ?: "string";
			definition.control             = customFieldTypesService.getControl( dataType );
			definition.renderer            = customFieldTypesService.getRenderer( dataType, field.renderer ?: "" );
			definition.autofilter          = true;
			definition.batchEditable       = $helpers.isTrue( field.batch_editable ?: true );
			definition.customFieldDataType = dataType;

			if ( dataType == "object_ref" && Len( Trim( field.related_object ?: "" ) ) ) {
				definition.relatedto = field.related_object;
				definition.renderer  = Len( Trim( field.renderer ?: "" ) ) ? field.renderer : "manyToOne";
			}
			if ( dataType == "lookup" ) {
				definition.renderer = Len( Trim( field.renderer ?: "" ) ) ? field.renderer : "customFieldLookup";
				definition.customFieldLookupOptions = customFieldsService.listLookupOptions( field.id );
				definition.includeEmptyOption = true;
				definition.values = [];
				definition.labels = [];
				for( var option in definition.customFieldLookupOptions ) {
					ArrayAppend( definition.values, option.id );
					ArrayAppend( definition.labels, option.label );
				}
			}
			if ( dataType == "date" ) {
				definition.dbtype = "none";
			}
			if ( dataType == "datetime" ) {
				definition.type = "date";
			}
		} else if ( kind == "aggregate" ) {
			definition.type       = "numeric";
			definition.renderer   = Len( Trim( field.renderer ?: "" ) ) ? field.renderer : "none";
			definition.autofilter = true;
		} else {
			definition.type       = "string";
			definition.renderer   = "customFieldConditionalLabel";
			definition.autofilter = false;
		}

		return definition;
	}

	public string function buildFormula( required struct field, required string objectName ) {
		var kind = arguments.field.kind ?: "static";

		switch( kind ) {
			case "aggregate":
				return _buildAggregateFormula( argumentCollection=arguments );
			case "conditional_label":
				return _buildConditionalFormula( argumentCollection=arguments );
		}

		return _buildStaticFormula( argumentCollection=arguments );
	}

	private string function _buildStaticFormula( required struct field, required string objectName ) {
		var valueObject = customFieldsValueTableService.getValueObjectName( arguments.objectName );
		var table       = presideObjectService.getObjectAttribute( valueObject, "tableName" );
		var typedCol    = customFieldTypesService.getTypedColumn( arguments.field.data_type ?: "text" );
		var selectCol   = Len( Trim( typedCol ) ) ? typedCol : "field_value";
		var idField = presideObjectService.getIdField( arguments.objectName );

		return "( select #selectCol# from #table# where field = #_sqlFieldId( arguments.field.id )# and record = ${prefix}#idField# )";
	}

	private string function _buildAggregateFormula( required struct field, required string objectName ) {
		var relatedProp = Trim( arguments.field.aggregate_property ?: "" );
		var fn          = LCase( Trim( arguments.field.aggregate_function ?: "count" ) );
		var valueProp   = Trim( arguments.field.aggregate_value_property ?: "" );
		var relatedTo   = presideObjectService.getObjectPropertyAttribute(
			  objectName    = arguments.objectName
			, propertyName  = relatedProp
			, attributeName = "relatedTo"
			, defaultValue  = ""
		);
		var relatedId = Len( relatedTo ) ? presideObjectService.getIdField( relatedTo ) : "id";

		if ( !Len( relatedProp ) ) {
			return "0";
		}

		if ( fn == "count" || !Len( valueProp ) ) {
			return "count( distinct ${prefix}#relatedProp#.#relatedId# )";
		}

		return "agg:#fn#{ ${prefix}#relatedProp#.#valueProp# }";
	}

	private string function _buildConditionalFormula( required struct field, required string objectName ) {
		var idField = presideObjectService.getIdField( arguments.objectName );
		return "concat( #_sqlFieldId( arguments.field.id )#, '.', ${prefix}#idField# )";
	}

	private void function _removeInjectedProperties( required struct properties, required array propertyNames ) {
		var toRemove = [];

		for( var propName in arguments.properties ) {
			if ( $helpers.isTrue( arguments.properties[ propName ].customField ?: "" ) ) {
				ArrayAppend( toRemove, propName );
			}
		}

		for( var propName in toRemove ) {
			StructDelete( arguments.properties, propName );
			ArrayDelete( arguments.propertyNames, propName );
		}
	}

	private string function _calculateFormulaFieldList( required struct properties ) {
		var list = [];
		for( var propName in arguments.properties ) {
			if ( Len( arguments.properties[ propName ].formula ?: "" ) ) {
				ArrayAppend( list, propName );
			}
		}

		return ArrayToList( list );
	}

	private string function _sqlFieldId( required any fieldId ) {
		var id = Trim( ToString( arguments.fieldId ) );
		if ( ReFind( "^[0-9]+$", id ) ) {
			return id;
		}

		return _sqlString( id );
	}

	private string function _sqlString( required string value ) {
		return "'" & Replace( arguments.value, "'", "''", "all" ) & "'";
	}

}

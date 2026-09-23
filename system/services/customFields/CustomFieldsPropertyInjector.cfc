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
	property name="rulesEngineFilterService"         inject="delayedInjector:rulesEngineFilterService";

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
			, datamanagerUserColumn  = $helpers.isTrue( field.show_in_listing ?: true )
			, excludeDataExport      = !$helpers.isTrue( field.data_exportable ?: true )
			, batchEditable          = false
			, adminViewGroup         = "customFields"
			, sortOrder              = Val( field.sort_order ?: 0 )
		};

		if ( kind == "static" ) {
			var dataType                   = field.data_type ?: "text";
			var type                       = customFieldTypesService.getType( dataType );
			definition.type                = type.type ?: "string";
			definition.control             = customFieldTypesService.getControl( dataType );
			definition.renderer            = customFieldTypesService.getRenderer( dataType );
			definition.autofilter          = $helpers.isTrue( field.filterable ?: true );
			definition.batchEditable       = $helpers.isTrue( field.batch_editable ?: true );
			definition.customFieldDataType = dataType;

			if ( dataType == "object_ref" && Len( Trim( field.related_object ?: "" ) ) ) {
				definition.relatedto = field.related_object;
				definition.renderer  = "manyToOne";
			}
			if ( dataType == "lookup" ) {
				definition.renderer = "customFieldLookup";
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
			definition.autofilter = $helpers.isTrue( field.filterable ?: true );
		} else if ( kind == "related_data" ) {
			var resolved          = customFieldsService.resolveRelatedDataPath(
				  objectName       = arguments.objectName
				, relationshipPath = field.related_data_relationship ?: ""
				, propertyName     = field.related_data_property     ?: ""
			);
			definition.type       = resolved.type ?: "string";
			definition.autofilter = $helpers.isTrue( field.filterable ?: true );
			if ( Len( Trim( resolved.renderer ?: "" ) ) ) {
				definition.renderer = resolved.renderer;
			}
			if ( Len( Trim( resolved.relatedTo ?: "" ) ) ) {
				definition.relatedto = resolved.relatedTo;
			}
		} else {
			definition.type                = "string";
			definition.renderer            = "customFieldConditionalLabel";
			definition.autofilter          = $helpers.isTrue( field.filterable ?: true );
			definition.datamanagerSortable = false;
		}

		return definition;
	}

	public string function buildFormula( required struct field, required string objectName ) {
		var kind = arguments.field.kind ?: "static";

		switch( kind ) {
			case "aggregate":
				return _buildAggregateFormula( argumentCollection=arguments );
			case "related_data":
				return _buildRelatedDataFormula( argumentCollection=arguments );
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
		var filterId    = Trim( arguments.field.aggregate_filter ?: "" );
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

		if ( Len( filterId ) && $isFeatureEnabled( "rulesEngine" ) ) {
			var filtered = _buildFilteredAggregateFormula( argumentCollection=arguments, relatedTo=relatedTo, relatedId=relatedId, fn=fn, valueProp=valueProp, filterId=filterId, relatedProp=relatedProp );
			if ( Len( filtered ) ) {
				return filtered;
			}
		}

		if ( fn == "count" || !Len( valueProp ) ) {
			return "count( distinct ${prefix}#relatedProp#.#relatedId# )";
		}

		return "agg:#fn#{ ${prefix}#relatedProp#.#valueProp# }";
	}

	private string function _buildRelatedDataFormula( required struct field, required string objectName ) {
		var relationshipPath = Trim( arguments.field.related_data_relationship ?: "" );
		var propertyName     = Trim( arguments.field.related_data_property     ?: "" );

		if ( !Len( relationshipPath ) || !Len( propertyName ) ) {
			return "''";
		}

		var resolved = customFieldsService.resolveRelatedDataPath(
			  objectName       = arguments.objectName
			, relationshipPath = relationshipPath
			, propertyName     = propertyName
		);

		if ( !$helpers.isTrue( resolved.valid ?: false ) ) {
			return "''";
		}

		var joinPath = _relatedDataJoinPath( relationshipPath );

		if ( Len( Trim( resolved.formula ?: "" ) ) && FindNoCase( "${prefix}", resolved.formula ) ) {
			return ReplaceNoCase( resolved.formula, "${prefix}", "${prefix}" & joinPath & ".", "all" );
		}

		return "${prefix}" & joinPath & "." & propertyName;
	}

	private string function _relatedDataJoinPath( required string relationshipPath ) {
		return Replace( arguments.relationshipPath, ".", "$", "all" );
	}

	private string function _buildFilteredAggregateFormula(
		  required struct field
		, required string objectName
		, required string relatedProp
		, required string relatedTo
		, required string relatedId
		, required string fn
		, required string valueProp
		, required string filterId
	) {
		if ( !Len( arguments.relatedTo ) || !presideObjectService.objectExists( arguments.relatedTo ) ) {
			return "";
		}

		var parentIdField     = presideObjectService.getIdField( arguments.objectName );
		var parentPlaceholder = "__cf_parent_id__";
		var relationship      = presideObjectService.getObjectPropertyAttribute(
			  objectName    = arguments.objectName
			, propertyName  = arguments.relatedProp
			, attributeName = "relationship"
			, defaultValue  = ""
		);
		var extraFilters = [ rulesEngineFilterService.prepareFilter(
			  objectName = arguments.relatedTo
			, filterId   = arguments.filterId
		) ];
		var sqlAndParams = {};

		try {
			if ( relationship == "one-to-many" ) {
				var relationshipKey = presideObjectService.getObjectPropertyAttribute(
					  objectName    = arguments.objectName
					, propertyName  = arguments.relatedProp
					, attributeName = "relationshipKey"
					, defaultValue  = arguments.objectName
				);
				var aggExpression = ( arguments.fn == "count" || !Len( arguments.valueProp ) )
					? "count( #arguments.relatedTo#.#arguments.relatedId# )"
					: "#arguments.fn#( #arguments.relatedTo#.#arguments.valueProp# )";

				ArrayAppend( extraFilters, { filter="#arguments.relatedTo#.#relationshipKey# = '#parentPlaceholder#'" } );

				sqlAndParams = presideObjectService.selectData(
					  objectName          = arguments.relatedTo
					, selectFields        = [ "#aggExpression# as agg_value" ]
					, extraFilters        = extraFilters
					, getSqlAndParamsOnly = true
					, formatSqlParams     = true
				);
			} else {
				var parentAgg = ( arguments.fn == "count" || !Len( arguments.valueProp ) )
					? "count( #arguments.relatedProp#.#arguments.relatedId# )"
					: "#arguments.fn#( #arguments.relatedProp#.#arguments.valueProp# )";
				var mmFilters = [ _rewriteFilterForRelatedProperty(
					  prepared    = extraFilters[ 1 ]
					, relatedTo   = arguments.relatedTo
					, relatedProp = arguments.relatedProp
				) ];

				ArrayAppend( mmFilters, { filter="#arguments.objectName#.#parentIdField# = '#parentPlaceholder#'" } );

				sqlAndParams = presideObjectService.selectData(
					  objectName          = arguments.objectName
					, selectFields        = [ "#parentAgg# as agg_value" ]
					, extraFilters        = mmFilters
					, getSqlAndParamsOnly = true
					, formatSqlParams     = true
				);
			}
		} catch ( any e ) {
			return "";
		}

		var sql = _inlineSqlParams( sqlAndParams.sql ?: "", sqlAndParams.params ?: {} );
		if ( !Len( Trim( sql ) ) ) {
			return "";
		}

		if ( FindNoCase( "'#parentPlaceholder#'", sql ) ) {
			sql = ReplaceNoCase( sql, "'#parentPlaceholder#'", "${prefix}#parentIdField#", "all" );
		} else {
			sql = ReplaceNoCase( sql, parentPlaceholder, "${prefix}#parentIdField#", "all" );
		}

		return "ifnull( ( #sql# ), 0 )";
	}

	private struct function _rewriteFilterForRelatedProperty(
		  required struct prepared
		, required string relatedTo
		, required string relatedProp
	) {
		var rewritten = Duplicate( arguments.prepared );

		if ( IsSimpleValue( rewritten.filter ?: "" ) ) {
			rewritten.filter = ReplaceNoCase( rewritten.filter, arguments.relatedTo & ".", arguments.relatedProp & ".", "all" );
		}
		if ( Len( Trim( rewritten.having ?: "" ) ) ) {
			rewritten.having = ReplaceNoCase( rewritten.having, arguments.relatedTo & ".", arguments.relatedProp & ".", "all" );
		}
		if ( IsArray( rewritten.extraJoins ?: "" ) ) {
			for( var i=1; i<=ArrayLen( rewritten.extraJoins ); i++ ) {
				var join = rewritten.extraJoins[ i ];
				if ( ( join.tableAlias ?: "" ) == arguments.relatedTo ) {
					join.tableAlias = arguments.relatedProp;
				}
				if ( ( join.joinToTable ?: "" ) == arguments.relatedTo ) {
					join.joinToTable = arguments.relatedProp;
				}
			}
		}

		return rewritten;
	}

	private string function _inlineSqlParams( required string sql, required any params ) {
		var sql        = arguments.sql;
		var paramNames = [];

		if ( IsStruct( arguments.params ) ) {
			paramNames = StructKeyArray( arguments.params );
			ArraySort( paramNames, function( a, b ){
				return Len( b ) - Len( a );
			} );
			for( var name in paramNames ) {
				sql = ReplaceNoCase( sql, ":" & name, _sqlLiteralFromParam( arguments.params[ name ] ), "all" );
			}
		} else if ( IsArray( arguments.params ) ) {
			var named = Duplicate( arguments.params );
			ArraySort( named, function( a, b ){
				return Len( b.name ?: "" ) - Len( a.name ?: "" );
			} );
			for( var def in named ) {
				if ( Len( Trim( def.name ?: "" ) ) ) {
					sql = ReplaceNoCase( sql, ":" & def.name, _sqlLiteralFromParam( def ), "all" );
				}
			}
		}

		return sql;
	}

	private string function _sqlLiteralFromParam( required any param ) {
		var value = arguments.param;
		var type  = "";

		if ( IsStruct( arguments.param ) ) {
			value = arguments.param.value ?: "";
			type  = arguments.param.type  ?: "";
		}

		if ( !Len( Trim( ToString( value ) ) ) && value != 0 && value != false ) {
			return "null";
		}
		if ( ReFindNoCase( "int|numeric|decimal|float|double|bit|boolean", type ) || ( !Len( type ) && IsNumeric( value ) && !IsDate( value ) ) ) {
			return ToString( Val( value ) );
		}

		return _sqlString( ToString( value ) );
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

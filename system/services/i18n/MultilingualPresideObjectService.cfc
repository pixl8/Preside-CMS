/**
 * This service exists to provide APIs that make providing support for multilingual
 * translations of standard preside objects possible in a transparent way. Note: You are
 * unlikely to need to deal with this API directly.
 *
 * @displayName Multilingual Preside Object Service
 * @singleton   true
 * @autodoc     true
 */
component {

// CONSTRUCTOR
	/**
	 * @relationshipGuidance.inject relationshipGuidance
	 *
	 */
	public any function init( required any relationshipGuidance ) {
		_setRelationshipGuidance( arguments.relationshipGuidance );
		_setMultiLingualObjectReference( {} );

		return this;
	}

// PUBLIC METHODS
	public boolean function isMultilingual( required string objectName, string propertyName="" ) {
		var multiLingualObjectReference = _getMultiLingualObjectReference();

		if ( !multiLingualObjectReference.keyExists( arguments.objectName ) ) {
			return false;
		}

		return !Len( Trim( arguments.propertyName ) ) || multiLingualObjectReference[ arguments.objectName ].findNoCase( arguments.propertyName );
	}

	public void function addTranslationObjectsForMultilingualEnabledObjects( required struct objects ) {
		var multiLingualObjectReference = {};

		for( var objectName in arguments.objects ){
			var object = arguments.objects[ objectName ];

			if ( _isObjectMultilingual( object.meta ?: {} ) ) {

				arguments.objects[ "_translation_" & objectName ] = createTranslationObject( objectName, object );
				decorateMultilingualObject( objectName, object );
				multiLingualObjectReference[ objectName ] = _listMultilingualObjectProperties( object.meta );
			}
		}

		_setMultiLingualObjectReference( multiLingualObjectReference );
	}

	public struct function createTranslationObject( required string objectName, required struct sourceObject ) {
		var translationObject     = Duplicate( arguments.sourceObject.meta );
		var translationProperties = translationObject.properties ?: {};
		var dbFieldList           = ListToArray( translationObject.dbFieldList ?: "" );
		var propertyNames         = translationObject.propertyNames ?: [];
		var validProperties       = _listMultilingualObjectProperties( arguments.sourceObject.meta ?: {} );

		validProperties.append( "id" );
		validProperties.append( "datecreated" );
		validProperties.append( "datemodified" );

		translationObject.tableName = "_translation_" & ( arguments.sourceObject.meta.tableName ?: "" );

		for( var propertyName in translationProperties ) {
			if ( !validProperties.find( propertyName ) ) {
				translationProperties.delete( propertyName );
				dbFieldList.delete( propertyName );
				propertyNames.delete( propertyName );
			}
		}

		translationProperties._translation_source_record = new preside.system.services.presideobjects.Property(
			  relationship  = "many-to-one"
			, relatedto     = arguments.objectName
			, required      = true
			, uniqueindexes = "translation|1"
			, indexes       = ""
			, ondelete      = "cascade"
			, onupdate      = "cascade"
			, generator     = "none"
		);
		dbFieldList.append( "_translation_source_record" );
		propertyNames.append( "_translation_source_record" );

		translationProperties._translation_language = new preside.system.services.presideobjects.Property(
			  required      = true
			, type          = "string"
			, dbtype        = "varchar"
			, maxlength     = 8
			, uniqueindexes = "translation|2"
			, indexes       = ""
			, relationship  = "none"
			, relatedto     = "none"
			, generator     = "none"
		);

		dbFieldList.append( "_translation_language" );
		propertyNames.append( "_translation_language" );

		translationObject.dbFieldList   = dbFieldList.toList();
		translationObject.propertyNames = propertyNames;

		translationObject.indexes       = translationObject.indexes ?: {};
		translationObject.indexes[ "ux_translation_" & arguments.objectName & "_translation" ] = { unique=true, fields="_translation_source_record,_translation_language" };

		return { meta=translationObject, instance="auto_created" };
	}

	public void function decorateMultilingualObject( required string objectName, required struct object ) {
		arguments.object.meta.properties = arguments.object.meta.properties ?: {};

		arguments.object.meta.properties._translations = new preside.system.services.presideobjects.Property(
			  relationship    = "one-to-many"
			, relatedto       = "_translation_" & arguments.objectName
			, relationshipKey = "_translation_source_record"
			, required        = false
			, uniqueindexes   = ""
			, indexes         = ""
			, generator       = "none"
		);
	}

	public void function mixinTranslationSpecificSelectLogicToSelectDataCall( required string objectName, required array selectFields, required array extraFilters, required any adapter ) {
		for( var i=1; i <= arguments.selectFields.len(); i++ ) {
			var field = arguments.selectFields[ i ];
			var resolved = _resolveSelectField( arguments.objectName, field );

			if ( !resolved.isEmpty() && isMultilingual( resolved.objectName, resolved.propertyName ) ) {
				arguments.selectFields[ i ] = _transformSelectFieldToGetTranslationIfExists( arguments.objectName, resolved.selector, resolved.alias, arguments.adapter );
			}
		}
	}

	public void function addLanguageClauseToTranslationJoins( required array tableJoins, required string language, required struct preparedFilter ) {

		for( var i=1; i <= arguments.tableJoins.len(); i++ ){
			if ( ListLast( arguments.tableJoins[ i ].tableAlias, "$" ) == "_translations" ) {
				if ( arguments.tableJoins[ i ].keyExists( "additionalClauses" ) ) {
					 arguments.tableJoins[ i ].additionalClauses &= " and #arguments.tableJoins[ i ].tableAlias#._translation_language = :_translation_language";
				} else {
					 arguments.tableJoins[ i ].additionalClauses = "#arguments.tableJoins[ i ].tableAlias#._translation_language = :_translation_language";
				}

				arguments.preparedFilter.params.append( { name="_translation_language", type="varchar", value=arguments.language } );
			}
		}

	}

// PRIVATE HELPERS
	private boolean function _isObjectMultilingual( required struct objectMeta ) {
		var multilingualFlag = arguments.objectMeta.multilingual ?: "";

		return IsBoolean( multilingualFlag ) && multilingualFlag;
	}

	private array function _listMultilingualObjectProperties( required struct objectMeta ) {
		var multilingualProperties = [];
		var objectProperties       = arguments.objectMeta.properties ?: {};

		for( var propertyName in objectProperties ) {
			var property = objectProperties[ propertyName ];
			if ( IsBoolean( property.multilingual ?: "" ) && property.multilingual ) {
				multilingualProperties.append( propertyName );
			}
		}

		return multilingualProperties;
	}

	private struct function _resolveSelectField( required string sourceObject, required string selectField ) {
		var fieldRegex       = "^[_a-zA-Z][_a-zA-Z0-9\$]*\.[_a-zA-Z][_a-zA-Z0-9]*$";
		var selectFieldParts = ListToArray( selectField, " " );

		if ( !selectFieldParts.len() || !ReFind( fieldRegex, selectFieldParts[ 1 ] ) || selectFieldParts.len() > 3 || ( selectFieldParts.len() == 3 && selectFieldParts[ 2 ] != "as" ) ) {
			return {};
		}

		var selector     = selectFieldParts[ 1 ];
		var propertyName = ListLast( selector, "." );
		var objectPath   = ListFirst( selector, "." );
		var objectName   = _getRelationshipGuidance().resolveRelationshipPathToTargetObject( arguments.sourceObject, objectPath );


		if ( !objectName.len() ) {
			return {};
		}

		return {
			  objectName   = objectName
			, propertyName = propertyName
			, selector     = selector
			, alias        = selectFieldParts.len() == 1 ? propertyName : selectFieldParts[ selectFieldParts.len() ]
		}
	}

	private string function _transformSelectFieldToGetTranslationIfExists( required string objectName, required string selector, required string alias, required any dbAdapter ) {
		var translationsObjectSelector = _getTranslatedObjectRelationshipPath( arguments.objectName, ListFirst( arguments.selector, "." ) );
		var translationSelector        = translationsObjectSelector & "." & ListRest( arguments.selector, "." );

		return dbAdapter.getIfNullStatement( translationSelector, arguments.selector, arguments.alias );
	}

	private string function _getTranslatedObjectRelationshipPath( required string objectName, required string plainObjectPath ) {
		if ( arguments.plainObjectPath == arguments.objectName ) {
			return "_translations";
		}

		return arguments.plainObjectPath & "$_translations";
	}

// GETTERS AND SETTERS
	private struct function _getMultiLingualObjectReference() {
		return _multiLingualObjectReference;
	}
	private void function _setMultiLingualObjectReference( required struct multiLingualObjectReference ) {
		_multiLingualObjectReference = arguments.multiLingualObjectReference;
	}

	private any function _getRelationshipGuidance() {
		return _relationshipGuidance;
	}
	private void function _setRelationshipGuidance( required any relationshipGuidance ) {
		_relationshipGuidance = arguments.relationshipGuidance;
	}

}
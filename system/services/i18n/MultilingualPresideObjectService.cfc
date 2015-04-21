/**
 * This service exists to provide APIs that make providing support for multilingual
 * translations of standard preside objects possible in a transparent way. Note: You are
 * unlikely to need to deal with this API directly.
 *
 * @displayName Multilingual Preside Object Service
 */
component autodoc=true {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC METHODS
	public void function addTranslationObjectsForMultilingualEnabledObjects( required struct objects ) {
		for( var objectName in arguments.objects ){
			var object = arguments.objects[ objectName ];

			if ( isObjectMultilingual( object.meta ?: {} ) ) {

				arguments.objects[ "_translation_" & objectName ] = createTranslationObject( objectName, object );
				decorateMultilingualObject( objectName, object );
			}
		}
	}

	public boolean function isObjectMultilingual( required struct objectMeta ) {
		var multiLingualFlag = arguments.objectMeta.multilingual ?: "";

		return IsBoolean( multiLingualFlag ) && multiLingualFlag;
	}

	public array function listMultilingualObjectProperties( required struct objectMeta ) {
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

	public struct function createTranslationObject( required string objectName, required struct sourceObject ) {
		var translationObject     = Duplicate( arguments.sourceObject.meta );
		var translationProperties = translationObject.properties ?: {};
		var dbFieldList           = ListToArray( translationObject.dbFieldList ?: "" );
		var propertyNames         = translationObject.propertyNames ?: [];
		var validProperties       = listMultilingualObjectProperties( arguments.sourceObject.meta ?: {} );

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


}
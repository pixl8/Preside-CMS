/**
 * This service exists to provide APIs that make providing support for multilingual
 * translations of standard preside objects possible in a transparent way. Note: You are
 * unlikely to need to deal with this API directly.
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="Multilingual Preside Object Service" {

// CONSTRUCTOR
	/**
	 * @relationshipGuidance.inject relationshipGuidance
	 * @cookieService.inject        cookieService
	 */
	public any function init( required any relationshipGuidance, required any cookieService ) {
		_setRelationshipGuidance( arguments.relationshipGuidance );
		_setCookieService( arguments.cookieService );
		_setMultiLingualObjectReference( {} );

		return this;
	}

// PUBLIC METHODS

	/**
	 * Returns whether or not the given object and optional property are multilingual
	 * enabled.
	 *
	 * @autodoc           true
	 * @objectName.hint   Name of the object that we wish to check
	 * @propertyName.hint Optional name of the property that we wish to check
	 */
	public boolean function isMultilingual( required string objectName, string propertyName="" ) {
		var multiLingualObjectReference = _getMultiLingualObjectReference();

		if ( !StructKeyExists( multiLingualObjectReference, arguments.objectName ) ) {
			return false;
		}

		return !Len( Trim( arguments.propertyName ) ) || multiLingualObjectReference[ arguments.objectName ].findNoCase( arguments.propertyName );
	}

	/**
	 * Performs the magic of creating extra database tables (preside objects) to store the
	 * translations of multilingual enabled objects.
	 *
	 * @autodoc      true
	 * @objects.hint Objects as compiled and read by the preside object service.
	 */
	public void function addTranslationObjectsForMultilingualEnabledObjects( required struct objects ) {
		var multiLingualObjectReference = {};

		for( var objectName in arguments.objects ){
			var object = arguments.objects[ objectName ];

			if ( _isObjectMultilingual( object.meta ?: {} ) ) {

				arguments.objects[ _getTranslationObjectPrefix() & objectName ] = createTranslationObject( objectName, object );
				decorateMultilingualObject( objectName, object );
				multiLingualObjectReference[ objectName ] = _listMultilingualObjectProperties( object.meta );
			}
		}

		_setMultiLingualObjectReference( multiLingualObjectReference );
	}

	/**
	 * Returns the meta data for our auto generated translation object based on a given
	 * source object
	 *
	 * @autodoc           true
	 * @objectName.hint   The name of the source object
	 * @sourceObject.hint The metadata of the source object
	 */
	public struct function createTranslationObject( required string objectName, required struct sourceObject ) {
		var translationObject     = Duplicate( arguments.sourceObject.meta );
		var translationProperties = translationObject.properties ?: {};
		var dbFieldList           = ListToArray( translationObject.dbFieldList ?: "" );
		var propertyNames         = translationObject.propertyNames ?: [];
		var validProperties       = _listMultilingualObjectProperties( arguments.sourceObject.meta ?: {} );
		var extraLanguageIndexes  = "";

		validProperties.append( "id" );
		if ( !( arguments.sourceObject.meta.noDateCreated ?: false ) ) {
			validProperties.append( "datecreated" );
		}
		if ( !( arguments.sourceObject.meta.noDateModified ?: false ) ) {
			validProperties.append( "datemodified" );
		}

		translationObject.tableName    = _getTranslationObjectPrefix() & ( arguments.sourceObject.meta.tableName ?: "" );
		translationObject.derivedFrom  = arguments.objectName;
		translationObject.siteFiltered = false;
		translationObject.tenant       = "";
		translationObject.isPageType   = false;

		for( var propertyName in translationProperties ) {
			if ( !validProperties.findNoCase( propertyName ) ) {
				StructDelete( translationProperties, propertyName );

				if ( dbFieldList.findNoCase( propertyName ) ) {
					ArrayDeleteAt( dbFieldList, dbFieldList.findNoCase( propertyName )  );
				}
				if ( propertyNames.findNoCase( propertyName ) ) {
					ArrayDeleteAt( propertyNames, propertyNames.findNoCase( propertyName )  );
				}

				continue;
			}

			var prop = translationProperties[ propertyName ];

			if ( Len( Trim( prop.uniqueindexes ?: "" ) ) ) {
				var newIndexDefinition = "";

				for( var ix in ListToArray( prop.uniqueindexes ) ) {
					var languageIndexName = ListFirst( ix, "|" ) & "|1";

					if ( !ListFindNoCase( extraLanguageIndexes, languageIndexName ) ) {
						extraLanguageIndexes = ListAppend( extraLanguageIndexes, languageIndexName );
					}

					if ( ListLen( ix, "|" ) > 1 ) {
						newIndexDefinition = ListAppend( newIndexDefinition, ListFirst( ix, "|" ) & "|" & Val( ListRest( ix, "|" ) )+1 );
					} else {
						newIndexDefinition = ListAppend( newIndexDefinition, ix & "|2" );
					}
				}

				prop.uniqueindexes = newIndexDefinition;
			}
		}
		if ( Len( Trim( extraLanguageIndexes ) ) ) {
			extraLanguageIndexes = "," & extraLanguageIndexes;
		}

		translationProperties._translation_source_record = {
			  name          = "_translation_source_record"
			, relationship  = "many-to-one"
			, relatedto     = arguments.objectName
			, required      = true
			, uniqueindexes = "translation|1"
			, indexes       = ""
			, ondelete      = "cascade"
			, onupdate      = "cascade"
			, generator     = "none"
			, control       = "none"
		};
		dbFieldList.append( "_translation_source_record" );
		propertyNames.append( "_translation_source_record" );

		translationProperties._translation_language = {
			  name          = "_translation_language"
			, relationship  = "many-to-one"
			, relatedto     = "multilingual_language"
			, required      = true
			, uniqueindexes = "translation|2" & extraLanguageIndexes
			, indexes       = ""
			, ondelete      = "error"
			, onupdate      = "cascade"
			, generator     = "none"
			, control       = "none"
		};
		dbFieldList.append( "_translation_language" );
		propertyNames.append( "_translation_language" );

		translationObject.dbFieldList   = dbFieldList.toList();
		translationObject.propertyNames = propertyNames;

		translationObject.indexes       = translationObject.indexes ?: {};
		for( var indexName in translationObject.indexes ) {
			for( var indexField in translationObject.indexes[ indexName ].fields.listToArray() ) {
				if ( !dbFieldList.findNoCase( indexField ) ) {
					translationObject.indexes.delete( indexName );
					break;
				}
			}

			if ( StructKeyExists( translationObject.indexes, indexName ) && translationObject.indexes[ indexName ].unique ) {
				translationObject.indexes[ indexName ].fields = "_translation_language," & translationObject.indexes[ indexName ].fields;
			}
		}
		translationObject.indexes[ "ux_translation_" & arguments.objectName & "_translation" ] = { unique=true, fields="_translation_source_record,_translation_language" };

		return { meta=translationObject, instance="auto_created" };
	}

	/**
	 * Adds utility properties to the multilingual enabled source object
	 * so that its translations can be easily queried
	 *
	 * @autodoc         true
	 * @objectName.hint The name of the source object
	 * @object.hint     The metadata of the source object
	 */
	public void function decorateMultilingualObject( required string objectName, required struct object ) {
		arguments.object.meta.properties = arguments.object.meta.properties ?: {};

		arguments.object.meta.properties._translations = {
			  name            = "_translations"
			, relationship    = "one-to-many"
			, relatedto       = _getTranslationObjectPrefix() & arguments.objectName
			, relationshipKey = "_translation_source_record"
			, required        = false
			, uniqueindexes   = ""
			, indexes         = ""
			, generator       = "none"
			, control         = "none"
			, adminRenderer   = "none"
		};
	}

	/**
	 * Works on intercepted select queries to discover and replace multilingual
	 * select fields with special IfNull( translation, original ) syntax
	 * to automagically select translations without the developer having to
	 * do anything about it
	 *
	 * @autodoc           true
	 * @objectName.hint   The name of the source object
	 * @selectFields.hint Array of select fields as passed into the presideObjectService.selectData() method
	 */
	public void function mixinTranslationSpecificSelectLogicToSelectDataCall( required string objectName, required array selectFields ) {
		var adapter = $getPresideObjectService().getDbAdapterForObject( arguments.objectName );

		for( var i=1; i <= arguments.selectFields.len(); i++ ) {
			var field = arguments.selectFields[ i ];
			var resolved = _resolveSelectField( arguments.objectName, field );

			if ( !resolved.isEmpty() && isMultilingual( resolved.objectName, resolved.propertyName ) ) {
				arguments.selectFields[ i ] = _transformSelectFieldToGetTranslationIfExists( arguments.objectName, resolved.selector, resolved.alias, adapter );
			}
		}
	}

	/**
	 * Works on intercepted select queries to discover and decorate
	 * joins on translation objects with an additional clause for the
	 * passed in language
	 *
	 * @autodoc             true
	 * @tableJoins.hint     Array of table joins as calculated by the SelectData() logic
	 * @joins.hint          Array of raw joins as calculated by the SelectData() logic that match the table joins
	 * @language.hint       The language to filter on
	 * @preparedFilter.hint The fully prepared and resolved filter that will be used in the select query
	 */
	public void function addLanguageClauseToTranslationJoins( required array tableJoins, required string language, required struct preparedFilter, boolean fromVersionTable=false ) {
		for( var i=1; i <= arguments.tableJoins.len(); i++ ){
			if ( ListLast( arguments.tableJoins[ i ].tableAlias, "$" ) == "_translations" ) {

				if ( StructKeyExists( arguments.tableJoins[ i ], "additionalClauses" ) ) {
					arguments.tableJoins[ i ].additionalClauses &= " and #arguments.tableJoins[ i ].tableAlias#._translation_language = :_translation_language";
				} else {
					arguments.tableJoins[ i ].additionalClauses = "#arguments.tableJoins[ i ].tableAlias#._translation_language = :_translation_language";
				}

				if ( !$getRequestContext().showNonLiveContent() ) {
					var joinTarget = arguments.joins[ i ].joinToObject ?: "";
					if ( joinTarget.len() && $getPresideObjectService().objectIsVersioned( joinTarget ) ) {
						arguments.tableJoins[ i ].additionalClauses &= " and ( #arguments.tableJoins[ i ].tableAlias#._version_is_draft is null or #arguments.tableJoins[ i ].tableAlias#._version_is_draft = '0' )";
					}
				}

				arguments.tableJoins[ i ].type = "left";

				arguments.preparedFilter.params.append( { name="_translation_language", type="varchar", value=arguments.language } );

				if ( arguments.fromVersionTable ) {
					arguments.tableJoins[ i ].tableName = "_version_" & arguments.tableJoins[ i ].tableName;
				}
			}
		}
	}

	/**
	 * Works on intercepted select queries to add versioning clauses to translation
	 * table joins
	 *
	 * @autodoc
	 *
	 */
	public void function addVersioningClausesToTranslationJoins( required struct selectDataArgs ) {

		if ( !selectDataArgs.specificVersion ) {
			var poService          = $getPresideObjectService();
			var versionedObject    = selectDataArgs.objectName;

			if ( !isMultilingual( selectDataArgs.objectName ) ) {
				if ( poService.isPageType( selectDataArgs.objectName ) && isMultilingual( "page" ) ) {
					versionedObject = "page";
				} else {
					return;
				}
			}

			var versionObjectName  = poService.getVersionObjectName( getTranslationObjectName( versionedObject ) );
			var tableName          = poService.getObjectAttribute( versionObjectName, "tablename", "" );


			for( var i=selectDataArgs.joins.len(); i>0; i-- ) {
				var join             = selectDataArgs.joins[i];
				var latestCheckField = IsBoolean( selectDataArgs.allowDraftVersions ?: "" ) && selectDataArgs.allowDraftVersions ? "_version_is_latest_draft" : "_version_is_latest";

				if ( join.tableAlias contains "_translations" && join.tableName.reFindNoCase( "^_version" ) ) {
					join.additionalClauses &= " and #join.tableAlias#.#latestCheckField# = '1'";
				}
			}
		}
	}

	/**
	 * Returns an array of actively supported languages. Each language
	 * is represented as a struct with id, name, native_name, iso_code and default keys
	 *
	 * @includeDefault.hint Whether or not to include the default language in the array
	 * @autoDoc             true
	 */
	public array function listLanguages( boolean includeDefault=true ) {
		var settings        = $getPresideCategorySettings( "multilingual" );
		var defaultLanguage = settings.default_language ?: "";
		var languageIds     = ListToArray( settings.additional_languages ?: "" );
		var languages       = [];

		if ( arguments.includeDefault && defaultLanguage.len() ) {
			languageIds.prepend( defaultLanguage );
		}

		var dbRecords = _getLanguageDao().selectData( filter={ id=languageIds } );

		for( var record in dbRecords ) {
			record.default = record.id == defaultLanguage;
			record.sortOrder = languageIds.find( record.id );
			languages.append( record );
		}

		languages.sort( function( a, b ){
			return a.sortorder > b.sortorder ? 1 : -1;
		} );

		return languages;
	}

	/**
	 * Returns an array of actively supported languages as per listLanguages()
	 * with an additional 'status' field indicating the status of the translation
	 * for the given object record
	 *
	 * @objectName.hint Name of the object that has the record we wish to get the translation status of
	 * @recordId.hint   ID of the record we wish to get the translation status of
	 * @autoDoc         true
	 */
	public array function getTranslationStatus( required string objectName, required string recordId ) {
		var languages         = listLanguages( includeDefault=false );
		var objectIsVersioned = $getPresideObjectService().objectIsVersioned( arguments.objectName );
		var selectFields      = objectIsVersioned ? [ "_translation_language", "_version_is_draft", "_version_has_drafts" ] : [ "_translation_language" ];
		var dbRecords         = $getPresideObjectService().selectData(
			  objectName         = _getTranslationObjectPrefix() & objectName
			, selectFields       = selectFields
			, filter             = { _translation_source_record = arguments.recordId }
			, allowDraftVersions = true
		);
		var mappedRecords = {};

		for( var record in dbRecords ){
			if ( objectIsVersioned ) {
				mappedrecords[ record._translation_language ] = ( !IsBoolean( record._version_is_draft ) || !record._version_is_draft ) && ( !IsBoolean( record._version_has_drafts ) || !record._version_has_drafts );
			} else {
				mappedrecords[ record._translation_language ] = true;
			}
		}

		for( var language in languages ) {
			if ( StructKeyExists( mappedRecords, language.id ) ) {
				language.status = mappedRecords[ language.id ] ? "active" : "inprogress";
			} else {
				language.status = "notstarted";
			}
		}

		return languages;
	}

	/**
	 * Returns a structure of language details for the given language.
	 * If the language is not an actively translatable language,
	 * an empty structure will be returned.
	 *
	 * @languageId.hint ID of the language to get
	 * @autodoc         true
	 *
	 */
	public struct function getLanguage( required string languageId ) {
		var languages = listLanguages();
		for( var language in languages ) {
			if ( language.id == arguments.languageId ) {
				return language;
			}
		}

		return {};
	}

	/**
	 * Returns the name of the given object's corresponding translation object
	 *
	 * @objectName.hint Name of the object whose corresponding translation object name we wish to get
	 * @autodoc         true
	 *
	 */
	public string function getTranslationObjectName( required string sourceObjectName ) {
		return _getTranslationObjectPrefix() & arguments.sourceObjectName;
	}

	/**
	 * Returns the equivalent translation record
	 * for the given object record (object name and id)
	 * and language
	 *
	 * @autodoc
	 *
	 */
	public query function selectTranslation( required string objectName, required string id, required string languageId, array selectFields=[], string version="", boolean useCache=true ) {
		var translationObjectName = getTranslationObjectName( arguments.objectName );
		var filter                = { _translation_source_record=arguments.id, _translation_language=arguments.languageId };
		var presideObjectService  = $getPresideObjectService();
		var args                  = {
			  objectName         = translationObjectName
			, filter             = filter
			, selectFields       = arguments.selectFields
			, allowDraftVersions = true
		};

		if ( !arguments.useCache ) {
			args.useCache = false;
		}

		if ( Val( arguments.version ) ) {
			args.fromVersionTable = true;
			args.specificVersion  = arguments.version;
		}

		return presideObjectService.selectData( argumentCollection=args );
	}

	/**
	 * Saves a translation record for a given preside object
	 * and record ID
	 *
	 * @autodoc
	 * @objectName.hint Name of the object whose record we are to save the translation for
	 * @id.hint         ID of the record we are to save the translation for
	 * @languageId.hint ID of the language that the translation is for
	 * @data.hint       Structure of data containing to save in the translation record
	 *
	 */
	public string function saveTranslation(
 		  required string  objectName
		, required string  id
		, required string  languageId
		, required struct  data
		,          boolean isDraft = false
	){
		var returnValue = "";

		transaction {
			var translationObjectName = getTranslationObjectName( arguments.objectName );
			var existingId            = getExistingTranslationId( argumentCollection=arguments );

			if ( existingId.len() ) {
				returnValue = existingId;
				$getPresideObjectService().updateData(
					  objectName              = translationObjectName
					, id                      = existingId
					, data                    = arguments.data
					, updateManyToManyRecords = true
					, isDraft                 = arguments.isDraft
				);
			} else {
				var newRecordData = Duplicate( arguments.data );
				    newRecordData._translation_source_record = arguments.id;
				    newRecordData._translation_language      = arguments.languageId;

				returnValue = $getPresideObjectService().insertData(
					  objectName              = translationObjectName
					, data                    = newRecordData
					, insertManyToManyRecords = true
					, isDraft                 = arguments.isDraft
				);
			}
		}

		return returnValue;
	}

	public string function getExistingTranslationId(
		  required string objectName
		, required string id
		, required string languageId
	) {
		var existing = selectTranslation(
			  objectName   = arguments.objectName
			, id           = arguments.id
			, languageId   = arguments.languageId
			, selectFields = [ "id" ]
		);

		return existing.id ?: "";
	}

	/**
	 * Returns a query record for the detected language
	 * for this request.
	 *
	 * @autodoc
	 * @localeSlug.hint locale detected in URL
	 *
	 */
	public query function getDetectedRequestLanguage( required string localeSlug ) {
		var languageObj  = $getPresideObject( "multilingual_language" );
		var validateLang = function( required query lang ){
			var multilingualSettings = $getPresideCategorySettings( "multilingual" );
			var configuredLanguages  = ListToArray( ListAppend( multilingualSettings.additional_languages ?: "", multilingualSettings.default_language ?: "" ) );

			return configuredLanguages.findNoCase( lang.id ) ? lang : QueryNew( 'id,slug' );
		}

		if ( Len( Trim( arguments.localeSlug ) ) ) {
			var languageFromSlug = languageObj.selectData( filter={ slug=arguments.localeSlug } );

			if ( languageFromSlug.recordCount ) {
				return validateLang( languageFromSlug );
			}
		}

		var languageFromCookie = _getCookieService().getVar( "_preside_language", "" );
		if ( Len( Trim( languageFromCookie ) ) ) {
			languageFromCookie = languageObj.selectData( id=languageFromCookie );
			if ( languageFromCookie.recordCount ) {
				return validateLang( languageFromCookie );
			}
		}

		var languageFromAcceptHeader = ListToArray( cgi.http_accept_language ?: "", ";" );
		if ( languageFromAcceptHeader.len() ) {
			for( var isoCode in languageFromAcceptHeader ) {
				if ( !isNumeric( isoCode ) ) {
					var languageFromIsoCode = languageObj.selectData( filter={ iso_code = isoCode } );
					if ( languageFromIsoCode.recordCount ) {
						return validateLang( languageFromIsoCode );
					}
				}
			}
		}

		var defaultLanguage = $getPresideSetting( "multilingual", "default_language" );
		if ( defaultLanguage.len() ) {
			return validateLang( languageObj.selectData( id=defaultLanguage ) );
		}

		return QueryNew('id,slug');
	}

	/**
	 * Persists the user's language choice so that it can be used
	 * as the default language when it is unclear from the request
	 * what language to use.
	 *
	 * @autodoc
	 * @languageId.hint The ID of the language to persist
	 *
	 */
	public void function persistUserLanguage( required string languageId ) {
		_getCookieService().setVar( name="_preside_language", value=arguments.languageId );
	}

	/**
	 * Populates an empty language database with core
	 * pre-defined languages (see getDefaultLanguageSet())
	 *
	 */
	public void function populateCoreLanguageSet() {
		var dao                   = _getLanguageDao();
		var languagesAlreadyExist = dao.dataExists();

		if ( !languagesAlreadyExist ) {
			var languages = getDefaultLanguageSet();

			for( var language in languages ) {
				dao.insertData( {
					  id            = language.iso_code
					, slug          = ReReplace( LCase( language.iso_code ), "[\W_]", "-", "all" )
					, iso_code      = language.iso_code
					, name          = language.name
					, native_name   = language.native_name
					, right_to_left = language.rtl
				} );
			}
		}
	}

	/**
	 * Returns an array of hardcoded default languages that the system
	 * will start up with. This could be a useful method to override should
	 * you wish to supplement the default languages, etc.
	 *
	 * @autodoc
	 */
	public array function getDefaultLanguageSet() {
		return [
			  { "name":"Afrikaans"                    , "iso_code":"af"        , "rtl":false, "native_name":"Afrikaans" }
			, { "name":"Albanian"                     , "iso_code":"sq"        , "rtl":false, "native_name":"shqip" }
			, { "name":"Amharic"                      , "iso_code":"am"        , "rtl":false, "native_name":"አማርኛ" }
			, { "name":"Angika"                       , "iso_code":"anp"       , "rtl":false, "native_name":"Angika" }
			, { "name":"Arabic"                       , "iso_code":"ar"        , "rtl":true , "native_name":"العربية" }
			, { "name":"Armenian"                     , "iso_code":"hy"        , "rtl":false, "native_name":"Հայերէն" }
			, { "name":"Assamese"                     , "iso_code":"as"        , "rtl":false, "native_name":"অসমীয়া" }
			, { "name":"Asturian"                     , "iso_code":"ast"       , "rtl":false, "native_name":"Asturian" }
			, { "name":"Azerbaijani"                  , "iso_code":"az"        , "rtl":false, "native_name":"azərbaycanca" }
			, { "name":"Basque"                       , "iso_code":"eu"        , "rtl":false, "native_name":"euskara" }
			, { "name":"Bengali (Bangladesh)"         , "iso_code":"bn_BD"     , "rtl":false, "native_name":"বাংলা (বাংলাদেশ)" }
			, { "name":"Bengali (India)"              , "iso_code":"bn_IN"     , "rtl":false, "native_name":"বাংলা (ভারত)" }
			, { "name":"Bodo"                         , "iso_code":"brx"       , "rtl":false, "native_name":"बड़ो" }
			, { "name":"Bosnian"                      , "iso_code":"bs"        , "rtl":false, "native_name":"bosanski" }
			, { "name":"Breton"                       , "iso_code":"br"        , "rtl":false, "native_name":"brezhoneg" }
			, { "name":"Bulgarian"                    , "iso_code":"bg"        , "rtl":false, "native_name":"български" }
			, { "name":"Catalan"                      , "iso_code":"ca"        , "rtl":false, "native_name":"català" }
			, { "name":"Chinese (China)"              , "iso_code":"zh_CN"     , "rtl":false, "native_name":"中文（中国）" }
			, { "name":"Chinese (Hong Kong SAR China)", "iso_code":"zh_HK"     , "rtl":false, "native_name":"中文（中華人民共和國香港特別行政區）" }
			, { "name":"Chinese (Simplified, China)"  , "iso_code":"zh_Hans_CN", "rtl":false, "native_name":"中文（简体中文、中国）" }
			, { "name":"Chinese (Taiwan)"             , "iso_code":"zh_TW"     , "rtl":false, "native_name":"中文（台灣）" }
			, { "name":"Chinese (Traditional, Taiwan)", "iso_code":"zh_Hant_TW", "rtl":false, "native_name":"中文（繁體中文，台灣）" }
			, { "name":"Cornish"                      , "iso_code":"kw"        , "rtl":false, "native_name":"kernewek" }
			, { "name":"Croatian"                     , "iso_code":"hr"        , "rtl":false, "native_name":"hrvatski" }
			, { "name":"Czech"                        , "iso_code":"cs"        , "rtl":false, "native_name":"čeština" }
			, { "name":"Danish"                       , "iso_code":"da"        , "rtl":false, "native_name":"dansk" }
			, { "name":"Dogri"                        , "iso_code":"doi"       , "rtl":false, "native_name":"Dogri" }
			, { "name":"Dutch"                        , "iso_code":"nl"        , "rtl":false, "native_name":"Nederlands" }
			, { "name":"English"                      , "iso_code":"en"        , "rtl":false, "native_name":"English" }
			, { "name":"English (Australia)"          , "iso_code":"en_AU"     , "rtl":false, "native_name":"English (Australia)" }
			, { "name":"English (Canada)"             , "iso_code":"en_CA"     , "rtl":false, "native_name":"English (Canada)" }
			, { "name":"English (United Kingdom)"     , "iso_code":"en_GB"     , "rtl":false, "native_name":"English (United Kingdom)" }
			, { "name":"English (United States)"      , "iso_code":"en_US"     , "rtl":false, "native_name":"English (United States)" }
			, { "name":"Esperanto"                    , "iso_code":"eo"        , "rtl":false, "native_name":"esperanto" }
			, { "name":"Estonian"                     , "iso_code":"et"        , "rtl":false, "native_name":"eesti" }
			, { "name":"Finnish"                      , "iso_code":"fi"        , "rtl":false, "native_name":"suomi" }
			, { "name":"French"                       , "iso_code":"fr"        , "rtl":false, "native_name":"français" }
			, { "name":"French (Canada)"              , "iso_code":"fr_CA"     , "rtl":false, "native_name":"français (Canada)" }
			, { "name":"Galician"                     , "iso_code":"gl"        , "rtl":false, "native_name":"galego" }
			, { "name":"Georgian"                     , "iso_code":"ka"        , "rtl":false, "native_name":"ქართული" }
			, { "name":"German"                       , "iso_code":"de"        , "rtl":false, "native_name":"Deutsch" }
			, { "name":"German (Germany)"             , "iso_code":"de_DE"     , "rtl":false, "native_name":"Deutsch (Deutschland)" }
			, { "name":"German (Switzerland)"         , "iso_code":"de_CH"     , "rtl":false, "native_name":"Deutsch (Schweiz)" }
			, { "name":"Greek"                        , "iso_code":"el"        , "rtl":false, "native_name":"Ελληνικά" }
			, { "name":"Gujarati"                     , "iso_code":"gu"        , "rtl":false, "native_name":"ગુજરાતી" }
			, { "name":"Haitian"                      , "iso_code":"ht"        , "rtl":false, "native_name":"Haitian" }
			, { "name":"Hebrew"                       , "iso_code":"he"        , "rtl":true , "native_name":"עברית" }
			, { "name":"Hindi"                        , "iso_code":"hi"        , "rtl":false, "native_name":"हिन्दी" }
			, { "name":"Hungarian"                    , "iso_code":"hu"        , "rtl":false, "native_name":"magyar" }
			, { "name":"Icelandic"                    , "iso_code":"is"        , "rtl":false, "native_name":"íslenska" }
			, { "name":"Indonesian"                   , "iso_code":"id"        , "rtl":false, "native_name":"Bahasa Indonesia" }
			, { "name":"Interlingua"                  , "iso_code":"ia"        , "rtl":false, "native_name":"Interlingua" }
			, { "name":"Irish"                        , "iso_code":"ga"        , "rtl":false, "native_name":"Gaeilge" }
			, { "name":"Italian"                      , "iso_code":"it"        , "rtl":false, "native_name":"italiano" }
			, { "name":"Japanese"                     , "iso_code":"ja"        , "rtl":false, "native_name":"日本語" }
			, { "name":"Kannada"                      , "iso_code":"kn"        , "rtl":false, "native_name":"ಕನ್ನಡ" }
			, { "name":"Kazakh"                       , "iso_code":"kk"        , "rtl":false, "native_name":"қазақ тілі" }
			, { "name":"Kirghiz"                      , "iso_code":"ky"        , "rtl":false, "native_name":"Kirghiz" }
			, { "name":"Konkani"                      , "iso_code":"kok"       , "rtl":false, "native_name":"कोंकणी" }
			, { "name":"Korean"                       , "iso_code":"ko"        , "rtl":false, "native_name":"한국어" }
			, { "name":"Kurdish"                      , "iso_code":"ku"        , "rtl":false, "native_name":"Kurdish" }
			, { "name":"Latin"                        , "iso_code":"la"        , "rtl":false, "native_name":"Latin" }
			, { "name":"Latvian"                      , "iso_code":"lv"        , "rtl":false, "native_name":"latviešu" }
			, { "name":"Lithuanian"                   , "iso_code":"lt"        , "rtl":false, "native_name":"lietuvių" }
			, { "name":"Low German"                   , "iso_code":"nds"       , "rtl":false, "native_name":"Low German" }
			, { "name":"Luxembourgish"                , "iso_code":"lb"        , "rtl":false, "native_name":"Luxembourgish" }
			, { "name":"Macedonian"                   , "iso_code":"mk"        , "rtl":false, "native_name":"македонски" }
			, { "name":"Maithili"                     , "iso_code":"mai"       , "rtl":false, "native_name":"Maithili" }
			, { "name":"Malay"                        , "iso_code":"ms"        , "rtl":false, "native_name":"Bahasa Melayu" }
			, { "name":"Malayalam"                    , "iso_code":"ml"        , "rtl":false, "native_name":"മലയാളം" }
			, { "name":"Maltese"                      , "iso_code":"mt"        , "rtl":false, "native_name":"Malti" }
			, { "name":"Manipuri"                     , "iso_code":"mni"       , "rtl":false, "native_name":"Manipuri" }
			, { "name":"Marathi"                      , "iso_code":"mr"        , "rtl":false, "native_name":"मराठी" }
			, { "name":"Mongolian"                    , "iso_code":"mn"        , "rtl":false, "native_name":"Mongolian" }
			, { "name":"Nepali"                       , "iso_code":"ne"        , "rtl":false, "native_name":"नेपाली" }
			, { "name":"Norwegian"                    , "iso_code":"no"        , "rtl":false, "native_name":"norsk" }
			, { "name":"Norwegian Bokmål"             , "iso_code":"nb"        , "rtl":false, "native_name":"norsk bokmål" }
			, { "name":"Norwegian Nynorsk"            , "iso_code":"nn"        , "rtl":false, "native_name":"nynorsk" }
			, { "name":"Occitan"                      , "iso_code":"oc"        , "rtl":false, "native_name":"Occitan" }
			, { "name":"Oriya"                        , "iso_code":"or"        , "rtl":false, "native_name":"ଓଡ଼ିଆ" }
			, { "name":"Persian"                      , "iso_code":"fa"        , "rtl":false, "native_name":"فارسی" }
			, { "name":"Persian (Afghanistan)"        , "iso_code":"fa_AF"     , "rtl":false, "native_name":"دری (افغانستان)" }
			, { "name":"Polish"                       , "iso_code":"pl"        , "rtl":false, "native_name":"polski" }
			, { "name":"Portuguese"                   , "iso_code":"pt"        , "rtl":false, "native_name":"português" }
			, { "name":"Portuguese (Brazil)"          , "iso_code":"pt_BR"     , "rtl":false, "native_name":"português (Brasil)" }
			, { "name":"Portuguese (Portugal)"        , "iso_code":"pt_PT"     , "rtl":false, "native_name":"português (Portugal)" }
			, { "name":"Punjabi"                      , "iso_code":"pa"        , "rtl":false, "native_name":"ਪੰਜਾਬੀ" }
			, { "name":"Romanian"                     , "iso_code":"ro"        , "rtl":false, "native_name":"română" }
			, { "name":"Russian"                      , "iso_code":"ru"        , "rtl":false, "native_name":"русский" }
			, { "name":"Sanskrit"                     , "iso_code":"sa"        , "rtl":false, "native_name":"Sanskrit" }
			, { "name":"Santali"                      , "iso_code":"sat"       , "rtl":false, "native_name":"Santali" }
			, { "name":"Sardinian"                    , "iso_code":"srd"       , "rtl":false, "native_name":"Sardinian" }
			, { "name":"Serbian"                      , "iso_code":"sr"        , "rtl":false, "native_name":"Српски" }
			, { "name":"Serbian (Cyrillic)"           , "iso_code":"sr_Cyrl"   , "rtl":false, "native_name":"Српски (Ћирилица)" }
			, { "name":"Serbian (Latin)"              , "iso_code":"sr_Latn"   , "rtl":false, "native_name":"Srpski (Latinica)" }
			, { "name":"Sindhi"                       , "iso_code":"sd"        , "rtl":false, "native_name":"Sindhi" }
			, { "name":"Sinhala"                      , "iso_code":"si"        , "rtl":false, "native_name":"සිංහල" }
			, { "name":"Slovak"                       , "iso_code":"sk"        , "rtl":false, "native_name":"slovenčina" }
			, { "name":"Slovenian"                    , "iso_code":"sl"        , "rtl":false, "native_name":"slovenščina" }
			, { "name":"Spanish"                      , "iso_code":"es"        , "rtl":false, "native_name":"español" }
			, { "name":"Spanish (Argentina)"          , "iso_code":"es_AR"     , "rtl":false, "native_name":"español (Argentina)" }
			, { "name":"Spanish (Mexico)"             , "iso_code":"es_MX"     , "rtl":false, "native_name":"español (México)" }
			, { "name":"Spanish (Spain)"              , "iso_code":"es_ES"     , "rtl":false, "native_name":"español (España)" }
			, { "name":"Spanish (Uruguay)"            , "iso_code":"es_UY"     , "rtl":false, "native_name":"español (Uruguay)" }
			, { "name":"Spanish (Venezuela)"          , "iso_code":"es_VE"     , "rtl":false, "native_name":"español (Venezuela)" }
			, { "name":"Swedish"                      , "iso_code":"sv"        , "rtl":false, "native_name":"svenska" }
			, { "name":"Tagalog"                      , "iso_code":"tl"        , "rtl":false, "native_name":"tl" }
			, { "name":"Tamil"                        , "iso_code":"ta"        , "rtl":false, "native_name":"தமிழ்" }
			, { "name":"Tamil (India)"                , "iso_code":"ta_IN"     , "rtl":false, "native_name":"தமிழ் (இந்தியா)" }
			, { "name":"Telugu"                       , "iso_code":"te"        , "rtl":false, "native_name":"తెలుగు" }
			, { "name":"Thai"                         , "iso_code":"th"        , "rtl":false, "native_name":"ไทย" }
			, { "name":"Turkish"                      , "iso_code":"tr"        , "rtl":false, "native_name":"Türkçe" }
			, { "name":"Ukrainian"                    , "iso_code":"uk"        , "rtl":false, "native_name":"українська" }
			, { "name":"Urdu"                         , "iso_code":"ur"        , "rtl":true , "native_name":"اردو" }
			, { "name":"Urdu (Pakistan)"              , "iso_code":"ur_PK"     , "rtl":true , "native_name":"اردو (پاکستان)" }
			, { "name":"Uzbek"                        , "iso_code":"uz"        , "rtl":false, "native_name":"Ўзбек" }
			, { "name":"Vietnamese"                   , "iso_code":"vi"        , "rtl":false, "native_name":"Tiếng Việt" }
			, { "name":"Welsh"                        , "iso_code":"cy"        , "rtl":false, "native_name":"Cymraeg" }
			, { "name":"Xhosa"                        , "iso_code":"xh"        , "rtl":false, "native_name":"Xhosa" }
			, { "name":"Yoruba"                       , "iso_code":"yo"        , "rtl":false, "native_name":"Èdè Yorùbá" }
			, { "name":"hne"                          , "iso_code":"hne"       , "rtl":false, "native_name":"hne" }
			, { "name":"me (Montenegro)"              , "iso_code":"me_ME"     , "rtl":false, "native_name":"me (Montenegro)" }
			, { "name":"va (Spain)"                   , "iso_code":"va_ES"     , "rtl":false, "native_name":"va (Spain)" }
		]
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
		var cacheKey = arguments.sourceObject & "|" & arguments.selectField;

		_resolveSelectFieldCache = variables._resolveSelectFieldCache ?: {};

		if ( !StructKeyExists( _resolveSelectFieldCache, cacheKey ) ) {
			var fieldMinusSqlEscapes = ReReplace( arguments.selectField, "[`\[\]]", "", "all" );
			var bareFieldRegex       = "^[_a-zA-Z][_a-zA-Z0-9\$]*$";

			if ( ReFind( bareFieldRegex, fieldMinusSqlEscapes ) ) {
				_resolveSelectFieldCache[ cacheKey ] = {
					  objectName   = arguments.sourceObject
					, propertyName = fieldMinusSqlEscapes
					, selector     = "#arguments.sourceObject#.#fieldMinusSqlEscapes#"
					, alias        = fieldMinusSqlEscapes
				};
			} else {
				var fieldRegex       = "^[_a-zA-Z][_a-zA-Z0-9\$]*\.[_a-zA-Z][_a-zA-Z0-9]*$";
				var selectFieldParts = ListToArray( fieldMinusSqlEscapes, " " );

				if ( !selectFieldParts.len() || !ReFind( fieldRegex, selectFieldParts[ 1 ] ) || selectFieldParts.len() > 3 || ( selectFieldParts.len() == 3 && selectFieldParts[ 2 ] != "as" ) ) {
					_resolveSelectFieldCache[ cacheKey ] = {};
				} else {
					var selector     = selectFieldParts[ 1 ];
					var propertyName = ListLast( selector, "." );
					var objectPath   = ListFirst( selector, "." );
					var objectName   = _getRelationshipGuidance().resolveRelationshipPathToTargetObject( arguments.sourceObject, objectPath );


					if ( !objectName.len() ) {
						_resolveSelectFieldCache[ cacheKey ] = {};
					}

					_resolveSelectFieldCache[ cacheKey ] = {
						  objectName   = objectName
						, propertyName = propertyName
						, selector     = selector
						, alias        = selectFieldParts.len() == 1 ? propertyName : selectFieldParts[ selectFieldParts.len() ]
					}
				}
			}
		}

		return _resolveSelectFieldCache[ cacheKey ];
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

	private string function _getTranslationObjectPrefix() {
		return "_translation_";
	}

	private any function _getLanguageDao() {
		return $getPresideObject( "multilingual_language" );
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

	private any function _getCookieService() {
		return _cookieService;
	}
	private void function _setCookieService( required any cookieService ) {
		_cookieService = arguments.cookieService;
	}
}
component output="false" singleton=true {

// CONSTRUCTOR
	/**
	 * @resourceBundleService.inject ResourceBundleService
	 * @presideObjectService.inject  PresideObjectService
	 * @assetManagerService.inject   AssetManagerService
	 */
	public any function init(
		  required any resourceBundleService
		, required any presideObjectService
		, required any assetManagerService
	) output=false {
		_setResourceBundleService( arguments.resourceBundleService );
		_setPresideObjectService( arguments.presideObjectService );
		_setAssetManagerService( arguments.assetManagerService );

		return this;
	}

// PUBLIC API METHODS
	public array function generateRulesFromPresideObject( required string objectName ) {
		var fields        = _getPresideObjectService().getObjectProperties( objectName=arguments.objectName );
		var field         = "";
		var fieldRules    = "";
		var rules         = [];
		var rule          = "";

		for( field in fields ){
			if ( !ListFindNoCase( "hidden,none", ( fields[field].control ?: "" ) ) ) {
				fieldRules = getRulesForField(
					  objectName      = arguments.objectName
					, fieldName       = field
					, fieldAttributes = fields[ field ]
				);

				for( rule in fieldRules ){
					ArrayAppend( rules, rule );
				}
			}
		}

		return rules;
	}

	public array function generateRulesFromPresideForm( required any formObject ) {
		var tab           = "";
		var fieldset      = "";
		var field         = "";
		var fieldRules    = "";
		var rule          = "";
		var rules         = [];

		for( tab in formObject.tabs ){
			if ( IsBoolean( tab.deleted ?: "" ) && tab.deleted ) {
				continue;
			}
			for( fieldset in tab.fieldsets ){
				if ( IsBoolean( fieldset.deleted ?: "" ) && fieldset.deleted ) {
					continue;
				}

				for( field in fieldset.fields ){
					if ( IsBoolean( field.deleted ?: "" ) && field.deleted ) {
						continue;
					}

					param name="field.name"         default="";
					param name="field.binding"      default="";
					param name="field.sourceObject" default="";

					fieldRules = getRulesForField(
						  objectName      = field.sourceObject.len() ? field.sourceObject : ListFirst( field.binding, "." )
						, fieldName       = field.name
						, fieldAttributes = field
					);

					for( rule in fieldRules ){
						ArrayAppend( rules, rule );
					}

					if ( StructKeyExists( field, "rules" ) ) {
						for( rule in field.rules ){
							rule.fieldName = field.name;
							ArrayAppend( rules, rule );
						}
					}
				}
			}
		}

		return rules;
	}

	public array function getRulesForField( required string objectName, required string fieldName, required struct fieldAttributes ) output=false {
		param name="arguments.fieldAttributes.required"  default="false";
		param name="arguments.fieldAttributes.generator" default="";
		param name="arguments.fieldAttributes.type"     default="string";

		var field = arguments.fieldAttributes;
		var rules = [];
		var index = "";
		var rule  = "";
		var conventionBasedMessageKey = "";
		var poService = _getPresideObjectService();

		if ( ( field.control ?: "" ) == "readonly" ) {
			return [];
		}

		// required
		if ( IsBoolean( field.required ) and field.required
			 and not ListFindNoCase( "datecreated,datemodified", arguments.fieldName )
			 and ( not Len( Trim( field.generator ) ) or field.generator eq "none" )
		) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="required" } );
		}

		// types
		switch( field.type ){
			case "numeric":
				if ( StructKeyExists( field, "format" ) and field.format eq "integer" ) {
					ArrayAppend( rules, { fieldName=arguments.fieldName, validator="digits" } );
				} else {
					ArrayAppend( rules, { fieldName=arguments.fieldName, validator="number" } );
				}
			break;

			case "date":
				if ( field.dbtype == "timestamp" ) {
					ArrayAppend( rules, { fieldName=arguments.fieldName, validator="datetime" } );
				} else {
					ArrayAppend( rules, { fieldName=arguments.fieldName, validator=field.dbtype } );
				}
			break;

			case "string":
				if ( StructKeyExists( field, "format" ) and Len( Trim( field.format ) ) ) {
					if ( ListFirst( field.format, ":" ) eq "regex" ) {
						ArrayAppend( rules, { fieldName=arguments.fieldName, validator="match", params={ regex = ListRest( field.format, ":" ) } } );
					} else {
						ArrayAppend( rules, { fieldName=arguments.fieldName, validator=Trim( field.format ) } );
					}
				}
			break;
		}

		// controls
		switch( field.control ?: "" ){
			case "emailInput":
				var multiple = isBoolean( field.multiple ?: "" ) && field.multiple;
				ArrayAppend( rules, { fieldName=arguments.fieldName, validator="email", params={ multiple=multiple } } );
			break;

			case "fileupload":
				if ( Len( Trim( field.allowedTypes ?: "" ) ) ) {
					var allowedExtensions = _getAssetManagerService().expandTypeList( ListToArray( field.allowedTypes ) ).toList();
					var allowedTypes      = listChangeDelims( field.allowedTypes, ", " );
				 	ArrayAppend( rules, { fieldName=arguments.fieldName, validator="fileType", params={ allowedTypes=allowedTypes, allowedExtensions=allowedExtensions } } );
				}
			break;

			case "captcha":
				ArrayAppend( rules, { fieldName=arguments.fieldName, validator="recaptcha" } );
			break;
		}

		// text length
		if ( StructKeyExists( field, "minLength" ) and Val( field.minLength ) and StructKeyExists( field, "maxLength" ) and Val( field.maxLength ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="rangeLength", params={ minLength = Val( field.minLength ), maxLength = Val( field.maxLength ) } } );
		} else if ( StructKeyExists( field, "minLength" ) and Val( field.minLength ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="minLength", params={ length = Val( field.minLength ) } } );
		} else if ( StructKeyExists( field, "maxLength" ) and Val( field.maxLength ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="maxLength", params={ length = Val( field.maxLength ) } } );
		}

		// min/max values
		if ( StructKeyExists( field, "minValue" ) and StructKeyExists( field, "maxValue" ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="range", params={ min = Val( field.minValue ), max = Val( field.maxValue ) } } );
		} else if ( StructKeyExists( field, "minValue" ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="min", params={ min = Val( field.minValue ) } } );
		} else if ( StructKeyExists( field, "maxValue" ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="max", params={ max = Val( field.maxValue ) } } );
		}

		// unique indexes
		if ( StructKeyExists( field, "uniqueindexes" ) && arguments.objectName.len() ) {
			for( index in ListToArray( field.uniqueindexes ) ) {
				if ( _isLastFieldInUniqueIndex( index, arguments.objectName, arguments.fieldName ) ) {
					ArrayAppend( rules, { fieldName=arguments.fieldName, validator="presideObjectUniqueIndex", params={ objectName=arguments.objectName, fields=_getUniqueIndexFields( index, arguments.objectName ) } } );
				}
			}
		}

		// password policies
		if ( Len( Trim( field.passwordPolicyContext ?: "" ) ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="meetsPasswordPolicy", params={ passwordPolicyContext = field.passwordPolicyContext } } );
		}

		// enum
		if ( Len( Trim( field.enum ?: "" ) ) ) {
			ArrayAppend( rules, { fieldName=arguments.fieldName, validator="enum", params={ enum=field.enum, multiple=( IsBoolean( field.multiple ?: "" ) && field.multiple ) } } );
		}

		for( rule in rules ){
			if ( not StructKeyExists( rule, "message" ) ) {
				conventionBasedMessageKey =  poService.getResourceBundleUriRoot( arguments.objectName ) & "validation.#arguments.fieldName#.#rule.validator#.message";
				if ( Len( Trim( _getResourceBundleService().getResource( conventionBasedMessageKey, "" ) ) ) ) {
					rule.message = conventionBasedMessageKey;
				}
			}
		}

		return rules;
	}

// PRIVATE UTILITY
	private boolean function _isLastFieldInUniqueIndex( required string indexDefinition, required string objectName, required string fieldName ) output=false {
		if ( ListLen( arguments.indexDefinition, "|" ) eq 1 ) {
			return true;
		}

		var position  = Val( ListLast( arguments.indexDefinition, "|" ) );
		var indexName = ListFirst( arguments.indexDefinition, "|" );
		var props     = _getPresideObjectService().getObjectProperties( objectName=arguments.objectName );
		var propName  = "";
		var indexes   = "";
		var index     = "";

		for( propName in props ){
			if ( propName eq arguments.fieldName ) {
				continue;
			}

			indexes = props[ propName ].uniqueindexes ?: "";
			for( index in ListToArray( indexes ) ) {
				if ( ListFirst( index, "|" ) eq indexName and Val( ListLast( index, "|" ) ) gt position ) {
					return false;
				}
			}
		}

		return true;
	}

	private string function _getUniqueIndexFields( required string indexDefinition, required string objectName ) output=false {
		var indexName = ListFirst( arguments.indexDefinition, "|" );
		var props     = _getPresideObjectService().getObjectProperties( objectName=arguments.objectName );
		var propName  = "";
		var indexes   = "";
		var index     = "";
		var fields    = [];

		for( propName in props ){
			indexes = props[ propName ].uniqueindexes ?: "";
			for( index in ListToArray( indexes ) ) {
				if ( ListFirst( index, "|" ) eq indexName ) {
					ArrayAppend( fields, propName );
				}
			}
		}

		ArraySort( fields, "textnocase" );

		return ArrayToList( fields );
	}

// GETTERS AND SETTERS
	private any function _getResourceBundleService() output=false {
		return _resourceBundleService;
	}
	private void function _setResourceBundleService( required any resourceBundleService ) output=false {
		_resourceBundleService = arguments.resourceBundleService;
	}

	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getAssetManagerService() output=false {
		return _assetManagerService;
	}
	private void function _setAssetManagerService( required any assetManagerService ) output=false {
		_assetManagerService = arguments.assetManagerService;
	}
}
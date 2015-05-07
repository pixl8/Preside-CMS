component output=false singleton=true hint="I do the logic for merging two objects to make one" {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API METHODS
	public struct function mergeObjects( required struct object1, required struct object2 ) output=false {
		object1.meta.properties    = _mergeObjectProperties( object1.meta.properties, object2.meta.properties, object1.meta );
		object1.instance           = _mergeObjectInstances( object1.instance, object2.instance );
		object1.meta.siteTemplates = _mergeSiteTemplatesSpecification( object1, object2 );

		var ignoreKeys = [ "properties", "siteTemplates", "propertyNames", "dbFieldList", "indexes" ];

		for ( var key in object2.meta ) {
			if ( !ignoreKeys.find( key ) ) {
				object1.meta[ key ] = object2.meta[ key ];
			}
		}

		return object1;
	}

// PRIVATE HELPERS
	private struct function _mergeObjectProperties( required struct propsA, required struct propsB, required struct objectAMeta ) output=false {
		for( var propName in propsA ) {
			if ( StructKeyExists( propsB, propName ) ) {
				var attribsA = propsA[ propName ];
				var attribsB = propsB[ propName ];

				if ( IsBoolean( attribsB.deleted ?: "" ) && attribsB.deleted ) {
					StructDelete( propsA, propName );
					objectAMeta.propertyNames.delete( propName );

					continue;
				}
				StructAppend( attribsA, attribsB );
			}
		}
		for( var propName in propsB ) {
			if ( !StructKeyExists( propsA, propName ) && !( IsBoolean( propsB[ propName ].deleted ?: "" ) && propsB[ propName ].deleted ) ) {
				var prop = propsA[ propName ] = propsB[ propName ];

				if ( not objectAMeta.propertyNames.find( propName ) ) {
					ArrayAppend( objectAMeta.propertyNames, propName );
				}
			}
		}

		return propsA;
	}

	private any function _mergeObjectInstances( required any instanceA, required any instanceB ) output=false {
		instanceA.$addFunction    = this.$addFunction;
		instanceB.$mixinFunctions = this.$mixinFunctions;

		instanceB.$mixinFunctions( instanceA );

		StructDelete( instanceA, "$addFunction"      );
		StructDelete( instanceB, "$extractFunctions" );

		return instanceA;
	}

	private string function _mergeSiteTemplatesSpecification( required struct object1, required struct object2 ) output=false {
		var mergedSiteTemplates = "";

		arguments.object1.meta.siteTemplates = arguments.object1.meta.siteTemplates ?: "*";
		arguments.object2.meta.siteTemplates = arguments.object2.meta.siteTemplates ?: "*";

		if ( arguments.object1.meta.siteTemplates == "*" || arguments.object2.meta.siteTemplates == "*" || !Len( Trim( arguments.object2.meta.siteTemplates  && arguments.object1.meta.siteTemplates ) ) ) {
			return "*";
		}

		mergedSiteTemplates = arguments.object1.meta.siteTemplates;
		if ( Len( Trim( arguments.object2.meta.siteTemplates ) ) ) {
			for( var template in ListToArray( arguments.object2.meta.siteTemplates ) ) {
				if ( !ListFindNoCase( mergedSiteTemplates, template ) ) {
					mergedSiteTemplates = ListAppend( mergedSiteTemplates, template );
				}
			}
		}

		return mergedSiteTemplates;
	}


// MIXIN METHODS
	public void function $addFunction( required string name, required function func ) output=false {
		this[ name ] = func;
		variables[ name ] = func;
	}

	public void function $mixinFunctions( target, objMeta = getMetaData( this ) ) output=false {
		if ( StructKeyExists( objMeta, "extends" ) ) {
			this.$mixinFunctions( target, objMeta.extends );
		}

		if ( StructKeyExists( objMeta, "functions" ) ) {
			for( var func in objMeta.functions ) {
				target.$addFunction( func.name, this[ func.name ] );
			}
		}
	}

}
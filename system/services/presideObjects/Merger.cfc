component output=false hint="I do the logic for merging two objects to make one" {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API METHODS
	public struct function mergeObjects( required struct object1, required struct object2 ) output=false {
		object1.meta.properties    = _mergeObjectProperties( object1.meta.properties, object2.meta.properties, object1.meta );
		object1.instance           = _mergeObjectInstances( object1.instance, object2.instance );
		object1.meta.siteTemplates = _mergeSiteTemplatesSpecification( object1, object2 );

		return object1;
	}

// PRIVATE HELPERS
	private struct function _mergeObjectProperties( required struct propsA, required struct propsB, required struct objectAMeta ) output=false {
		for( var propName in propsA ) {
			if ( StructKeyExists( propsB, propName ) ) {
				var attribsA = propsA[ propName ].getMemento();
				var attribsB = propsB[ propName ].getMemento();

				if ( IsBoolean( attribsB.deleted ?: "" ) && attribsB.deleted ) {
					StructDelete( propsA, propName );

					continue;
				}
				StructAppend( attribsA, attribsB );
				propsA[ propName ] = new Property( argumentCollection=attribsA );
			}
		}
		for( var propName in propsB ) {
			if ( !StructKeyExists( propsA, propName ) && !( IsBoolean( propsB[ propName ].getAttribute( "deleted", "" ) ) && propsB[ propName ].getAttribute( "deleted" ) ) ) {
				var prop = propsA[ propName ] = propsB[ propName ];

				if ( not ListFindNoCase( objectAMeta.dbFieldList, prop.name ) and objectAMeta.properties[ prop.name ].dbType neq "none" ) {
					objectAMeta.dbFieldList = ListAppend( objectAMeta.dbFieldList, prop.name );
				}

				if ( not objectAMeta.propertyNames.find( prop.name ) ) {
					ArrayAppend( objectAMeta.propertyNames, prop.name );
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
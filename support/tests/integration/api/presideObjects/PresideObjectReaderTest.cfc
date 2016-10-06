<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="test01_readObject_shouldGetTableName_fromComponent_whenAttributeSupplied" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_attributes();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "test_table", object.tableName   );
		</cfscript>
	</cffunction>

	<cffunction name="test02_readObject_shouldAllowInheritanceOfTableName" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "test_table", object.tableName   );
		</cfscript>
	</cffunction>

	<cffunction name="test03_readObject_shouldAllowInheritanceOverridesOfTableName" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_overrides();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "override_test_table", object.tableName   );
		</cfscript>
	</cffunction>

	<cffunction name="test04_readObject_shouldReadInAllSimpleAttributesWithInheritance" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_and_custom_attributes();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "override_test_table", object.tableName   );
			super.assertEquals( "test", object.someattribute );
		</cfscript>
	</cffunction>

	<cffunction name="test05_readObject_shouldNotReadStandardComponentAttributes_suchAsOutputAndPersist" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_and_custom_attributes();
			var object       = getReader().readObject( targetObject );

			super.assert( not StructKeyExists( object, "accessors"     ), "The object reader returned system attribute, 'accessors', when it was expected not to." );
			super.assert( not StructKeyExists( object, "displayname"   ), "The object reader returned system attribute, 'displayname', when it was expected not to." );
			super.assert( not StructKeyExists( object, "fullname"      ), "The object reader returned system attribute, 'fullname', when it was expected not to." );
			super.assert( not StructKeyExists( object, "hashCode"      ), "The object reader returned system attribute, 'hashCode', when it was expected not to." );
			super.assert( not StructKeyExists( object, "hint"          ), "The object reader returned system attribute, 'hint', when it was expected not to." );
			super.assert( not StructKeyExists( object, "output"        ), "The object reader returned system attribute, 'output', when it was expected not to." );
			super.assert( not StructKeyExists( object, "path"          ), "The object reader returned system attribute, 'path', when it was expected not to." );
			super.assert( not StructKeyExists( object, "persistent"    ), "The object reader returned system attribute, 'persistent', when it was expected not to." );
			super.assert( not StructKeyExists( object, "remoteAddress" ), "The object reader returned system attribute, 'remoteAddress', when it was expected not to." );
			super.assert( not StructKeyExists( object, "synchronized"  ), "The object reader returned system attribute, 'synchronized', when it was expected not to." );
		</cfscript>
	</cffunction>

	<cffunction name="test06_readObject_shouldReturnPropertiesDefinedInComponent" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_properties();
			var object       = getReader().readObject( targetObject );
			var expectedResult = {
				  test_property         = { name="test_property"         }
				, related_prop          = { name="related_prop"         ,                                                          control="objectpicker", maxLength="35", relatedto="someobject", relationship="many-to-one" }
				, another_property      = { name="another_property"     , type="date"   , label="My property" , dbtype="datetime", control="datepicker", required="true" }
				, some_numeric_property = { name="some_numeric_property", type="numeric", label="Numeric prop", dbtype="tinyint" , control="spinner"   , required="false", minValue="1", maxValue="10" }
			};

			super.assertEquals( expectedResult, object.properties );
		</cfscript>
	</cffunction>

	<cffunction name="test07_readObject_shouldReturnPropertiesDefinedInComponentMixedInWithInheritedProperties" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_properties_and_inheritance();
			var object       = getReader().readObject( targetObject );
			var expectedResult = {
				  test_property         = { name="test_property"        , label="New label" }
				, new_property          = { name="new_property"         , label="New property" }
				, related_prop          = { name="related_prop"         ,                                              control="objectpicker", maxLength="35", relatedto="someobject", relationship="many-to-one" }
				, another_property      = { name="another_property"     , type="date"   , label="My property" , dbtype="datetime", control="datepicker", required="true" }
				, some_numeric_property = { name="some_numeric_property", type="numeric", label="Numeric prop", dbtype="tinyint" , control="spinner"   , required="false", minValue="1", maxValue="10" }
			};

			super.assertEquals( expectedResult, object.properties );
		</cfscript>
	</cffunction>

	<cffunction name="test08_readObject_shouldReturnAListOfPublicMethods_whenComponentHasPublicMethods" returntype="void">
		<cfscript>
			var targetObject    = new tests.resources.presideObjectReader.object_with_methods();
			var object          = getReader().readObject( targetObject );
			var expectedMethods = "method1,method2,method3";

			super.assert( StructKeyExists( object, 'methods' ), "No methods key was returned" );
			super.assertEquals( expectedMethods, object.methods );
		</cfscript>
	</cffunction>

	<cffunction name="test09_readObject_shouldReturnSpecifiedDsn" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_dsn();
			var object       = getReader().readObject( targetObject );

			super.assert( StructKeyExists( object, 'dsn' ), "No dsn key was was returned" );
			super.assertEquals( "different_dsn", object.dsn );
		</cfscript>
	</cffunction>

	<cffunction name="test10_getAutoPivotObjectDefinition_shouldCreateObjectDefinitionBasedOnTwoSourcePkObjects" returntype="void">
		<cfscript>
			var reader = getReader();
			var objA = { meta = reader.readObject( new tests.resources.presideObjectReader.simple_object() ) };
			var objB = { meta = reader.readObject( new tests.resources.presideObjectReader.simple_object_with_prefix() ) };

			reader.finalizeMergedObject( objA );
			reader.finalizeMergedObject( objB );

			var expectedResult = {
				  dbFieldList = "source,target,sort_order"
				, dsn         = "default_dsn"
				, indexes     = { ux_mypivotobject = { unique=true, fields="source,target" } }
				, name        = "mypivotobject"
				, tablePrefix = "pobj_"
				, tableName   = "pobj_mypivotobject"
				, versioned   = true
				, properties  = {
					  source      = { name="source"    , control="auto", dbtype="varchar", maxLength="35", generator="none", relationship="many-to-one", relatedTo="simple_object"            , required=true, type="string", onDelete="cascade" }
					, target      = { name="target"    , control="auto", dbtype="varchar", maxLength="35", generator="none", relationship="many-to-one", relatedTo="simple_object_with_prefix", required=true, type="string", onDelete="cascade" }
					, sort_order  = { name="sort_order", control="auto", type="numeric" , dbtype="int" , maxLength="0", generator="none", relationship="none", required=false }
				  }
			};
			var autoObject = getReader().getAutoPivotObjectDefinition(
				  sourceObject       = objA.meta
				, targetObject       = objB.meta
				, pivotObjectName    = "mypivotobject"
				, sourcePropertyName = "source"
				, targetPropertyName = "target"
			);

			autoObject.properties = _propertiesToStruct( autoObject.properties );

			super.assertEquals( expectedResult, autoObject );
		</cfscript>
	</cffunction>

	<cffunction name="test11_readObject_shouldProvideArrayOfPropertyNamesInOrderOfDefinitionInComponent" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_properties();
			var object       = getReader().readObject( targetObject );
			var expected     = [ "test_property","related_prop","another_property","some_numeric_property"];

			super.assertEquals( expected, object.propertyNames );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="getReader" access="private" returntype="any" output="false">
		<cfargument name="dsn"         type="string" required="false" default="default_dsn" />
		<cfargument name="tablePrefix" type="string" required="false" default="pobj_" />

		<cfscript>
			mockFeatureService = getMockbox().createEmptyMock( "preside.system.services.features.FeatureService" );
			return new preside.system.services.presideObjects.PresideObjectReader(
				  dsn                = arguments.dsn
				, tablePrefix        = arguments.tablePrefix
				, interceptorService = _getMockInterceptorService()
				, featureService     = mockFeatureService
			);
		</cfscript>
	</cffunction>

	<cffunction name="_propertiesToStruct" access="private" returntype="struct" output="false">
		<cfargument name="properties" type="struct" required="true" />

		<cfscript>
			var newProps = {};

			for( var key in arguments.properties ){
				newProps[ key ] = arguments.properties[ key ];
			}

			return newProps;
		</cfscript>
	</cffunction>
</cfcomponent>
<cfcomponent output="false" extends="mxunit.framework.TestCase">


	<cffunction name="test01_readObject_shouldDeriveTableName_fromComponentName_whenAttributeNotSupplied" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "pobj_simple_object", object.tableName );
		</cfscript>
	</cffunction>

	<cffunction name="test02_readObject_shouldGetTableName_fromComponent_whenAttributeSupplied" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_attributes();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "pobj_test_table", object.tableName   );
		</cfscript>
	</cffunction>

	<cffunction name="test03_readObject_shouldAllowInheritanceOfTableName" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "pobj_test_table", object.tableName   );
		</cfscript>
	</cffunction>

	<cffunction name="test04_readObject_shouldAllowInheritanceOverridesOfTableName" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_overrides();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "pobj_override_test_table", object.tableName   );
		</cfscript>
	</cffunction>

	<cffunction name="test05_readObject_shouldReadInAllSimpleAttributesWithInheritance" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_and_custom_attributes();
			var object       = getReader().readObject( targetObject );

			super.assertEquals( "pobj_override_test_table", object.tableName   );
			super.assertEquals( "test", object.someattribute );
		</cfscript>
	</cffunction>

	<cffunction name="test06_readObject_shouldNotReadStandardComponentAttributes_suchAsOutputAndPersist" returntype="void">
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

	<cffunction name="test07_readObject_shouldReturnDefaultPresidePropeties_whenNotDefinedInTheComponent" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object();
			var object       = getReader().readObject( targetObject );
			var expectedResult = {
				  id           = { name="id"          , type="string", dbtype="varchar"  , control="none"     , maxLength="35", relationship="none", relatedto="none", generator="UUID", required="true", pk="true" }
				, label        = { name="label"       , type="string", dbtype="varchar"  , control="textinput", maxLength="250", relationship="none", relatedto="none", generator="none", required="true" }
				, datecreated  = { name="datecreated" , type="date"  , dbtype="timestamp", control="none"     , maxLength="0" , relationship="none", relatedto="none", generator="none", required="true" }
				, datemodified = { name="datemodified", type="date"  , dbtype="timestamp", control="none"     , maxLength="0" , relationship="none", relatedto="none", generator="none", required="true" }
			};

			super.assertEquals( expectedResult, _propertiesToStruct( object.properties ) );
		</cfscript>
	</cffunction>

	<cffunction name="test08_readObject_shouldReturnDefaultPresidePropertiesWithAttributesMergedWithThoseDefinedInComponent" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_redifined_standard_properties();
			var object       = getReader().readObject( targetObject );
			var expectedResult = {
				  id           = { name="id"          , label="Test ID"           , type="numeric", dbtype="integer"  , control="none"      , maxLength="9" , relationship="none", relatedto="none", generator="AUTOINCREMENT", required="true", pk="true"  }
				, label        = { name="label"       , label="Test Label"        , type="string" , dbtype="varchar"  , control="textinput" , maxLength="250", relationship="none", relatedto="none", generator="none"         , required="true"  }
				, datecreated  = { name="datecreated" , label="Test Created"      , type="date"   , dbtype="timestamp", control="datepicker", maxLength="0" , relationship="none", relatedto="none", generator="none"         , required="false" }
				, datemodified = { name="datemodified", label="Test Last modified", type="date"   , dbtype="timestamp", control="datepicker", maxLength="0" , relationship="none", relatedto="none", generator="none"         , required="false" }
			};

			super.assertEquals( expectedResult, _propertiesToStruct( object.properties ) );
		</cfscript>
	</cffunction>

	<cffunction name="test09_readObject_shouldReturnPropertiesDefinedInComponentMixedInWithDefaultPropertyAttributes" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_properties();
			var object       = getReader().readObject( targetObject );
			var expectedResult = {
				  id                = { name="id"                                     , type="string" , dbtype="varchar"  , control="none"        , maxLength="35" , relationship="none"       , relatedto="none"      , generator="UUID", required="true", pk="true"  }
				, label             = { name="label"                                  , type="string" , dbtype="varchar"  , control="textinput"   , maxLength="250" , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, datecreated       = { name="datecreated"                            , type="date"   , dbtype="timestamp", control="none"        , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, datemodified      = { name="datemodified"                           , type="date"   , dbtype="timestamp", control="none"        , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, test_property         = { name="test_property"                              , type="string" , dbtype="varchar"  , control="default"     , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="false" }
				, related_prop          = { name="related_prop"                               , type="string" , dbtype="varchar"  , control="objectpicker", maxLength="35" , relationship="many-to-one", relatedto="someobject", generator="none", required="false" }
				, another_property      = { name="another_property"     , label="My property" , type="date"   , dbtype="datetime" , control="datepicker"  , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, some_numeric_property = { name="some_numeric_property", label="Numeric prop", type="numeric", dbtype="tinyint"  , control="spinner"     , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="false", minValue="1", maxValue="10" }
			};

			super.assertEquals( expectedResult, _propertiesToStruct( object.properties ) );
		</cfscript>
	</cffunction>

	<cffunction name="test10_readObject_shouldReturnPropertiesDefinedInComponentMixedInWithInheritedProperties" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_properties_and_inheritance();
			var object       = getReader().readObject( targetObject );
			var expectedResult = {
				  id                = { name="id"               ,                       type="string" , dbtype="varchar"  , control="none"        , maxLength="35" , relationship="none"       , relatedto="none"      , generator="UUID", required="true", pk="true"  }
				, label             = { name="label"            ,                       type="string" , dbtype="varchar"  , control="textinput"   , maxLength="250" , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, datecreated       = { name="datecreated"      ,                       type="date"   , dbtype="timestamp", control="none"        , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, datemodified      = { name="datemodified"     ,                       type="date"   , dbtype="timestamp", control="none"        , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, test_property         = { name="test_property"        , label="New label"   , type="string" , dbtype="varchar"  , control="default"     , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="false" }
				, related_prop          = { name="related_prop"         ,                       type="string" , dbtype="varchar"  , control="objectpicker", maxLength="35" , relationship="many-to-one", relatedto="someobject", generator="none", required="false" }
				, another_property      = { name="another_property"     , label="My property" , type="date"   , dbtype="datetime" , control="datepicker"  , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="true"  }
				, some_numeric_property = { name="some_numeric_property", label="Numeric prop", type="numeric", dbtype="tinyint"  , control="spinner"     , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="false", minValue="1", maxValue="10" }
				, new_property          = { name="new_property"         , label="New property", type="string" , dbtype="varchar"  , control="default"     , maxLength="0"  , relationship="none"       , relatedto="none"      , generator="none", required="false" }
			};

			super.assertEquals( expectedResult, _propertiesToStruct( object.properties ) );
		</cfscript>
	</cffunction>

	<cffunction name="test11_readObject_shouldReturnListOfIndexes_whenDefinedInProperties" returntype="void">
		<cfscript>
			var targetObject    = new tests.resources.presideObjectReader.object_with_indexes();
			var object          = getReader().readObject( targetObject );
			var expectedIndexes = {
				  ix_object_with_indexes_1          = { unique="false", fields="field1,field2,field5" }
				, ix_object_with_indexes_2          = { unique="false", fields="field6,field3"        }
				, ix_object_with_indexes_3          = { unique="false", fields="field4,field1"        }
				, ux_object_with_indexes_uniqueness = { unique="true" , fields="field2,field1"        }
				, ux_object_with_indexes_uniq       = { unique="true" , fields="field3"               }
			}

			super.assert( StructKeyExists( object, 'indexes' ), "No index key was returned" );
			super.assertEquals( expectedIndexes, object.indexes );
		</cfscript>
	</cffunction>

	<cffunction name="test12_readObject_shouldReturnAListOfPublicMethods_whenComponentHasPublicMethods" returntype="void">
		<cfscript>
			var targetObject    = new tests.resources.presideObjectReader.object_with_methods();
			var object          = getReader().readObject( targetObject );
			var expectedMethods = "method1,method2,method3";

			super.assert( StructKeyExists( object, 'methods' ), "No methods key was returned" );
			super.assertEquals( expectedMethods, object.methods );
		</cfscript>
	</cffunction>

	<cffunction name="test13_readObject_shouldReturnAListOfDbTableFields" returntype="void">
		<cfscript>
			var targetObject   = new tests.resources.presideObjectReader.object_with_non_db_field_properties();
			var object         = getReader().readObject( targetObject );
			var expectedFields = [ "id","label","datemodified","datecreated","field1","field2" ];
			var field          = "";

			super.assert( StructKeyExists( object, 'dbFieldList' ), "No dbFieldList key was returned" );
			for( field in expectedFields ){
				super.assert( ListFindNoCase( object.dbFieldList, field ), "The field, #field#, was expected to be returned as a db field but was not." );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test14_readObject_shouldReturnDefaultDsn_whenNoDsnSpecified" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object();
			var object       = getReader().readObject( targetObject );

			super.assert( StructKeyExists( object, 'dsn' ), "No dsn key was was returned" );
			super.assertEquals( "default_dsn", object.dsn );
		</cfscript>
	</cffunction>

	<cffunction name="test15_readObject_shouldReturnSpecifiedDsn" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_dsn();
			var object       = getReader().readObject( targetObject );

			super.assert( StructKeyExists( object, 'dsn' ), "No dsn key was was returned" );
			super.assertEquals( "different_dsn", object.dsn );
		</cfscript>
	</cffunction>

	<cffunction name="test17_readObject_shouldReturnSpecifiedTablePrefixPrependedToTableName" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.simple_object_with_prefix();
			var object       = getReader().readObject( targetObject );

			super.assert( StructKeyExists( object, 'tableName' ), "No tableName key was was returned" );
			super.assertEquals( "psys_simple_object_with_prefix", object.tableName );
		</cfscript>
	</cffunction>

	<cffunction name="test18_readObject_shouldDeriveRelatedToFromPropertyName_whenRelationshipSpecifiedAndNoRelatedToIsSpecified" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_conventional_relationship();
			var object       = getReader().readObject( targetObject );

			super.assert( StructKeyExists( object.properties, "simple_object" ) );
			super.assertEquals( "simple_object", object.properties.simple_object.relatedTo );
		</cfscript>
	</cffunction>

	<cffunction name="test19_getAutoPivotObjectDefinition_shouldCreateObjectDefinitionBasedOnTwoSourcePkObjects" returntype="void">
		<cfscript>
			var objA = getReader().readObject( new tests.resources.presideObjectReader.simple_object() );
			var objB = getReader().readObject( new tests.resources.presideObjectReader.simple_object_with_prefix() );

			var expectedResult = {
				  dbFieldList = "simple_object,simple_object_with_prefix,sort_order"
				, dsn         = "default_dsn"
				, indexes     = { ux_simple_object__join__simple_object_with_prefix = { unique=true, fields="simple_object,simple_object_with_prefix" } }
				, name        = "simple_object__join__simple_object_with_prefix"
				, tablePrefix = "pobj_"
				, tableName   = "pobj_simple_object__join__simple_object_with_prefix"
				, versioned   = true
				, properties  = {
					  simple_object             = { name="simple_object"            , control="auto", dbtype="varchar", maxLength="35", generator="none", relationship="many-to-one", relatedTo="simple_object"            , required=true, type="string"            , onDelete="cascade" }
					, simple_object_with_prefix = { name="simple_object_with_prefix", control="auto", dbtype="varchar", maxLength="35", generator="none", relationship="many-to-one", relatedTo="simple_object_with_prefix", required=true, type="string", onDelete="cascade" }
					, sort_order                = { name="sort_order"               , control="auto", type="numeric" , dbtype="int" , maxLength="0", generator="none", relationship="none", required=false }
				  }
			};
			var autoObject = getReader().getAutoPivotObjectDefinition(
				  objectA = objA
				, objectB = objB
			);

			autoObject.properties = _propertiesToStruct( autoObject.properties );

			super.assertEquals( expectedResult, autoObject );
		</cfscript>
	</cffunction>

	<cffunction name="test20_readObject_shouldProvideArrayOfPropertyNamesInOrderOfDefinitionInComponent" returntype="void">
		<cfscript>
			var targetObject = new tests.resources.presideObjectReader.object_with_properties();
			var object       = getReader().readObject( targetObject );
			var expected     = [ "id","label","test_property","related_prop","another_property","some_numeric_property","datecreated","datemodified" ];

			super.assertEquals( expected, object.propertyNames );
		</cfscript>
	</cffunction>

	<cffunction name="test21_readObject_shouldInjectSiteTreePageForeignKey_whenObjectSitsUnderPageTypeDirectory" returntype="void">
		<cfscript>
			var targetObject  = CreateObject( "tests.resources.presideObjectReader.page-types.page" );
			var object        = getReader().readObject( targetObject );
			var expectedProps = [ "body","datecreated","datemodified","id","page","page_template" ];

			object.propertyNames.sort( "textNoCase" );

			super.assertEquals( expectedProps, object.propertyNames );

			super.assertEquals( "many-to-one", object.properties.page.getAttribute( "relationship", "" ) );
			super.assertEquals( "page", object.properties.page.getAttribute( "relatedTo", "" ) );
			super.assertEquals( "page", object.properties.page.getAttribute( "uniqueIndexes", "" ) );
			super.assertEquals( "cascade", object.properties.page.getAttribute( "ondelete", "" ) );
			super.assertEquals( "cascade", object.properties.page.getAttribute( "onupdate", "" ) );
			super.assert( object.properties.page.getAttribute( "required" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test22_readObject_shouldSetManyToManyFieldsDbTypeToNone" returntype="void">
		<cfscript>
			var targetObject  = CreateObject( "tests.resources.presideObjectReader.object_with_many_to_many_field" );
			var object        = getReader().readObject( targetObject );

			super.assertEquals( "none", object.properties.dave.dbtype );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="getReader" access="private" returntype="any" output="false">
		<cfargument name="dsn"         type="string" required="false" default="default_dsn" />
		<cfargument name="tablePrefix" type="string" required="false" default="pobj_" />

		<cfreturn new preside.system.api.presideObjects.Reader( dsn = arguments.dsn, tablePrefix = arguments.tablePrefix ) />
	</cffunction>

	<cffunction name="_propertiesToStruct" access="private" returntype="struct" output="false">
		<cfargument name="properties" type="struct" required="true" />

		<cfscript>
			var newProps = {};

			for( var key in arguments.properties ){
				newProps[ key ] = arguments.properties[ key ].getMemento();
			}

			return newProps;
		</cfscript>
	</cffunction>
</cfcomponent>
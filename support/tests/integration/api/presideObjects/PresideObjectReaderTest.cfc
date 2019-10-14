component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	public void function run() {
		describe( "readObject()", function(){
			it( "should get table name from component when attribute supplied", function(){
				var targetObject = new tests.resources.presideObjectReader.simple_object_with_attributes();
				var object       = getReader().readObject( targetObject );

				expect( object.tableName ).toBe( "test_table" );
			} );

			it( "should allow inheritance of table name", function(){
				var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance();
				var object       = getReader().readObject( targetObject );

				expect( object.tableName ).toBe( "test_table" );
			} );

			it( "should allow inheritance overrides of table name", function(){
				var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_overrides();
				var object       = getReader().readObject( targetObject );

				expect( object.tableName ).toBe( "override_test_table" );
			} );

			it( "should read in all simple attributes with inheritance", function(){
				var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_and_custom_attributes();
				var object       = getReader().readObject( targetObject );

				expect( object.tableName ).toBe( "override_test_table" );
				expect( object.someattribute ).toBe( "test" );
			} );

			it( "should not read standard component attributes such as output and persist", function(){
				var targetObject = new tests.resources.presideObjectReader.simple_object_with_inheritance_and_custom_attributes();
				var object       = getReader().readObject( targetObject );

				expect( StructKeyExists( object, "accessors"     ) ).toBeFalse( "The object reader returned system attribute, 'accessors', when it was expected not to." );
				expect( StructKeyExists( object, "displayname"   ) ).toBeFalse( "The object reader returned system attribute, 'displayname', when it was expected not to." );
				expect( StructKeyExists( object, "fullname"      ) ).toBeFalse( "The object reader returned system attribute, 'fullname', when it was expected not to." );
				expect( StructKeyExists( object, "hashCode"      ) ).toBeFalse( "The object reader returned system attribute, 'hashCode', when it was expected not to." );
				expect( StructKeyExists( object, "hint"          ) ).toBeFalse( "The object reader returned system attribute, 'hint', when it was expected not to." );
				expect( StructKeyExists( object, "output"        ) ).toBeFalse( "The object reader returned system attribute, 'output', when it was expected not to." );
				expect( StructKeyExists( object, "path"          ) ).toBeFalse( "The object reader returned system attribute, 'path', when it was expected not to." );
				expect( StructKeyExists( object, "persistent"    ) ).toBeFalse( "The object reader returned system attribute, 'persistent', when it was expected not to." );
				expect( StructKeyExists( object, "remoteAddress" ) ).toBeFalse( "The object reader returned system attribute, 'remoteAddress', when it was expected not to." );
				expect( StructKeyExists( object, "synchronized"  ) ).toBeFalse( "The object reader returned system attribute, 'synchronized', when it was expected not to." );
			} );

			it( "should return properties defined in component", function(){
				var targetObject = new tests.resources.presideObjectReader.object_with_properties();
				var object       = getReader().readObject( targetObject );
				var expectedResult = {
					  test_property         = { name="test_property"         }
					, related_prop          = { name="related_prop"         ,                                                          control="objectpicker", maxLength="35", relatedto="someobject", relationship="many-to-one" }
					, another_property      = { name="another_property"     , type="date"   , label="My property" , dbtype="datetime", control="datepicker", required="true" }
					, some_numeric_property = { name="some_numeric_property", type="numeric", label="Numeric prop", dbtype="tinyint" , control="spinner"   , required="false", minValue="1", maxValue="10" }
				};

				expect( object.properties ).toBe( expectedResult );
			} );

			it( "should return properties defined in component mixed in with inherited properties", function(){
				var targetObject = new tests.resources.presideObjectReader.object_with_properties_and_inheritance();
				var object       = getReader().readObject( targetObject );
				var expectedResult = {
					  test_property         = { name="test_property"        , label="New label" }
					, new_property          = { name="new_property"         , label="New property" }
					, related_prop          = { name="related_prop"         ,                                              control="objectpicker", maxLength="35", relatedto="someobject", relationship="many-to-one" }
					, another_property      = { name="another_property"     , type="date"   , label="My property" , dbtype="datetime", control="datepicker", required="true" }
					, some_numeric_property = { name="some_numeric_property", type="numeric", label="Numeric prop", dbtype="tinyint" , control="spinner"   , required="false", minValue="1", maxValue="10" }
				};

				expect( object.properties ).toBe( expectedResult );
			} );

			it( "should return a list of public method when component has public methods", function(){
				var targetObject    = new tests.resources.presideObjectReader.object_with_methods();
				var object          = getReader().readObject( targetObject );
				var expectedMethods = "method1,method2,method3";

				super.assert( StructKeyExists( object, 'methods' ), "No methods key was returned" );
				expect( object.methods ).toBe( expectedMethods );
			} );

			it( "should return specified dsn", function(){
				var targetObject = new tests.resources.presideObjectReader.simple_object_with_dsn();
				var object       = getReader().readObject( targetObject );

				super.assert( StructKeyExists( object, 'dsn' ), "No dsn key was was returned" );
				expect( object.dsn ).toBe( "different_dsn" );
			} );

			it( "should provide array of property names in order of definition in component", function(){
				var targetObject = new tests.resources.presideObjectReader.object_with_properties();
				var object       = getReader().readObject( targetObject );
				var expected     = [ "test_property","related_prop","another_property","some_numeric_property"];

				expect( expected ).toBe( object.propertyNames );
			} );

		} );

		describe( "getAutoPivotObjectDefinition()", function(){
			it( "should create object definition based on two source PK objects", function(){
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
						  source      = { name="source"    , control="auto", dbtype="varchar", maxLength="35", generator="none", generate="never", relationship="many-to-one", relatedTo="simple_object"            , required=true, type="string", onDelete="cascade" }
						, target      = { name="target"    , control="auto", dbtype="varchar", maxLength="35", generator="none", generate="never", relationship="many-to-one", relatedTo="simple_object_with_prefix", required=true, type="string", onDelete="cascade" }
						, sort_order  = { name="sort_order", control="auto", type="numeric" , dbtype="int" , maxLength="0", generator="none", generate="never", relationship="none", required=false }
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

				expect( expectedResult ).toBe( autoObject );
			} );
		} );

		describe( "finalizeMergedObject()", function(){
			it( "should add an ID field to an object that does not have one", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "id" ) ).toBeTrue();
				expect( dummyObj.meta.properties.id ).toBe( {
					  name         = "id"
					, type         = "string"
					, pk           = true
					, generate     = "insert"
					, generator    = "UUID"
					, dbtype       = "varchar"
					, control      = "none"
					, maxLength    = 35
					, relationship = "none"
					, relatedto    = "none"
					, required     = true
				} );
			} );

			it( "should NOT add an ID field to an object that specifies an alternative ID field", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", idField="mytestobject_id", properties={
						mytestobject_id = { name="mytestobject_id" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "id" ) ).toBeFalse( "ID field was created when it should not have been!" );
			} );

			it( "should create ID field with system defaults when IDField is not 'id' and the alternative does not already exist", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", idField="mytestobject_id", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.mytestobject_id ?: "" ).toBe( {
					  name         = "mytestobject_id"
					, type         = "string"
					, pk           = true
					, generate     = "insert"
					, generator    = "UUID"
					, dbtype       = "varchar"
					, control      = "none"
					, maxLength    = 35
					, relationship = "none"
					, relatedto    = "none"
					, required     = true
					, aliases      = "id"
				} );
			} );

			it( "should leave the alternative ID field alone when it is predefined in the object", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", idField="mytestobject_id", propertyNames=["mytestobject_id"], properties={
						mytestobject_id = { name="mytestobject_id", pk=true, generator="none" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.mytestobject_id.generator ?: "" ).toBe( "none" );
			} );

			it( "should NOT add an ID field to an object that specifies @noid", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", noid=true, properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "id" ) ).toBeFalse( "ID field was created when it should not have been!" );
			} );

			it( "should NOT add a DateModified field to an object that specifies noDateModified", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", noDateModified=true, properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datemodified" ) ).toBeFalse( "DateModified field was created when it should not have been!" );
			} );

			it( "should add a DateModified field to an object that does not have one", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datemodified" ) ).toBeTrue();
				expect( dummyObj.meta.properties.datemodified ).toBe( {
					  name         = "datemodified"
					, type         = "date"
					, dbtype       = "datetime"
					, control      = "none"
					, maxLength    = 0
					, relationship = "none"
					, relatedto    = "none"
					, generator    = "none"
					, generate     = "never"
					, required     = true
					, indexes      = "datemodified"
				} );
			} );

			it( "should NOT add a DateModified field to an object that specifies an alternative DateModified field", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", datemodifiedField="lastDateModified", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datemodified" ) ).toBeFalse( "DateModified field was created when it should not have been!" );
			} );

			it( "should NOT add a DateModified field to an object that specifies noDateModified", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", noDateModified=true, properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datemodified" ) ).toBeFalse( "DateModified field was created when it should not have been!" );
			} );

			it( "should create DateModified field with system defaults when DateModifiedField is not 'DateModified' and the alternative does not already exist", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", datemodifiedField="lastDateModified", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.lastDateModified ?: "" ).toBe( {
					  name         = "lastDateModified"
					, type         = "date"
					, dbtype       = "datetime"
					, control      = "none"
					, maxLength    = 0
					, relationship = "none"
					, relatedto    = "none"
					, generator    = "none"
					, generate     = "never"
					, required     = true
					, aliases      = "datemodified"
					, indexes      = "datemodified"
				} );
			} );

			it( "should leave the alternative DateModified field alone when it is predefined in the object", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", datemodifiedField="lastDateModified", propertyNames=["lastDateModified"], properties={
						lastDateModified = { name="lastDateModified", type="numeric", dbtype="bigint" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.lastDateModified.dbtype ?: "" ).toBe( "bigint" );
			} );

			it( "should add a dateCreated field to an object that does not have one", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datecreated" ) ).toBeTrue();
				expect( dummyObj.meta.properties.datecreated ).toBe( {
					  name         = "datecreated"
					, type         = "date"
					, dbtype       = "datetime"
					, control      = "none"
					, maxLength    = 0
					, relationship = "none"
					, relatedto    = "none"
					, generator    = "none"
					, generate     = "never"
					, required     = true
					, indexes      = "datecreated"
				} );
			} );

			it( "should NOT add a dateCreated field to an object that specifies an alternative dateCreated field", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", dateCreatedField="creation_date", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datecreated" ) ).toBeFalse( "dateCreated field was created when it should not have been!" );
			} );

			it( "should NOT add a dateCreated field to an object that specifies noDateCreated", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", noDateCreated=true, properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.keyExists( "datecreated" ) ).toBeFalse( "dateCreated field was created when it should not have been!" );
			} );

			it( "should create dateCreated field with system defaults when DateCreatedField is not 'dateCreated' and the alternative does not already exist", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", dateCreatedField="creation_date", properties={} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.creation_date ?: "" ).toBe( {
					  name         = "creation_date"
					, type         = "date"
					, dbtype       = "datetime"
					, control      = "none"
					, maxLength    = 0
					, relationship = "none"
					, relatedto    = "none"
					, generator    = "none"
					, generate     = "never"
					, required     = true
					, aliases      = "datecreated"
					, indexes      = "datecreated"
				} );
			} );

			it( "should leave the alternative dateCreated field alone when it is predefined in the object", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", dateCreatedField="creation_date", propertyNames=["creation_date"], properties={
						creation_date = { name="creation_date", type="numeric", dbtype="bigint" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.creation_date.dbtype ?: "" ).toBe( "bigint" );
			} );

			it( "should add core aliases to alternative id, label, datecreated and datemofied fields", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", dateCreatedField="creation_date", dateModifiedField="updated_date", idField="mypk", labelField="title", propertyNames=["creation_date", "updated_date", "mypk", "title" ], properties={
						  creation_date = { name="creation_date", type="numeric", dbtype="bigint" }
						, updated_date  = { name="updated_date" , type="numeric", dbtype="bigint" }
						, mypk = { name="mypk", type="numeric", dbtype="bigint" }
						, title = { name="title", type="string", dbtype="varchar" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.properties.creation_date.aliases ?: "" ).toBe( "datecreated"  );
				expect( dummyObj.meta.properties.updated_date.aliases  ?: "" ).toBe( "datemodified" );
				expect( dummyObj.meta.properties.mypk.aliases          ?: "" ).toBe( "id"           );
			} );

			it( "should ensure fields with 'formula' attributes are not added to dbfieldlist and have default attributes set to blank/none", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", propertyNames=["myformulafield"], properties={
						  myformulafield = { name="myformulafield", formula="Sum( ${prefix}comments.id )" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.dbFieldList ?: "" ).toBe( "id,label,datecreated,datemodified" );
				expect( dummyObj.meta.properties.myformulafield ).toBe( {
					  name         = "myformulafield"
					, formula      = "Sum( ${prefix}comments.id )"
					, control      = "default"
					, dbtype       = "none"
					, generate     = "never"
					, generator    = "none"
					, maxlength    = 0
					, relatedto    = "none"
					, relationship = "none"
					, required     = false
					, type         = "string"
				} );
			} );

			it( "should ensure fields with 'formula' attributes are added to formulafieldlist", function(){
				var reader = getReader();
				var dummyObj = {
					meta = { name="mytestobject", propertyNames=["myformulafield"], properties={
						  myformulafield = { name="myformulafield", formula="Sum( ${prefix}comments.id )" }
					} }
				};

				reader.finalizeMergedObject( dummyObj );

				expect( dummyObj.meta.dbFieldList      ?: "" ).toBe( "id,label,datecreated,datemodified" );
				expect( dummyObj.meta.formulaFieldList ?: "" ).toBe( "myformulafield" );
			} );

		} );
	}

// PRIVATE HELPERS
	private any function getReader( string dsn="default_dsn", tablePrefix="pobj_" ) {
		mockFeatureService = createEmptyMock( "preside.system.services.features.FeatureService" );
		mockAdapterFactory = createEmptyMock( "preside.system.services.database.adapters.AdapterFactory" );
		mockAdapter        = createEmptyMock( "preside.system.services.database.adapters.MySqlAdapter" );

		mockAdapterFactory.$( "getAdapter", mockAdapter );
		mockAdapter.$( "autoCreatesFkIndexes", true );

		return new preside.system.services.presideObjects.PresideObjectReader(
			  dsn                = arguments.dsn
			, tablePrefix        = arguments.tablePrefix
			, interceptorService = _getMockInterceptorService()
			, featureService     = mockFeatureService
			, adapterFactory     = mockAdapterFactory
		);
	}

	private struct function _propertiesToStruct( required any properties ) {
		var newProps = {};

		for( var key in arguments.properties ){
			newProps[ key ] = arguments.properties[ key ];
		}

		return newProps;
	}
}
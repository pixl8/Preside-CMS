component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	public void function run() {
		describe( "listCloneableFields()", function(){
			it( "should, by default, return all fields that are not system fields, oneToMany relationships or formula fields and have no unique indexes", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectProperties" ).$args( objectName=objectName ).$results({
					  _id           = {}
					, label         = { uniqueindexes="label" }
					, _datecreated  = {}
					, _datemodified = {}
					, test          = { type="boolean", uniqueindexes="" }
					, fubar         = { relationship="many-to-one", relatedto="fubar", uniqueindexes="" }
					, crikey        = { relationship="many-to-many", relatedto="fubar", relatedvia="crikey_crumbs" }
					, oneToMany     = { relationship="one-to-many", relatedto="dang", relationshipKey="test" }
					, blah          = { formula="test" }
				});

				var cloneableFields = service.listCloneableFields( objectName );
				cloneableFields.sort( "textnocase" );

				expect( cloneableFields ).toBe( [ "crikey", "fubar", "test" ] );
			} );

			it( "should allow unique index fields and one-to-many relationships IF cloneable=true is specified on the property", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectProperties" ).$args( objectName=objectName ).$results({
					  label     = { uniqueindexes="label", cloneable=true }
					, oneToMany = { relationship="one-to-many", relatedto="dang", relationshipKey="test", cloneable=true }
				});

				var cloneableFields = service.listCloneableFields( objectName );
				cloneableFields.sort( "textnocase" );

				expect( cloneableFields ).toBe( [ "label", "oneToMany" ] );
			} );

			it( "should disallow ANY fields that have cloneable=false", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectProperties" ).$args( objectName=objectName ).$results({
					  _id           = {}
					, label         = { uniqueindexes="label" }
					, _datecreated  = {}
					, _datemodified = {}
					, test          = { type="boolean", uniqueindexes="", cloneable=false }
					, fubar         = { relationship="many-to-one", relatedto="fubar", uniqueindexes="", cloneable=false }
					, crikey        = { relationship="many-to-many", relatedto="fubar", relatedvia="crikey_crumbs", cloneable=false }
					, oneToMany     = { relationship="one-to-many", relatedto="dang", relationshipKey="test" }
					, blah          = { formula="test" }
				});

				var cloneableFields = service.listCloneableFields( objectName );
				cloneableFields.sort( "textnocase" );

				expect( cloneableFields ).toBe( [] );
			} );
		} );

		describe( "isCloneable()", function(){
			it( "should return false if the object has @clonable=false annotation", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName=objectName, attributeName="cloneable" ).$results( false );

				expect( service.isCloneable( objectName ) ).toBeFalse();
			} );

			it( "should return true if the object has @clonable=true annotation and has one or more cloneable attributes", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName=objectName, attributeName="cloneable" ).$results( true );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( [ "more", "than", "zero" ] );

				expect( service.isCloneable( objectName ) ).toBeTrue();
			} );

			it( "should return true if the object does not specify @clonable annotation and has one or more cloneable attributes", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName=objectName, attributeName="cloneable" ).$results( "" );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( [ "more", "than", "zero" ] );

				expect( service.isCloneable( objectName ) ).toBeTrue();
			} );

			it( "should return false if the object does not specify @clonable annotation but has no cloneable attributes", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName=objectName, attributeName="cloneable" ).$results( "" );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( [] );

				expect( service.isCloneable( objectName ) ).toBeFalse();
			} );

			it( "should return false if the object  has @clonable=true annotation but has no cloneable attributes", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName=objectName, attributeName="cloneable" ).$results( true );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( [] );

				expect( service.isCloneable( objectName ) ).toBeFalse();
			} );
		} );

		describe( "getCloneHandler()", function(){
			it( "return handler event specified in @cloneHandler annotation on the object", function(){
				var service    = _getService();
				var objectName = "SomeObject#CreateUUId()#";
				var cloneHandler = "some.handler.here.#CreateUUId()#";

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName=objectName, attributeName="cloneHandler" ).$results( cloneHandler );

				expect( service.getCloneHandler( objectName ) ).toBe( cloneHandler );
			} );
		} );

		describe( "cloneRecord()", function(){
			it( "should throw informative error when object is not cloneable", function(){
				var service    = _getService();
				var objectName = "nonCloneableObject#CreateUUId()#";

				service.$( "isCloneable" ).$args( objectName=objectName ).$results( false );

				expect( function(){
					service.cloneRecord(
						  objectName = objectName
						, recordId   = CreateUUId()
						, data       = {}
					)
				} ).toThrow( "preside.cloning.not.possible"  );
			} );
			it( "should call the custom clone handler for the object when defined to take care of cloning completely", function(){
				var service      = _getService();
				var objectName   = "myObject#CreateUUId()#";
				var recordId     = CreateUUId();
				var cloneHandler = "test.handler.#CreateUUId()#";
				var data         = { test="this", right=Now() };
				var newId        = CreateUUId();

				mockColdbox.$( "runEvent" ).$args(
					  event          = cloneHandler
					, private        = true
					, prePostExempt  = true
					, eventArguments = { objectName=objectName, recordId=recordId, data=data }
				).$results( newId );

				service.$( "isCloneable" ).$args( objectName=objectName ).$results( true );
				service.$( "getCloneHandler" ).$args( objectName=objectName ).$results( cloneHandler );

				expect( service.cloneRecord(
					  objectName = objectName
					, recordId   = recordId
					, data       = data
				) ).toBe( newId );
			} );

			it( "should throw an informative error when the source record does not exist", function(){
				var service    = _getService();
				var objectName = "someobject#CreateUUId()#";
				var recordId   = CreateUUId();

				service.$( "isCloneable" ).$args( objectName=objectName ).$results( true );
				service.$( "getCloneHandler" ).$args( objectName=objectName ).$results( "" );

				mockPresideObjectService.$( "selectData" ).$args( objectName=objectName, id=recordId ).$results( QueryNew( "" ) );

				expect( function(){
					service.cloneRecord(
						  objectName = objectName
						, recordId   = recordId
						, data       = {}
					)
				} ).toThrow( "preside.clone.record.not.found"  );
			} );

			it( "should merge passed data with cloneable field values from the original record for simple field values when creating the new record (i.e. non related data)", function(){
				var service         = _getService();
				var objectName      = "someobject#CreateUUId()#";
				var recordId        = CreateUUId();
				var newRecordId     = CreateUUId();
				var cloneableFields = [ "one", "two", "three" ];
				var newData         = { one=1, four=4 };
				var oldRecord       = QueryNew( "id,one,two,three,datecreated,datemodified", "varchar,varchar,varchar,varchar,date,date", [[CreateUUId(), "one", "two", "three", Now(),Now() ] ] );

				service.$( "isCloneable" ).$args( objectName=objectName ).$results( true );
				service.$( "getCloneHandler" ).$args( objectName=objectName ).$results( "" );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( cloneableFields );

				mockPresideObjectService.$( "selectData" ).$args( objectName=objectName, id=recordId ).$results( oldRecord );
				for( var prop in cloneableFields ) {
					mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectName=objectName, propertyName=prop, attributeName="relationship", defaultValue="none" ).$results( "none" );
				}

				mockPresideObjectService.$( "insertData" ).$args(
					  objectName              = objectName
					, data                    = { one=1, two="two", three="three", four=4 }
					, insertManyToManyRecords = true
					, isDraft                 = false
				).$results( newRecordId );

				expect( service.cloneRecord(
					  objectName = objectName
					, recordId   = recordId
					, data       = newData
				) ).toBe( newRecordId );
			} );

			it( "should fetch many-to-many data for cloning for cloneable many-to-many relationships that are not passed in with the data struct", function(){
				var service          = _getService();
				var objectName       = "someobject#CreateUUId()#";
				var recordId         = CreateUUId();
				var newRecordId      = CreateUUId();
				var cloneableFields  = [ "one", "two", "three", "many_to_one", "many_to_many", "many_to_many_two" ];
				var newData          = { one=1, four=4, many_to_many_two="#CreateUUId()#,#CreateUUId()#" };
				var oldRecord        = QueryNew( "id,one,two,three,many_to_one,datecreated,datemodified", "varchar,varchar,varchar,varchar,varchar,date,date", [[CreateUUId(), "one", "two", "three", CreateUUId(), Now(),Now() ] ] );
				var oldManyToManyIds = QueryNew( "id", "varchar", [[CreateUUId()],[CreateUUId()]])

				service.$( "isCloneable" ).$args( objectName=objectName ).$results( true );
				service.$( "getCloneHandler" ).$args( objectName=objectName ).$results( "" );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( cloneableFields );

				mockPresideObjectService.$( "selectData" ).$args( objectName=objectName, id=recordId ).$results( oldRecord );
				for( var prop in cloneableFields ) {
					if ( prop.findNoCase( "many" ) ) {
						if ( prop == "many_to_many" ) {
							mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectName=objectName, propertyName=prop, attributeName="relationship", defaultValue="none" ).$results( "many-to-many" );
						} else {
							mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectName=objectName, propertyName=prop, attributeName="relationship", defaultValue="none" ).$results( "many-to-one" );
						}
					} else {
						mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectName=objectName, propertyName=prop, attributeName="relationship", defaultValue="none" ).$results( "none" );
					}
				}

				mockPresideObjectService.$( "selectManyToManyData" ).$args(
					  objectName   = objectName
					, id           = recordId
					, propertyName = "many_to_many"
					, selectFields = [ "many_to_many.id" ]
				).$results( oldManyToManyIds );

				mockPresideObjectService.$( "insertData" ).$args(
					  objectName              = objectName
					, data                    = { one=1, two="two", three="three", four=4, many_to_one=oldRecord.many_to_one, many_to_many=ValueList( oldManyToManyIds.id ), many_to_many_two=newData.many_to_many_two }
					, insertManyToManyRecords = true
					, isDraft                 = false
				).$results( newRecordId );

				expect( service.cloneRecord(
					  objectName = objectName
					, recordId   = recordId
					, data       = newData
				) ).toBe( newRecordId );
			} );

			it( "should perform 'cloneRecord' operations on any cloneable one-to-many relationship records", function(){
				var service          = _getService();
				var objectName       = "someobject#CreateUUId()#";
				var recordId         = CreateUUId();
				var newRecordId      = CreateUUId();
				var cloneableFields  = [ "one", "one_to_many" ];
				var newData          = {};
				var oldRecord        = QueryNew( "id,one,datecreated,datemodified", "varchar,varchar,date,date", [[CreateUUId(), "one", Now(),Now() ] ] );

				service.$( "isCloneable" ).$args( objectName=objectName ).$results( true );
				service.$( "cloneOneToManyRecords" );
				service.$( "getCloneHandler" ).$args( objectName=objectName ).$results( "" );
				service.$( "listCloneableFields" ).$args( objectName=objectName ).$results( cloneableFields );

				mockPresideObjectService.$( "selectData" ).$args( objectName=objectName, id=recordId ).$results( oldRecord );
				mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectName=objectName, propertyName="one"        , attributeName="relationship", defaultValue="none" ).$results( "none" );
				mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectName=objectName, propertyName="one_to_many", attributeName="relationship", defaultValue="none" ).$results( "one-to-many" );

				mockPresideObjectService.$( "insertData" ).$args(
					  objectName              = objectName
					, data                    = { one="one" }
					, insertManyToManyRecords = true
					, isDraft                 = false
				).$results( newRecordId );

				expect( service.cloneRecord(
					  objectName = objectName
					, recordId   = recordId
					, data       = newData
				) ).toBe( newRecordId );

				var callLog = service.$callLog().cloneOneToManyRecords;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( {
					  objectName   = objectname
					, recordId     = recordId
					, newRecordId  = newRecordId
					, propertyName = "one_to_many"
					, isDraft      = false
				} );
			} );
		} );

		describe( "cloneOneToManyRecords()", function(){
			it( "should fetch related records and call cloneRecord() for each one, passing the new source cloned record ID in the data", function(){
				var service         = _getService();
				var objectName      = "my_object_#CreateUUId()#";
				var propertyName    = "one_to_many_prop";
				var recordId        = CreateUUId();
				var newRecordId     = CreateUUId();
				var relatedTo       = "some_other_object_#CreateUUId()#";
				var relationshipKey = "some_key";
				var dummyRecords    = QueryNew( "id", "varchar", [[CreateUUId()],[CreateUUId()],[CreateUUId()],[CreateUUId()]]);

				mockPresideObjectService.$( "selectData" ).$args(
					  objectName   = objectName
					, id           = recordId
					, selectFields = [ "#propertyName#._id as id" ]
					, forceJoins   = "inner"
				).$results( dummyRecords );

				mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args(
					  objectName = objectName
					, propertyName = propertyName
					, attributeName = "relatedTo"
				).$results( relatedTo );
				mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = propertyName
					, attributeName = "relationshipKey"
				).$results( relationshipKey );

				service.$( "cloneRecord", CreateUUId() );

				service.cloneOneToManyRecords(
					  objectName   = objectName
					, propertyName = propertyName
					, recordId     = recordId
					, newRecordId  = newRecordId
				);

				var callLog = service.$callLog().cloneRecord;
				expect( callLog.len() ).toBe( dummyRecords.recordCount );
				var i = 0;
				for( var record in dummyRecords ) {
					expect( callLog[ ++i ] ).toBe( {
						  objectName = relatedTo
						, recordId   = record.id
						, isDraft    = false
						, data       = { "#relationshipKey#"=newRecordId }
					} );
				}
			} );
		} );
	}

	private any function _getService() {
		mockPresideObjectService = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockColdbox              = CreateStub();

		mockPresideObjectService.$( "getIdField"          , "_id" );
		mockPresideObjectService.$( "getDateCreatedField" , "_datecreated" );
		mockPresideObjectService.$( "getDateModifiedField", "_datemodified" );

		var service = CreateMock( object = new preside.system.services.presideObjects.PresideObjectCloningService() );

		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$getColdbox", mockColdbox );

		return service;
	}

}
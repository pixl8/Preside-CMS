component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "listExporters()", function(){
			it( "should return array of exporters as read from the DataExporterReader", function(){
				var exporters = _getTestExporters();
				var service   = _getService( exporters );

				expect( service.listExporters() ).toBe( exporters );
			} );
		} );

		describe( "getExporterDetails()", function(){
			it( "should return the exporter as identified by passed ID", function(){
				var exporters = _getTestExporters();
				var service   = _getService( exporters );

				expect( service.getExporterDetails( "csv" ) ).toBe( exporters[2] );
			} );

			it( "should return an empty struct when the exporter does not exist", function(){
				var exporters = _getTestExporters();
				var service   = _getService( exporters );

				expect( service.getExporterDetails( CreateUUId() ) ).toBe( {} );
			} );
		} );

		describe( "exportData()", function(){
			it( "should return value generated from the given exporter's 'export' method", function(){
				var service         = _getService();
				var exporter        = "excel";
				var exporterHandler = "dataExporters.excel.export";
				var defaultFields   = {
					  selectFields = [ "one", "two", "three" ]
					, fieldTitles  = { one=CreateUUId(), two=CreateUUId(), three=CreateUUId() }
				};
				var args            = {
					  exporter     = "excel"
					, meta         = { title="My title", author="John McFee", published=Now() }
					, objectName   = "my_object"
				};
				var mockResult = CreateUUId();

				mockPresideObjectService.$( "getObjectProperties", {} );
				mockPresideObjectService.$( "getObjectAttribute", "" );
				mockColdbox.$( "handlerExists" ).$args( exporterHandler ).$results( true );
				mockColdbox.$( "runEvent", mockResult );

				service.$( "getDefaultExportFieldsForObject" ).$args( args.objectName ).$results( defaultFields );
				service.$( "_expandRelationshipFields", defaultFields.selectFields );
				service.$( "_setDefaultFieldTitles", defaultFields.fieldTitles );

				expect( service.exportData( argumentCollection=args ) ).toBe( mockResult );

				var runEventCallLog = mockColdbox.$callLog().runevent;

				expect( runEventCallLog.len() ).toBe( 1 );
				expect( runEventCallLog[1].private ).toBe( true );
				expect( runEventCallLog[1].prePostExempt ).toBe( true );
				expect( runEventCallLog[1].event ).toBe( exporterHandler );
				expect( runEventCallLog[1].eventArguments.selectFields ).toBe( defaultFields.selectFields );
				expect( runEventCallLog[1].eventArguments.fieldTitles ).toBe( defaultFields.fieldTitles );
				expect( runEventCallLog[1].eventArguments.meta ).toBe( args.meta );

				var dummyresults = [
					  QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [] )
				];
				mockPresideObjectService.$( "selectData" ).$results( dummyresults[1], dummyresults[2], dummyresults[3], dummyresults[4], dummyresults[5] );

				var result       = "";
				var resultNumber = 1;
				do {
					result = runEventCallLog[1].eventArguments.batchedRecordIterator();

					expect( result ).toBe( dummyResults[ resultNumber ] );

					resultNumber++;
				} while( result.recordCount );
			} );

			it( "should throw an informative error when the given exporter does not have a corresponding handler action", function(){
				var service         = _getService();
				var exporter        = "excel";
				var exporterHandler = "dataExporters.excel.export";
				var errorThrown     = false;
				var args            = {
					  exporter     = "excel"
					, meta         = { title="My title", author="John McFee", published=Now() }
					, objectName   = "my_object"
				};

				mockColdbox.$( "handlerExists" ).$args( exporterHandler ).$results( false );

				service.$( "getDefaultExportFieldsForObject" ).$args( args.objectName ).$results( {} );

				try {
					service.exportData( argumentCollection=args );
				} catch ( "preside.dataExporter.missing.action" e ) {
					expect( e.message ).toBe( "No 'export' action could be found for the [excel] exporter. The exporter should provide an 'export' handler action at /handlers/dataExporters/excel.cfc to process the export. See documentation for further details." );
					errorThrown = true;
				}

				expect( errorThrown ).toBeTrue( "An informative error was not thrown" );
			} );

			it( "should allow passing of a closure to process each batched recordset and potentially decorate it", function(){
				var service         = _getService();
				var exporter        = "excel";
				var exporterHandler = "dataExporters.excel.export";
				var defaultFields   = {
					  selectFields = [ "one", "two", "three" ]
					, fieldTitles  = { one=CreateUUId(), two=CreateUUId(), three=CreateUUId() }
				};
				var args = {
					  exporter           = "excel"
					, meta               = { title="My title", author="John McFee", published=Now() }
					, objectName         = "my_object"
					, recordsetDecorator = function( recordset ) { QueryAddColumn( recordset, "fubar", [ 'test' ] ); }
				};
				var mockResult = CreateUUId();

				mockPresideObjectService.$( "getObjectProperties", {} );
				mockPresideObjectService.$( "getObjectAttribute", "" );
				mockColdbox.$( "handlerExists" ).$args( exporterHandler ).$results( true );
				mockColdbox.$( "runEvent", mockResult );

				service.$( "getDefaultExportFieldsForObject" ).$args( args.objectName ).$results( defaultFields );
				service.$( "_expandRelationshipFields", defaultFields.selectFields );
				service.$( "_setDefaultFieldTitles", defaultFields.fieldTitles );

				expect( service.exportData( argumentCollection=args ) ).toBe( mockResult );

				var runEventCallLog = mockColdbox.$callLog().runevent;

				expect( runEventCallLog.len() ).toBe( 1 );
				expect( runEventCallLog[1].private ).toBe( true );
				expect( runEventCallLog[1].prePostExempt ).toBe( true );
				expect( runEventCallLog[1].event ).toBe( exporterHandler );
				expect( runEventCallLog[1].eventArguments.selectFields ).toBe( defaultFields.selectFields );
				expect( runEventCallLog[1].eventArguments.fieldTitles ).toBe( defaultFields.fieldTitles );
				expect( runEventCallLog[1].eventArguments.meta ).toBe( args.meta );

				var dummyresults = [
					  QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [ [ CreateUUId() ] ] )
					, QueryNew( 'blah', 'varchar', [] )
				];
				var expectedResults = [
					  QueryNew( 'blah,fubar', 'varchar,varchar', [ [ dummyresults[1].blah, "test" ] ] )
					, QueryNew( 'blah,fubar', 'varchar,varchar', [ [ dummyresults[2].blah, "test" ] ] )
					, QueryNew( 'blah,fubar', 'varchar,varchar', [ [ dummyresults[3].blah, "test" ] ] )
					, QueryNew( 'blah,fubar', 'varchar,varchar', [ [ dummyresults[4].blah, "test" ] ] )
					, QueryNew( 'blah', 'varchar', [] )
				];
				mockPresideObjectService.$( "selectData" ).$results( dummyresults[1], dummyresults[2], dummyresults[3], dummyresults[4], dummyresults[5] );

				var result       = "";
				var resultNumber = 1;
				do {
					result = runEventCallLog[1].eventArguments.batchedRecordIterator();

					expect( result ).toBe( expectedResults[ resultNumber ] );

					resultNumber++;
				} while( result.recordCount );
			} );
		} );

		describe( "getDefaultExportFieldsForObject()", function(){
			it( "should return the configured field list and translated field mappings when @dataExportFields is defined on the object", function(){
				var service    = _getService();
				var objectName = "my_object";
				var fieldList  = "field1,field2,field3";
				var uriRoot    = "blah.blah.#CreateUUId()#:";
				var titles     = {
					  field1 = "Field 1" & CreateUUId()
					, field2 = "Field 2" & CreateUUId()
					, field3 = "Field 3" & CreateUUId()
				};

				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "dataExportFields"
				).$results( fieldList );
				mockPresideObjectService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( uriRoot )

				service.$( "$translateResource" ).$args( uri=uriRoot & "field.field1.title", defaultValue="field1" ).$results( titles.field1 );
				service.$( "$translateResource" ).$args( uri=uriRoot & "field.field2.title", defaultValue="field2" ).$results( titles.field2 );
				service.$( "$translateResource" ).$args( uri=uriRoot & "field.field3.title", defaultValue="field3" ).$results( titles.field3 );

				var result = service.getDefaultExportFieldsForObject( objectName );

				expect( result ).toBe( {
					  selectFields = [ "field1", "field2", "field3" ]
					, fieldTitles  = titles
				} );
			} );

			it( "should return a set of fieldnames automatically parsed from the object that match auto exportable criteria. i.e. formula fields, short string fields, numerics, dates and many-to-one fields", function(){
				var service    = _getService();
				var objectName = "my_object";
				var uriRoot    = "blah.blah.#CreateUUId()#:";
				var props      = {
					  id              = { type="string", dbtype="varchar", maxlength=35 }
					, datecreated     = { type="date" }
					, longtext        = { type="string", dbtype="text" }
					, anotherlongtext = { type="string", dbtype="varchar", maxlength=801 }
					, numberField     = { type="numeric", dbtype="int" }
					, manyToOneField  = { relationship="many-to-one" }
					, oneToManyField  = { relationship="one-to-many" }
					, manyToManyField = { relationship="many-to-many" }
				};
				var propNames = [
					  "id"
					, "datecreated"
					, "longtext"
					, "anotherlongtext"
					, "numberField"
					, "manyToOneField"
					, "oneToManyField"
					, "manyToManyField"
				];
				var titles     = {
					  id             = "ID" & CreateUUId()
					, datecreated    = "Date created" & CreateUUId()
					, numberField    = "Number field" & CreateUUId()
					, manyToOneField = "Many to one" & CreateUUId()
				};

				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "dataExportFields"
				).$results( "" );
				mockPresideObjectService.$( "getObjectAttribute" ).$args(
					  objectName    = objectName
					, attributeName = "propertyNames"
				).$results( propNames );
				mockPresideObjectService.$( "getObjectProperties" ).$args( objectName ).$results( props );
				mockPresideObjectService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( uriRoot )

				service.$( "$translateResource" ).$args( uri=uriRoot & "field.id.title"            , defaultValue="id"             ).$results( titles.id             );
				service.$( "$translateResource" ).$args( uri=uriRoot & "field.datecreated.title"   , defaultValue="datecreated"    ).$results( titles.datecreated    );
				service.$( "$translateResource" ).$args( uri=uriRoot & "field.numberField.title"   , defaultValue="numberField"    ).$results( titles.numberField    );
				service.$( "$translateResource" ).$args( uri=uriRoot & "field.manyToOneField.title", defaultValue="manyToOneField" ).$results( titles.manyToOneField );

				var result = service.getDefaultExportFieldsForObject( objectName );

				expect( result ).toBe( {
					  selectFields = [ "id", "datecreated", "numberField", "manyToOneField" ]
					, fieldTitles  = titles
				} );
			} );
		} );
	}

// private helpers
	private any function _getService( array exporters=_getTestExporters() ) {
		mockDataExporterReader = createEmptyMock( "preside.system.services.dataExport.DataExporterReader" );
		mockDataExporterReader.$( "readExportersFromDirectories", arguments.exporters );

		mockPresideObjectService = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockColdbox              = createStub();

		var service = createMock( object=new preside.system.services.dataExport.DataExportService(
			  dataExporterReader = mockDataExporterReader
		) );

		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$announceInterception" );

		return service;
	}

	private array function _getTestExporters() {
		return [{
			  id = "excel"
			, title = "Excel"
			, description = "Test blah"
		},{
			  id = "csv"
			, title = "CSV"
			, description = "Test blah"
		},{
			  id = "json"
			, title = "JSON File"
			, description = "Test blah"
		}];
	}
}
component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){

		describe( "getAdapter()", function(){
			it( "should return MySQL Adapter when datasource is a MySQL DB", function(){
				var factory = _getFactory();

				var mockedDbInfo = querySim( "database_productname,database_version
				    MySql | whatever"
				);

				factory.$( "_getDbInfo" ).$args( dsn=application.dsn ).$results( mockedDbInfo );

				var adapter = factory.getAdapter( dsn = application.dsn );

				expect( GetMetaData( adapter ).name ).toBe( "preside.system.services.database.adapters.MySqlAdapter" );
			} );

			it( "should return SQL Server Adapter when datasource is a Microsoft SQL Server DB", function(){
				var factory = _getFactory();

				var mockedDbInfo = querySim( "database_productname,database_version
				    Microsoft SQL Server | 8.1.2"
				);

				factory.$( "_getDbInfo" ).$args( dsn=application.dsn ).$results( mockedDbInfo );

				var adapter = factory.getAdapter( dsn = application.dsn );

				expect( GetMetaData( adapter ).name ).toBe( "preside.system.services.database.adapters.MsSqlAdapter" );
			} );

			it( "should return SQL Server 2012 Adapter when datasource is a Microsoft SQL Server DB and version is >= 11", function(){
				var factory = _getFactory();

				var mockedDbInfo = querySim( "database_productname,database_version
				    Microsoft SQL Server | 11.1.2"
				);

				factory.$( "_getDbInfo" ).$args( dsn=application.dsn ).$results( mockedDbInfo );

				var adapter = factory.getAdapter( dsn = application.dsn );

				expect( GetMetaData( adapter ).name ).toBe( "preside.system.services.database.adapters.MsSql2012Adapter" );
			} );

			it( "should return PostgreSQL Adapter when datasource is a PostgreSQL DB", function(){
				var factory = _getFactory();

				var mockedDbInfo = querySim( "database_productname,database_version
				    PostgreSQL | whatever"
				);

				factory.$( "_getDbInfo" ).$args( dsn=application.dsn ).$results( mockedDbInfo );

				var adapter = factory.getAdapter( dsn = application.dsn );

				expect( GetMetaData( adapter ).name ).toBe( "preside.system.services.database.adapters.PostgreSqlAdapter" );
			} );

			it( "should throw error when DB is not a supported engine", function(){
				var factory = _getFactory();

				var mockedDbInfo = querySim( "database_productname,database_version
				    Some DB Engine | whatever"
				);

				factory.$( "_getDbInfo" ).$args( dsn="somedsn" ).$results( mockedDbInfo );

				expect( function(){
					factory.getAdapter( dsn="somedsn" );

				} ).toThrow( type="PresideObjects.databaseEngineNotSupported" );
			} );

			it( "should throw error when datasource does not exist", function(){
				expect( function(){
					_getFactory().getAdapter( dsn = "nonExistantDb" );

				} ).toThrow( type="PresideObjects.datasourceNotFound" );
			} );
		} );
	}

	private any function _getFactory() {
		dbInfoService = CreateMock( object=( new preside.system.services.database.DbInfoService() ) );

		var factory   = new preside.system.services.database.adapters.AdapterFactory( dbInfoService = dbInfoService, msSqlUseVarcharMaxForText = false );

		return CreateMock( object=factory );
	}
}
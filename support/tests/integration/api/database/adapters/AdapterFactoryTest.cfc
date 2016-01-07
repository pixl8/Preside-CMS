component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){

		describe( "getAdapter()", function(){
			it( "should return MySQL Adapter when datasource is a MySQL DB", function(){
				var factory = _getFactory();

				factory.$( "_getDbType" ).$args( dsn=application.dsn ).$results( "MYSQL" );

				var adapter = factory.getAdapter( dsn = application.dsn );

				expect( GetMetaData( adapter ).name ).toBe( "preside.system.services.database.adapters.MySqlAdapter" );
			} );

			it( "should return SQL Server Adapter when datasource is a Microsoft SQL Server DB", function(){
				var factory = _getFactory();

				factory.$( "_getDbType" ).$args( dsn=application.dsn ).$results( "Microsoft SQL Server" );

				var adapter = factory.getAdapter( dsn = application.dsn );

				expect( GetMetaData( adapter ).name ).toBe( "preside.system.services.database.adapters.MsSqlAdapter" );
			} );

			it( "should throw error when DB is not a supported engine", function(){
				var factory = _getFactory();

				factory.$( "_getDbType" ).$args( dsn="somedsn" ).$results( "Some DB Engine" );

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

		var factory   = new preside.system.services.database.adapters.AdapterFactory(
			  cache         = _getCachebox().getCache( "PresideSystemCache" )
			, dbInfoService = dbInfoService
		);

		return CreateMock( object=factory );
	}
}
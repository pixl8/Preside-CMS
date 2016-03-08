component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "listApplications()", function(){

			it( "should return an empty array when no applications configured", function(){
				var service = getService( [] );


				expect( service.listApplications() ).toBe( [] );
			} );

			it( "should return an array of application IDs who's features are active", function(){
				var service = getService();

				service.$( "$isFeatureEnabled" ).$args( "cms" ).$results( true );
				service.$( "$isFeatureEnabled" ).$args( "ems" ).$results( false );
				service.$( "$isFeatureEnabled" ).$args( "somefeature" ).$results( true );

				expect( service.listApplications() ).toBe( [ "cms", "test" ] );
			} );

			it( "should return an array of active application IDs that the current user has access to, when the 'limitByCurrentUser' flag is set to true", function(){
				var service = getService();

				service.$( "$isAdminUserLoggedIn", true );
				service.$( "$isFeatureEnabled"   ).$args( "cms" ).$results( true );
				service.$( "$hasAdminPermission" ).$args( "cms.access" ).$results( false );
				service.$( "$isFeatureEnabled"   ).$args( "ems" ).$results( true );
				service.$( "$hasAdminPermission" ).$args( "ems.access" ).$results( true );
				service.$( "$isFeatureEnabled"   ).$args( "somefeature" ).$results( true );
				service.$( "$hasAdminPermission" ).$args( "whatever.this.is" ).$results( true );

				expect( service.listApplications( limitByCurrentUser=true ) ).toBe( [ "ems", "test" ] );
			} );

		} );

		describe( "getDefaultApplication()", function(){
			it( "should return the first configured application that the current user has access to", function(){
				var service = getService();

				service.$( "listApplications" ).$args( limitByCurrentUser=true ).$results( [ "test", "this", "thing" ] );

				expect( service.getDefaultApplication() ).toBe( "test" );
			} );

			it( "should return an empty string when there are not applications for the current user", function(){
				var service = getService();

				service.$( "listApplications" ).$args( limitByCurrentUser=true ).$results( [] );

				expect( service.getDefaultApplication() ).toBe( "" );
			} );
		} );

		describe( "getDefaultEvent()", function(){
			it( "should return the configured default event for the passed application", function(){
				var service = getService();

				expect( service.getDefaultEvent( "test" ) ).toBe( "admin.testing.event" );
			} );

			it( "should return a default event using configuration when the configured application does not define a default event", function(){
				var service = getService();

				expect( service.getDefaultEvent( "ems" ) ).toBe( "admin.ems.index" );
			} );

			it( "should return an empty string when the application does not exist", function(){
				var service = getService();

				expect( service.getDefaultEvent( "whatever" ) ).toBe( "" );
			} );

			it( "should return the default event for the default application when no application supplied", function(){
				var service = getService();

				service.$( "getDefaultApplication", "cms" );

				expect( service.getDefaultEvent() ).toBe( "admin.siteTree" );
			} );
		} );

		describe( "getActiveApplication", function(){

			it( "should return the first application that matches regex pattern for current event, ordered by longest regex", function(){
				var service = getService();

				expect( service.getActiveApplication( "admin.ems.index" ) ).toBe( "ems" );
				expect( service.getActiveApplication( "admin.ems.something.blah" ) ).toBe( "ems" );
				expect( service.getActiveApplication( "admin.test.whatever.yes" ) ).toBe( "test" );
				expect( service.getActiveApplication( "admin.anything.else" ) ).toBe( "cms" );
			} );
		} );

		describe( "getLayout()", function(){
			it( "should return the configured layout for the passed application", function(){
				var service = getService();

				expect( service.getLayout( "cms" ) ).toBe( "admin" );
			} );

			it( "should return a layout using configuration when the configured application does not define a default event", function(){
				var service = getService();

				expect( service.getLayout( "ems" ) ).toBe( "ems" );
			} );

			it( "should return an empty string when the application does not exist", function(){
				var service = getService();

				expect( service.getLayout( "whatever" ) ).toBe( "" );
			} );

			it( "should return the layout for the default application when no application supplied", function(){
				var service = getService();

				service.$( "getDefaultApplication", "cms" );

				expect( service.getLayout() ).toBe( "admin" );
			} );
		} );
	}

// HELPERS
	private any function getService( array configuredApplications=getDefaultTestApplications() ) {
		var service = createMock( object=new preside.system.services.applications.ApplicationsService(
			  configuredApplications = arguments.configuredApplications
		) );


		return service;
	}

	private array function getDefaultTestApplications() {
		return [
		  {
			  id                 = "cms"
			, defaultEvent       = "admin.sitetree"
			, accessPermission   = "cms.access"
			, activeEventPattern = "admin\..*"
			, layout             = "admin"
		  }
		, "ems"
		, {
			  id               = "test"
			, defaultEvent     = "admin.testing.event"
			, feature          = "somefeature"
			, accessPermission = "whatever.this.is"
		  }
		];
	}

}
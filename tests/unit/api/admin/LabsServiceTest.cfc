component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "isEnabled()", function(){
			it( "should return true when the experiment mode is alwaysOn, even if the user and system default are off", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="alwaysOn" } } } );

				_stubUserPreference( svc, "off" );
				svc.$( "$getPresideSetting", "off" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeTrue();
			} );

			it( "should return false when the experiment is unknown", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOn" } } } );

				expect( svc.isEnabled( "missingExperiment" ) ).toBeFalse();
			} );

			it( "should return false for labsDefaultOff when there is no system setting and no user preference", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } } );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeFalse();
			} );

			it( "should return true for labsDefaultOn when there is no system setting and no user preference", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOn" } } } );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeTrue();
			} );

			it( "should use the system-config value when the user preference is default", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } } );

				_stubUserPreference( svc, "default" );
				svc.$( "$getPresideSetting" ).$args( category="labs", setting="datatablesOverhaul", default="" ).$results( "on" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeTrue();
			} );

			it( "should treat a yes/no switch value of 1 as on", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } } );

				svc.$( "$getPresideSetting" ).$args( category="labs", setting="datatablesOverhaul", default="" ).$results( "1" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeTrue();
			} );

			it( "should treat a yes/no switch value of 0 as off, even when the code default is on", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOn" } } } );

				svc.$( "$getPresideSetting" ).$args( category="labs", setting="datatablesOverhaul", default="" ).$results( "0" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeFalse();
			} );

			it( "should honour a user on preference over a system off default", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } } );

				_stubUserPreference( svc, "on" );
				svc.$( "$getPresideSetting" ).$args( category="labs", setting="datatablesOverhaul", default="" ).$results( "off" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeTrue();
			} );

			it( "should honour a user off preference over a system on default", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOn" } } } );

				_stubUserPreference( svc, "off" );
				svc.$( "$getPresideSetting" ).$args( category="labs", setting="datatablesOverhaul", default="" ).$results( "on" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeFalse();
			} );

			it( "should cache the result on the request", function(){
				var svc = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } } );

				svc.$( "$getPresideSetting", "" );

				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeFalse();
				expect( svc.isEnabled( "datatablesOverhaul" ) ).toBeFalse();
				expect( svc.$callLog().$getPresideSetting.len() ).toBe( 1 );
			} );
		} );

		describe( "listConfigurableExperiments()", function(){
			it( "should omit experiments whose mode is alwaysOn", function(){
				var svc = _getService( { experiments={
					  datatablesOverhaul = { mode="labsDefaultOff" }
					, alreadyShipped     = { mode="alwaysOn" }
				} } );

				expect( svc.listConfigurableExperiments() ).toBe( [ "datatablesOverhaul" ] );
			} );

			it( "should report whether any configurable experiments remain", function(){
				var none = _getService( { experiments={ alreadyShipped={ mode="alwaysOn" } } } );
				var some = _getService( { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } } );

				expect( none.hasConfigurableExperiments() ).toBeFalse();
				expect( some.hasConfigurableExperiments() ).toBeTrue();
			} );
		} );

		describe( "getUserPreference()", function(){
			it( "should return default when there is no logged-in administrator", function(){
				expect( _getService().getUserPreference( "datatablesOverhaul" ) ).toBe( "default" );
			} );

			it( "should normalize an invalid stored value to default", function(){
				var svc = _getService();

				_stubUserPreference( svc, "invalid" );

				expect( svc.getUserPreference( "datatablesOverhaul" ) ).toBe( "default" );
			} );
		} );

		describe( "saveUserPreference()", function(){
			it( "should insert a new user preference", function(){
				var svc     = _getService();
				var mockDao = createStub();

				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "$getPresideObject" ).$args( "admin_lab_preference" ).$results( mockDao );
				mockDao.$( "selectData", QueryNew( "id" ) );
				mockDao.$( "insertData", "preference-1" );

				svc.saveUserPreference( experimentId="datatablesOverhaul", value="on" );

				expect( mockDao.$callLog().insertData.len() ).toBe( 1 );
				expect( mockDao.$callLog().insertData[ 1 ][ 1 ] ).toBe( {
					  security_user = "user-1"
					, experiment    = "datatablesOverhaul"
					, value         = "on"
				} );
			} );

			it( "should update an existing user preference and clear the request cache", function(){
				var svc     = _getService();
				var mockDao = createStub();

				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "$getPresideObject" ).$args( "admin_lab_preference" ).$results( mockDao );
				mockDao.$( "selectData", QueryNew( "id", "varchar", [ [ "preference-1" ] ] ) );
				mockDao.$( "updateData", 1 );
				request._presideLabsEnabled = { datatablesOverhaul=false };

				svc.saveUserPreference( experimentId="datatablesOverhaul", value="on" );

				expect( mockDao.$callLog().updateData.len() ).toBe( 1 );
				expect( mockDao.$callLog().updateData[ 1 ].id ).toBe( "preference-1" );
				expect( mockDao.$callLog().updateData[ 1 ].data ).toBe( { value="on" } );
				expect( StructKeyExists( request._presideLabsEnabled, "datatablesOverhaul" ) ).toBeFalse();
			} );

			it( "should ignore unknown experiments", function(){
				var svc = _getService();

				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.saveUserPreference( experimentId="missing", value="on" );

				expect( StructKeyExists( svc.$callLog(), "$getPresideObject" ) ).toBeFalse();
			} );
		} );
	}

	private any function _getService( struct labsConfig ) {
		var mockHelpers = createStub();
		var svc         = CreateMock( object=new preside.system.services.admin.LabsService(
			labsConfig = arguments.labsConfig ?: { experiments={ datatablesOverhaul={ mode="labsDefaultOff" } } }
		) );

		StructDelete( request, "_presideLabsEnabled" );

		svc.$property( propertyName="$helpers", mock=mockHelpers );
		mockHelpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );
		svc.$( "$getAdminLoggedInUserId", "" );
		svc.$( "$getPresideSetting", "" );

		return svc;
	}

	private void function _stubUserPreference( required any svc, required string value ) {
		var mockDao = createStub();
		var records = "";

		arguments.svc.$( "$getAdminLoggedInUserId", "user-1" );
		arguments.svc.$( "$getPresideObject" ).$args( "admin_lab_preference" ).$results( mockDao );

		if ( arguments.value == "default" ) {
			records = QueryNew( "value" );
		} else {
			records = QueryNew( "value", "varchar", [ [ arguments.value ] ] );
		}

		mockDao.$( "selectData", records );
	}

}

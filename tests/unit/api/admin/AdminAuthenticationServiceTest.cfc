component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "eventRequiresAdminAuthentication()", function(){
			it( "requires authentication for a routable admin event", function(){
				expect( _getService().eventRequiresAdminAuthentication( "admin.devtools.terminal.index" ) ).toBeTrue();
			} );

			it( "does not require authentication for the login handler", function(){
				expect( _getService().eventRequiresAdminAuthentication( "admin.login.index" ) ).toBeFalse();
				expect( _getService().eventRequiresAdminAuthentication( "admin.login.logout" ) ).toBeFalse();
				expect( _getService().eventRequiresAdminAuthentication( "admin.login.twoStep" ) ).toBeFalse();
			} );

			it( "does not require authentication for the ajax proxy", function(){
				expect( _getService().eventRequiresAdminAuthentication( "admin.ajaxProxy.index" ) ).toBeFalse();
			} );

			it( "does not require authentication for the locale action only", function(){
				expect( _getService().eventRequiresAdminAuthentication( "admin.general.setLocale" ) ).toBeFalse();
				expect( _getService().eventRequiresAdminAuthentication( "admin.general.toggleNonLiveContent" ) ).toBeTrue();
			} );

			it( "does not require authentication for static asset download", function(){
				expect( _getService().eventRequiresAdminAuthentication( "admin.staticAssetDownload.download" ) ).toBeFalse();
			} );

			it( "does not require authentication for a public event", function(){
				expect( _getService().eventRequiresAdminAuthentication( "page.index" ) ).toBeFalse();
				expect( _getService().eventRequiresAdminAuthentication( "" ) ).toBeFalse();
			} );
		} );

		describe( "isAdminAuthenticationExempt()", function(){
			it( "keeps the existing login exemption for an admin handler", function(){
				var service = _getService();

				expect( service.isAdminAuthenticationExempt( "admin.login.forgottenPassword" ) ).toBeTrue();
				expect( service.isAdminAuthenticationExempt( "admin.datamanager.index" ) ).toBeFalse();
				expect( service.isAdminAuthenticationExempt( "page.index" ) ).toBeFalse();
			} );
		} );

		describe( "configured exemptions", function(){
			it( "exempts a configured event and its child actions", function(){
				var service = _getService( [ "admin.custom.publicHook" ] );

				expect( service.isAdminAuthenticationExempt( "admin.custom.publicHook" ) ).toBeTrue();
				expect( service.isAdminAuthenticationExempt( "admin.custom.publicHook.index" ) ).toBeTrue();
				expect( service.eventRequiresAdminAuthentication( "admin.custom.publicHook.index" ) ).toBeFalse();
			} );

			it( "matches a configured event without case sensitivity", function(){
				var service = _getService( [ "Admin.Custom.PublicHook" ] );

				expect( service.isAdminAuthenticationExempt( "admin.custom.publichook.detail" ) ).toBeTrue();
			} );

			it( "does not exempt a longer event name that only shares a prefix", function(){
				var service = _getService( [ "admin.custom.publicHook" ] );

				expect( service.isAdminAuthenticationExempt( "admin.custom.publicHooked" ) ).toBeFalse();
				expect( service.isAdminAuthenticationExempt( "admin.datamanager.index" ) ).toBeFalse();
			} );

			it( "ignores a blank entry and an entry that is not an event name", function(){
				var service = _getService( [ "", "admin" ] );

				expect( service.isAdminAuthenticationExempt( "admin.datamanager.index" ) ).toBeFalse();
				expect( service.eventRequiresAdminAuthentication( "admin.datamanager.index" ) ).toBeTrue();
			} );

			it( "allows a stateless request to a configured event", function(){
				var service = _getService( [ "admin.custom.publicHook" ] );

				expect( service.allowsStatelessRequest( "admin.custom.publicHook.index" ) ).toBeTrue();
				expect( service.backstopDeniesStatelessRequest( "admin.custom.publicHook.index" ) ).toBeFalse();
				expect( service.backstopDeniesStatelessRequest( "admin.login.index" ) ).toBeTrue();
			} );
		} );

		describe( "backstopDeniesStatelessRequest()", function(){
			it( "denies a stateless admin request", function(){
				expect( _getService().backstopDeniesStatelessRequest( "admin.login.index" ) ).toBeTrue();
				expect( _getService().backstopDeniesStatelessRequest( "admin.devtools.terminal.index" ) ).toBeTrue();
			} );

			it( "allows a stateless request for a static asset", function(){
				expect( _getService().backstopDeniesStatelessRequest( "admin.staticAssetDownload.download" ) ).toBeFalse();
			} );

			it( "ignores a stateless public request", function(){
				expect( _getService().backstopDeniesStatelessRequest( "page.index" ) ).toBeFalse();
			} );
		} );
	}

	private any function _getService( array exemptEvents=[] ) {
		var service = new preside.system.services.admin.AdminAuthenticationService();

		service.setAdminAuthenticationExemptEvents( arguments.exemptEvents );

		return service;
	}

}

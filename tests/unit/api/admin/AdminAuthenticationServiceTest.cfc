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

	private any function _getService() {
		return new preside.system.services.admin.AdminAuthenticationService();
	}

}

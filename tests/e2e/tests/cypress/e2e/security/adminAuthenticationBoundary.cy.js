// Anonymous and signed-in coverage for the admin authentication backstop.
// Redirects are not followed: the denial is the redirect to the login page.

const anonymous = ( url, options = {} ) => cy.request( {
	  url              : url
	, method           : options.method || "GET"
	, body             : options.body
	, form             : options.form
	, failOnStatusCode : false
	, followRedirect   : false
} );

const expectLoginRedirect = ( response ) => {
	expect( response.status, "anonymous admin request must not succeed" ).to.be.oneOf( [ 302, 401, 403 ] );

	const location = response.headers[ "location" ] || "";
	if ( response.status === 302 ) {
		expect( location, "denial must redirect to the admin login" ).to.include( "/admin/login" );
	}
};

describe( "Admin authentication boundary", () => {
	describe( "Anonymous requests", () => {
		it( "serves the login page", () => {
			anonymous( "/admin/login/" ).then( ( response ) => {
				expect( response.status ).to.eq( 200 );
				expect( response.body ).to.include( "name=\"password\"" );
			} );
		} );

		it( "lets logout redirect to the login page", () => {
			anonymous( "/admin/login/logout/" ).then( ( response ) => {
				expect( response.status ).to.eq( 302 );
				expect( response.headers[ "location" ] || "" ).to.include( "/admin/login" );
			} );
		} );

		it( "lets the two-factor page send an anonymous user to login", () => {
			anonymous( "/admin/login/twostep/" ).then( expectLoginRedirect );
		} );

		it( "lets a locale change redirect without sending the user to login", () => {
			anonymous( "/admin/general/setLocale/?locale=en" ).then( ( response ) => {
				expect( response.status ).to.eq( 302 );
				expect( response.headers[ "location" ] || "" ).not.to.include( "/admin/login" );
			} );
		} );

		it( "keeps the ajax proxy denial", () => {
			anonymous( "/admin/ajaxproxy/" ).then( ( response ) => {
				expect( response.status ).to.eq( 403 );
				expect( response.body.success ).to.eq( false );
			} );
		} );

		it( "still requires authentication for other general actions", () => {
			anonymous( "/admin/general/toggleNonLiveContent/" ).then( expectLoginRedirect );
		} );

		it( "still serves a legitimate core static asset", () => {
			anonymous( `/admin/staticassetdownload/download/?staticAssetPath=${ encodeURIComponent( "/preside/system/assets/css/admin/core/core.less" ) }` )
				.its( "status" ).should( "eq", 200 );
		} );

		it( "does not run an admin handler that has no authentication of its own", () => {
			anonymous( "/admin/devtools/terminal/" ).then( expectLoginRedirect );
		} );

		it( "does not run that handler when the event is supplied on the request", () => {
			anonymous( "/?event=admin.devtools.terminal.index" ).then( ( response ) => {
				expect( response.status, "the event parameter must not dispatch a different handler" ).to.eq( 200 );
				expect( response.body, "the request must fall through to the normal homepage" ).to.include( "<h1>Homepage</h1>" );
			} );
		} );
	} );

	describe( "Authenticated requests", () => {
		beforeEach( () => {
			cy.session( "superuser", () => {
				cy.superuserAdminLogin();
			} );
		} );

		it( "opens the admin homepage", () => {
			cy.visit( "/admin/" );
			cy.location( "pathname" ).should( "eq", "/admin/" );
			cy.contains( "System administrator" ).should( "be.visible" );
		} );
	} );
} );

// Regression coverage for the unauthenticated handler exposure fixes.
//
// Every request here is anonymous and read-only: ids are non-existent, so a
// vulnerable build returns an empty result rather than real data, and a fixed
// build denies the request. Redirects are not followed, because the denial is a
// redirect to the admin login and following it would hide the status.

const NONEXISTENT_ID = "00000000-0000-0000-0000-000000000000";

const anonymous = ( url, options = {} ) => cy.request( {
	  url              : url
	, method           : options.method || "GET"
	, body             : options.body
	, form             : options.form
	, failOnStatusCode : false
	, followRedirect   : false
} );

const expectDenied = ( response ) => {
	expect( response.status, "anonymous request must not succeed" ).to.be.oneOf( [ 302, 401, 403 ] );

	const location = response.headers[ "location" ] || "";
	if ( response.status === 302 ) {
		expect( location, "denial must redirect to the admin login" ).to.include( "/admin/login" );
	}
};

const expectNoJsonPayload = ( response ) => {
	const contentType = response.headers[ "content-type" ] || "";
	expect( contentType, "a denied request must not return the JSON payload" ).to.not.include( "json" );
};

describe( "Unauthenticated handler exposure", () => {
	describe( "Frontend editing", () => {
		const versionContent = {
			  object   : "security_user"
			, property : "password"
			, id       : NONEXISTENT_ID
			, version  : "0"
		};

		it( "does not return record content through the version lookup", () => {
			anonymous( `/admin/frontendediting/getVersionContent/?object=${ versionContent.object }&property=${ versionContent.property }&id=${ versionContent.id }&version=${ versionContent.version }` )
				.then( ( response ) => {
					expectDenied( response );
					expectNoJsonPayload( response );
				} );
		} );

		it( "does not return record content when the event is passed as a query parameter", () => {
			const query = new URLSearchParams( { event : "admin.frontendediting.getVersionContent", ...versionContent } ).toString();

			anonymous( `/?${ query }` ).then( ( response ) => {
				expectDenied( response );
				expectNoJsonPayload( response );
			} );
		} );

		it( "does not save content through a POST body event", () => {
			anonymous( "/", {
				  method : "POST"
				, form   : true
				, body   : {
					  event    : "admin.frontendediting.saveAction"
					, object   : "security_user"
					, property : "known_as"
					, recordId : NONEXISTENT_ID
					, content  : "security-regression-probe"
				}
			} ).then( ( response ) => {
				expectDenied( response );
				expectNoJsonPayload( response );
			} );
		} );
	} );

	describe( "Static asset download", () => {
		const download = ( assetPath ) => anonymous( `/admin/staticassetdownload/download/?staticAssetPath=${ encodeURIComponent( assetPath ) }` );

		it( "does not serve extension source files", () => {
			download( "/preside/system/assets/extension/preside-ext-sitemap/box.json" )
				.then( ( response ) => {
					expect( response.status, "extension source must not be downloadable" ).to.be.oneOf( [ 302, 401, 403, 404 ] );

					const body = typeof response.body === "string" ? response.body : JSON.stringify( response.body || "" );
					expect( body, "response must not contain extension source" ).to.not.include( '"dependencies"' );
				} );
		} );

		it( "does not serve files reached by escaping the asset directory", () => {
			download( "/preside/system/assets/../handlers/admin/StaticAssetDownload.cfc" )
				.its( "status" ).should( "be.oneOf", [ 302, 401, 403, 404 ] );
		} );

		it( "still serves legitimate core static assets", () => {
			download( "/preside/system/assets/css/admin/core/core.less" )
				.its( "status" ).should( "eq", 200 );
		} );
	} );

	describe( "Further unauthenticated endpoints", () => {
		it( "does not run a saved export", () => {
			anonymous( `/admin/datamanager/saved_export/adhocRunSavedExport/?savedExportId=${ NONEXISTENT_ID }` )
				.then( expectDenied );
		} );

		it( "does not return webflow instance options", () => {
			anonymous( `/formcontrols/webflowinstancepicker/getinstanceoptions/?webflowId=${ NONEXISTENT_ID }&selectedType=current` )
				.then( ( response ) => {
					expectDenied( response );
					expectNoJsonPayload( response );
				} );
		} );

		it( "does not resolve a page slug", () => {
			anonymous( `/formcontrols/sitetreepageslugeditor/getparentpage/?parent_page=${ NONEXISTENT_ID }` )
				.then( expectDenied );
		} );
	} );
} );

// Authenticated checks for DataManager request validation.
//
// Requests use a made-up id or a sort value that is not a real field. A fixed
// build returns the select payload, or denies the request. It does not return
// a database error page.

const NONEXISTENT_ID = "00000000-0000-0000-0000-000000000000";

const request = ( url ) => cy.request( {
	  url
	, failOnStatusCode : false
	, followRedirect   : false
} );

const expectLoginRedirect = ( response ) => {
	expect( response.status ).to.be.oneOf( [ 302, 401, 403 ] );
	if ( response.status === 302 ) {
		expect( response.headers.location || "" ).to.include( "/admin/login" );
	}
};

const expectJsonRecords = ( response ) => {
	const contentType = response.headers[ "content-type" ] || "";
	const location    = response.headers.location || "";

	expect( response.status, location ).to.eq( 200 );
	expect( contentType ).to.include( "json" );
	expect( response.body ).to.be.an( "array" );
};

describe( "DataManager request validation", () => {
	const selectUrl = ( query ) => `/admin/datamanager/getObjectRecordsForAjaxSelectControl/?${ query }`;

	it( "does not return select records to an anonymous user", () => {
		request( selectUrl( "object=security_user&maxRows=1" ) ).then( expectLoginRedirect );
	} );

	describe( "logged-in administrator", () => {
		beforeEach( () => {
			cy.session( "superuser", () => {
				cy.superuserAdminLogin();
			} );
		} );

		it( "returns select records for a real object and field sort", () => {
			request( selectUrl( "object=security_user&maxRows=1&orderBy=known_as%20asc" ) )
				.then( expectJsonRecords );
		} );

		it( "still returns select records when the sort is not a real field", () => {
			request( selectUrl( "object=security_user&maxRows=1&orderBy=known_as%20not_a_direction" ) )
				.then( expectJsonRecords );
		} );

		it( "still returns select records when the preferred value contains a quote", () => {
			request( selectUrl( `object=security_user&maxRows=1&targetIdField=id&defaultValue=${ encodeURIComponent( "o'brien" ) }` ) )
				.then( expectJsonRecords );
		} );

		it( "does not return select records for an unknown object", () => {
			request( selectUrl( "object=not_a_real_object&maxRows=1" ) ).then( ( response ) => {
				expect( response.status, response.headers.location || "" ).to.be.oneOf( [ 401, 403, 404 ] );
			} );
		} );

		it( "does not return child-grid records for an unknown object", () => {
			request( `/admin/datamanager/getChildObjectRecordsForAjaxDataTables/?object=not_a_real_object&parentId=${ NONEXISTENT_ID }&relationshipKey=parent` )
				.then( ( response ) => {
					expect( response.status ).to.be.oneOf( [ 302, 401, 403, 404 ] );
					expect( response.headers[ "content-type" ] || "" ).to.not.include( "json" );
				} );
		} );

		it( "does not open a batch edit form for a field that cannot be batch edited", () => {
			request( selectUrl( "object=security_user&maxRows=1" ) ).then( ( response ) => {
				expectJsonRecords( response );
				expect( response.body.length, "the test admin user should be selectable" ).to.be.greaterThan( 0 );

				const recordId = response.body[ 0 ].value;

				request( `/admin/datamanager/batchEditField/?object=security_user&field=id&id=${ recordId }` )
					.then( ( batchResponse ) => {
						expect( batchResponse.status, batchResponse.headers.location || "" ).to.eq( 401 );
					} );
			} );
		} );

		it( "still opens a batch edit form for a batch-editable field", () => {
			request( selectUrl( "object=security_user&maxRows=1" ) ).then( ( response ) => {
				expectJsonRecords( response );

				const recordId = response.body[ 0 ].value;

				request( `/admin/datamanager/batchEditField/?object=security_user&field=user_language&id=${ recordId }` )
					.then( ( batchResponse ) => {
						expect( batchResponse.status, batchResponse.headers.location || "" ).to.eq( 200 );
					} );
			} );
		} );
	} );
} );

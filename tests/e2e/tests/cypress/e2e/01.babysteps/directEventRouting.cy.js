describe( 'direct event routing', () => {
	it( 'should ignore an event query parameter when serving the homepage', () => {
		cy.request( '/?event=admin.login.login' ).then( ( response ) => {
			expect( response.body ).to.include( '<h1>Homepage</h1>' );
		} );
	} );

	it( 'should ignore an event form parameter when serving the homepage', () => {
		cy.request( {
			  method : 'POST'
			, url    : '/'
			, form   : true
			, body   : { event : 'admin.login.login' }
		} ).then( ( response ) => {
			expect( response.body ).to.include( '<h1>Homepage</h1>' );
		} );
	} );

	it( 'should continue to serve the admin login through its path route', () => {
		cy.request( '/admin/login/' ).then( ( response ) => {
			expect( response.body ).to.match( /First time setup|name="loginId"/ );
		} );
	} );
} );

describe('System pages', () => {
	before(() => {
		cy.ensureFrontendUserSetup();
	})

	it('Should return 401 for access denied', () => {
		cy.request( { url:'/accessdenied.html', failOnStatusCode:false } ).then( ( response ) => {
			expect(response.status).to.eq(401);
		} )
	});

	it('Should return 404 for not found', () => {
		cy.request( { url:'/zzz-this-is-a-link-should-not-be-found.html', failOnStatusCode:false } ).then( ( response ) => {
			expect(response.status).to.eq(404);
		} )
	});

	it('Should be able to login successfully if page exist', () => {
		cy.visit( '/' );
		cy.get( 'body .header' ).then( ( $header ) => {
			if ( $header.text().includes( 'Login' ) ) {
				cy.get( 'body .header' ).contains( 'Login' ).click();
				cy.wait( 500 );
				cy.userFrontendLogin();
				cy.location( 'pathname' ).should( 'eq', '/' );
			}
		} );
	});
});
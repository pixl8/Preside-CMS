describe( 'Admin site tree search', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitSiteTree();
	} );

	it( 'offers typeahead suggestions for the homepage title', () => {
		cy.get( '#sitetree-search-box' ).should( 'be.visible' ).type( 'Home' );
		cy.get( '.tt-suggestion', { timeout: 15000 } ).should( 'be.visible' ).should( 'contain.text', 'Homepage' );
	} );
} );

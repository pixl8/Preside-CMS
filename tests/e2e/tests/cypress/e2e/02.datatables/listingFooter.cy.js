describe( 'Application listing footer spec', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
	} );

	it( 'renders a column-mapped footer that follows visible columns', () => {
		cy.get( 'tfoot.listing-mapped-footer', { timeout : 15000 } ).should( 'be.visible' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'E2E column totals' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-status-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-category-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'not.contain.text', 'e2e-notes-footer' );

		cy.toggleListingColumn( 'Category' );
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'not.contain.text', 'Category' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'E2E column totals' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-status-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'not.contain.text', 'e2e-category-footer' );

		cy.toggleListingColumn( 'Notes' );
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'contain.text', 'Notes' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-notes-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-status-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'not.contain.text', 'e2e-category-footer' );
	} );
} );

describe( 'Application listing footer spec', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
	} );

	it( 'renders footer cells for the object default columns', () => {
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.get( 'tfoot.listing-mapped-footer', { timeout : 15000 } ).should( 'be.visible' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'E2E column totals' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-status-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-category-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'not.contain.text', 'e2e-notes-footer' );
	} );

	it( 'renders footer cells for extra grid fields on a dedicated object', () => {
		cy.visitObjectListing( 'my_extension_notes_object' );

		cy.get( 'tfoot.listing-mapped-footer', { timeout : 15000 } ).should( 'be.visible' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'E2E column totals' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-status-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-category-footer' );
		cy.get( 'tfoot.listing-mapped-footer' ).should( 'contain.text', 'e2e-notes-footer' );
	} );
} );

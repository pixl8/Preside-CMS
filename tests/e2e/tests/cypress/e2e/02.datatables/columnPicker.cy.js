describe( 'Listing column picker', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'hides a column and keeps that preference after reload', () => {
		cy.resetListingColumns();
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'contain.text', 'Category' );

		cy.toggleListingColumn( 'Category' );
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'not.contain.text', 'Category' );

		cy.reloadAfterListingColumnSave();
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Category' );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Label' );
	} );
} );

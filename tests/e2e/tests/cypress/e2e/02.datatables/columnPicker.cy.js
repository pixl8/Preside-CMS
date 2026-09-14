describe( 'Listing column picker', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'hides a column and keeps that preference after reload', () => {
		cy.resetListingColumns();
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'contain.text', 'Category' );

		cy.get( 'button[aria-label="Columns"]' ).click();
		cy.get( '.listing-colvis-list, .dtcc-list' ).should( 'be.visible' );

		cy.contains( '.listing-colvis-list label, .dtcc-list label, .dtcc-button', 'Category' )
			.closest( 'label, button, div' )
			.find( 'input[type=checkbox], .dtcc-button' )
			.first()
			.click( { force : true } );

		cy.get( 'body' ).click( 0, 0 );
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'not.contain.text', 'Category' );

		cy.wait( 800 );
		cy.reload();
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Category' );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Label' );
	} );
} );

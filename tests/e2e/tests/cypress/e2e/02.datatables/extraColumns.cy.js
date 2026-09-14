describe( 'Application extra listing columns', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
	} );

	it( 'makes non-default columns available in the picker and showable', () => {
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E-NOTES-ALPHA-01' );

		cy.get( 'button[aria-label="Columns"]' ).click();
		cy.get( '.listing-colvis-list, .dtcc-list' ).should( 'be.visible' );
		cy.contains( '.listing-colvis-list label, .dtcc-list label', 'Notes' )
			.should( 'be.visible' )
			.find( 'input[type=checkbox].listing-column-toggle' )
			.should( 'not.be.checked' )
			.click( { force : true } );
		cy.get( 'body' ).click( 0, 0 );

		cy.wait( 800 );
		cy.reload();
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E-NOTES-ALPHA-01' );
	} );
} );

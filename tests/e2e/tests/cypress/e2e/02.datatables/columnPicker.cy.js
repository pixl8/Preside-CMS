describe( 'Listing column picker', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'marks default columns as checked and extra columns as unchecked', () => {
		cy.resetListingColumns();
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Category' );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );

		cy.openListingColumnPicker();
		cy.contains( '.listing-colvis-list .listing-column-row label', 'Category' )
			.find( 'input[type=checkbox].listing-column-toggle' )
			.should( 'be.checked' );
		cy.contains( '.listing-colvis-list .listing-column-row label', 'Notes' )
			.find( 'input[type=checkbox].listing-column-toggle' )
			.should( 'not.be.checked' );
	} );
} );

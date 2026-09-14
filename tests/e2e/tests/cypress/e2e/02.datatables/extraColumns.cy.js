describe( 'Application extra listing columns', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'keeps non-default columns out of the listing but available in the picker', () => {
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E-NOTES-ALPHA-01' );

		cy.openListingColumnPicker();
		cy.get( '.listing-colvis-list' ).should( 'contain.text', 'Notes' );
		cy.contains( '.listing-colvis-list .listing-column-row label', 'Notes' )
			.find( 'input[type=checkbox].listing-column-toggle' )
			.should( 'not.be.checked' );
	} );

	it( 'shows extra columns when they are configured as grid fields', () => {
		cy.visitObjectListing( 'my_extension_notes_object' );

		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E-NOTES-ALPHA-01' );
	} );

	it( 'expands wildcard picker fields and honours exclusions', () => {
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
		cy.openListingColumnPicker();

		cy.get( '.listing-colvis-list' ).should( 'contain.text', 'Notes' );
		cy.get( '.listing-colvis-list' ).should( 'contain.text', 'E2E date modified' );
		cy.get( '.listing-colvis-list' ).should( 'not.contain.text', 'E2E sensitive col' );
		cy.get( '.listing-colvis-list' ).should( 'not.contain.text', 'E2E other sensitive col' );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'E2E sensitive col' );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'E2E other sensitive col' );
	} );
} );

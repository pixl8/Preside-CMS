describe( 'Application extra listing columns', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
	} );

	it( 'makes non-default columns available in the picker and showable', () => {
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E-NOTES-ALPHA-01' );

		cy.toggleListingColumn( 'Notes' );
		cy.get( '.object-listing-table thead', { timeout : 10000 } ).should( 'contain.text', 'Notes' );

		cy.reloadAfterListingColumnSave();
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E-NOTES-ALPHA-01' );
	} );

	it( 'expands wildcard picker fields and honours exclusions', () => {
		cy.openListingColumnPicker();

		cy.get( '.listing-colvis-list' ).should( 'contain.text', 'Notes' );
		cy.get( '.listing-colvis-list' ).should( 'contain.text', 'E2E date modified' );
		cy.get( '.listing-colvis-list' ).should( 'not.contain.text', 'E2E sensitive col' );
		cy.get( '.listing-colvis-list' ).should( 'not.contain.text', 'E2E other sensitive col' );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'E2E sensitive col' );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'E2E other sensitive col' );
	} );
} );

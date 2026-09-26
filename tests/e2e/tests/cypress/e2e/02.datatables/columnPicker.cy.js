describe( 'Listing column picker', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
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

	it( 'groups visible columns above hidden ones and only visible columns can be dragged', () => {
		cy.resetListingColumns();
		cy.openListingColumnPicker();

		cy.get( '.listing-colvis-visible .listing-column-row' ).should( 'have.length.greaterThan', 0 );
		cy.get( '.listing-colvis-hidden .listing-column-drag:not(.is-placeholder)' ).should( 'not.exist' );
		cy.contains( '.listing-colvis-hidden .listing-column-row label', 'Notes' )
			.find( 'input[type=checkbox].listing-column-toggle' )
			.check();

		cy.contains( '.listing-colvis-visible .listing-column-row label', 'Notes' ).should( 'be.visible' );
		cy.contains( '.listing-colvis-visible .listing-column-row', 'Notes' )
			.find( '.listing-column-drag:not(.is-placeholder)' )
			.should( 'exist' );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
	} );
} );

describe( 'Everything bar saved filters', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
		cy.visitObjectListing( 'my_extension_object' );
		cy.openEverythingBar();
	} );

	it( 'groups saved filters as favourites, segmentation, folders, then uncategorised, with icons', () => {
		cy.everythingBarGroups().should( ( groups ) => {
			expect( groups ).to.deep.equal( [
				'Favourites',
				'Views',
				'Segmentation filters',
				'Alpha folder',
				'Subscriptions',
				'Uncategorised filters'
			] );
		} );

		cy.get( '.everything-bar-group' ).eq( 0 ).find( 'i.fa-heart' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 1 ).find( 'i.fa-th-list' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 2 ).find( 'i.fa-sitemap' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 3 ).find( 'i.fa-folder' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 4 ).find( 'i.fa-folder' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 5 ).find( 'i.fa-filter' ).should( 'exist' );

		cy.contains( '.everything-bar-item', 'Default' ).should( 'be.visible' );
		cy.contains( '.everything-bar-item', 'Starred alphas' ).should( 'be.visible' );
		cy.contains( '.everything-bar-item', 'Professors' ).should( 'contain.text', '(22)' );
		cy.contains( '.everything-bar-item', 'Foldered alphas' ).scrollIntoView().should( 'be.visible' );
		cy.contains( '.everything-bar-item', 'Active pro rata subscriptions' ).scrollIntoView().should( 'be.visible' );
		cy.contains( '.everything-bar-item', 'Loose other filter' ).scrollIntoView().should( 'be.visible' );
	} );

	it( 'filters the dropdown by folder name', () => {
		cy.get( '.everything-bar-input' ).type( 'sub' );

		cy.contains( '.everything-bar-item', /Search records for/ ).should( 'be.visible' );
		cy.everythingBarGroups().should( ( groups ) => {
			expect( groups ).to.deep.equal( [ 'Subscriptions' ] );
		} );
		cy.contains( '.everything-bar-item', 'Active pro rata subscriptions' ).should( 'be.visible' );
		cy.contains( '.everything-bar-item', 'Starred alphas' ).should( 'not.exist' );
	} );

	it( 'applies and removes a saved filter as a chip', () => {
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();

		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Other 01' );

		cy.get( '.everything-chip-saved .everything-chip-remove' ).click();
		cy.get( '.everything-chip-saved' ).should( 'not.exist' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 10 );
	} );
} );

describe( 'Everything bar saved filters', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
		cy.visitObjectListing( 'my_extension_object' );
		cy.openEverythingBar();
	} );

	it( 'shows favourites expanded above collapsed filter folders, segmentation, and views', () => {
		cy.everythingBarSections().should( ( sections ) => {
			expect( sections ).to.deep.equal( [
				'Favourites',
				'Segmentation filters',
				'Alpha folder',
				'Subscriptions',
				'Uncategorised filters',
				'Views'
			] );
		} );

		cy.get( '.everything-bar-group' ).eq( 0 ).find( 'i.fa-heart' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 1 ).find( 'i.fa-sitemap' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 2 ).find( 'i.fa-folder' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 3 ).find( 'i.fa-folder' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 4 ).find( 'i.fa-filter' ).should( 'exist' );
		cy.get( '.everything-bar-group' ).eq( 5 ).find( 'i.fa-th-list' ).should( 'exist' );

		cy.contains( '.everything-bar-group', 'Favourites' ).should( 'have.attr', 'aria-expanded', 'true' );
		cy.get( '.everything-bar-group' ).not( ':contains("Favourites")' ).should( 'have.attr', 'aria-expanded', 'false' );
		cy.contains( '.everything-bar-item', 'Starred alphas' ).should( 'be.visible' );
		cy.contains( '.everything-bar-group', 'Favourites' ).click();
		cy.contains( '.everything-bar-group', 'Favourites' ).should( 'have.attr', 'aria-expanded', 'false' );
		cy.contains( '.everything-bar-item', 'Starred alphas' ).should( 'not.exist' );
		cy.contains( '.everything-bar-group', 'Favourites' ).click();
		cy.contains( '.everything-bar-group', 'Favourites' ).should( 'have.attr', 'aria-expanded', 'true' );

		cy.expandEverythingBarSection( 'Alpha folder' );
		cy.contains( '.everything-bar-item', 'Foldered alphas' ).should( 'be.visible' );
		cy.expandEverythingBarSection( 'Subscriptions' );
		cy.contains( '.everything-bar-item', 'Active pro rata subscriptions' ).should( 'be.visible' );
		cy.expandEverythingBarSection( 'Uncategorised filters' );
		cy.contains( '.everything-bar-item', 'Loose other filter' ).should( 'be.visible' );
		cy.expandEverythingBarSection( 'Segmentation filters' );
		cy.contains( '.everything-bar-item', 'Professors' ).should( 'contain.text', '(22)' );
		cy.expandEverythingBarSection( 'Views' );
		cy.contains( '.everything-bar-item', 'Default' ).should( 'be.visible' );
	} );

	it( 'expands matching folders while searching, then restores manual expansion state', () => {
		cy.expandEverythingBarSection( 'Alpha folder' );
		cy.get( '.everything-bar-input' ).type( '{esc}' );
		cy.get( '.everything-bar-dropdown' ).should( 'have.class', 'hide' );
		cy.openEverythingBar();
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.attr', 'aria-expanded', 'true' );

		cy.get( '.everything-bar-input' ).type( 'sub' );

		cy.contains( '.everything-bar-item', /Search records for/ ).should( 'be.visible' );
		cy.everythingBarSections().should( ( sections ) => {
			expect( sections ).to.deep.equal( [ 'Subscriptions' ] );
		} );
		cy.contains( '.everything-bar-group', 'Subscriptions' ).should( 'have.attr', 'aria-expanded', 'true' );
		cy.contains( '.everything-bar-item', 'Active pro rata subscriptions' ).should( 'be.visible' );
		cy.contains( '.everything-bar-item', 'Starred alphas' ).should( 'not.exist' );

		cy.get( '.everything-bar-input' ).clear();
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.attr', 'aria-expanded', 'true' );
		cy.contains( '.everything-bar-group', 'Subscriptions' ).should( 'have.attr', 'aria-expanded', 'false' );

		cy.get( '.everything-bar-input' ).type( 'pro rata' );
		cy.everythingBarSections().should( ( sections ) => {
			expect( sections ).to.deep.equal( [ 'Subscriptions' ] );
		} );
		cy.contains( '.everything-bar-item', 'Active pro rata subscriptions' ).should( 'be.visible' );
	} );

	it( 'supports tree keyboard navigation and exposes virtual focus', () => {
		cy.get( '.everything-bar-input' )
			.should( 'have.attr', 'role', 'combobox' )
			.and( 'have.attr', 'aria-expanded', 'true' )
			.type( '{downarrow}' );

		cy.contains( '.everything-bar-group', 'Favourites' )
			.should( 'have.class', 'is-highlighted' )
			.and( 'have.attr', 'aria-selected', 'true' );
		cy.get( '.everything-bar-input' ).should( 'have.attr', 'aria-activedescendant' );

		cy.get( '.everything-bar-input' ).type( '{downarrow}' );
		cy.contains( '.everything-bar-item', 'Starred alphas' ).should( 'have.class', 'is-highlighted' );

		cy.get( '.everything-bar-input' ).type( '{downarrow}{downarrow}{rightarrow}' );
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.attr', 'aria-expanded', 'true' );
		cy.get( '.everything-bar-input' ).type( '{downarrow}' );
		cy.contains( '.everything-bar-item', 'Foldered alphas' ).should( 'have.class', 'is-highlighted' );
		cy.get( '.everything-bar-input' ).type( '{leftarrow}' );
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.class', 'is-highlighted' );
		cy.get( '.everything-bar-input' ).type( '{leftarrow}' );
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.attr', 'aria-expanded', 'false' );
		cy.get( '.everything-bar-input' ).type( ' ' );
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.attr', 'aria-expanded', 'true' );
		cy.get( '.everything-bar-input' ).type( '{enter}' );
		cy.contains( '.everything-bar-group', 'Alpha folder' ).should( 'have.attr', 'aria-expanded', 'false' );

		cy.get( '.everything-bar-input' ).type( '{esc}' ).should( 'have.attr', 'aria-expanded', 'false' );
		cy.get( '.everything-bar-dropdown' ).should( 'have.class', 'hide' );
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

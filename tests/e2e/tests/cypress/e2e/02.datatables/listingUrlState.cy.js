describe( 'Listing URL state', () => {
	const listingUrlParam = /lst[0-9a-f]{8}=/;

	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'writes saved filters to a table-specific URL param and restores them on load', () => {
		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();

		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.location( 'search' ).should( 'match', listingUrlParam );

		cy.url().then( ( url ) => {
			cy.clearListingTableState();
			cy.visit( url );
			cy.get( '.everything-chip-saved', { timeout : 20000 } ).should( 'contain.text', 'Starred alphas' );
			cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length', 5 );
			cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
			cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Other 01' );
		} );
	} );

	it( 'writes search to the URL and restores it on reload', () => {
		cy.get( '.everything-bar-input' ).click().type( 'E2E Alpha' );
		cy.contains( '.everything-bar-item', /Search records for/ ).click();

		cy.get( '.everything-chip-search' ).should( 'contain.text', 'E2E Alpha' );
		cy.location( 'search' ).should( 'match', listingUrlParam );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.reload();
		cy.get( '.everything-chip-search', { timeout : 20000 } ).should( 'contain.text', 'E2E Alpha' );
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );
	} );

	it( 'writes sort order to the URL and restores it on reload', () => {
		cy.get( 'th[data-field="label"] button[aria-label="Toggle ordering"], th[data-field="label"] .dtcc-button_order' )
			.first()
			.click();

		cy.location( 'search', { timeout : 15000 } ).should( 'match', listingUrlParam );
		cy.get( 'th[data-field="label"]', { timeout : 15000 } ).should( 'satisfy', ( $th ) => {
			const cls  = $th.attr( 'class' ) || '';
			const aria = $th.attr( 'aria-sort' ) || '';
			return /sorting_|dt-ordering-|asc|desc/.test( cls ) || /ascending|descending/.test( aria );
		} );

		cy.get( 'th[data-field="label"]' ).then( ( $th ) => {
			const aria = $th.attr( 'aria-sort' ) || '';
			const cls  = $th.attr( 'class' ) || '';

			cy.reload();
			cy.get( 'th[data-field="label"]', { timeout : 20000 } ).should( 'satisfy', ( $reloaded ) => {
				const reloadedAria = $reloaded.attr( 'aria-sort' ) || '';
				const reloadedCls  = $reloaded.attr( 'class' ) || '';
				if ( aria ) {
					return reloadedAria === aria;
				}
				return reloadedCls === cls || /sorting_|dt-ordering-|asc|desc/.test( reloadedCls );
			} );
		} );
	} );

	it( 'keeps filter changes in browser history', () => {
		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.location( 'search' ).should( 'match', listingUrlParam );

		cy.get( '.everything-chip-saved .everything-chip-remove' ).click();
		cy.get( '.everything-chip-saved' ).should( 'not.exist' );

		cy.go( 'back' );
		cy.get( '.everything-chip-saved', { timeout : 20000 } ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length', 5 );
	} );

	it( 'restores last used filters when returning to the listing without using back', () => {
		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.visit( '/admin/' );
		cy.visit( '/admin/datamanager/object/?id=my_extension_object' );

		cy.get( '.everything-chip-saved', { timeout : 20000 } ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Other 01' );
	} );
} );

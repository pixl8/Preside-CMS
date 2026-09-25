describe( 'Legacy listing when Labs is off', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'off' );
		cy.visitObjectListing( 'my_extension_object' );
	} );

	afterEach( () => {
		cy.setListingLabPreference( 'default' );
	} );

	it( 'loads the stable search well without the Everything bar', () => {
		cy.get( '.object-listing-everything-bar' ).should( 'not.exist' );
		cy.get( 'button[aria-label="Columns"]' ).should( 'not.exist' );
		cy.get( '.listing-views-toggle' ).should( 'not.exist' );
		cy.get( '.data-table-search' ).should( 'be.visible' );
		cy.get( '.well.well-sm' ).should( 'exist' );
		cy.get( '.object-listing-table tbody tr' ).should( 'have.length.greaterThan', 0 );
	} );

	it( 'loads only the stable DataTables runtime and assets', () => {
		cy.get( 'script[src*="plugins-1.8.004.min.js"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="datatables-1.9.4.min.js"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="datatables-3.0.4.min.js"]' ).should( 'not.exist' );
		cy.get( 'script[src*="/presidecore/"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="/datatablesCore/"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="/datatablesCoreModern/"]' ).should( 'not.exist' );
		cy.get( 'script[src*="objectModern"]' ).should( 'not.exist' );
		cy.window().then( ( win ) => {
			expect( win.presideJQuery.fn.dataTableExt.sVersion ).to.match( /^1\./ );
		} );
	} );

	it( 'searches records with the stable DataTables search input', () => {
		cy.get( '.data-table-search' ).clear().type( 'E2E Alpha' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );
	} );

	it( 'paginates and sorts with the stable controls', () => {
		cy.get( '.object-listing-table tbody tr' ).should( 'have.length', 10 );
		cy.get( '.dataTables_paginate .next:not(.disabled) a' ).first().click();
		cy.contains( '.dataTables_info', /Showing 11 to/ ).should( 'be.visible' );

		cy.get( 'th[data-field="label"]' ).first().click();
		cy.get( 'th[data-field="label"]' ).should( 'have.class', 'sorting_asc' );
	} );

	it( 'keeps static tables on the stable runtime', () => {
		cy.visit( '/admin/emailcenter/systemtemplates/' );
		cy.get( 'table.static-data-table' ).should( 'be.visible' );
		cy.get( '.dataTables_wrapper input.data-table-search' ).should( 'be.visible' );
		cy.get( '.dt-container, .dtcc-button_order' ).should( 'not.exist' );
	} );

	it( 'keeps asset manager on its stable DataTable implementation', () => {
		cy.visit( '/admin/assetmanager/' );
		cy.get( '#asset-listing-table.asset-listing-table' ).should( 'be.visible' );
		cy.get( '#asset-listing-table_wrapper.dataTables_wrapper' ).should( 'exist' );
		cy.get( '.dt-container, .dtcc-button_order' ).should( 'not.exist' );
		cy.get( '.info-bar' ).should( 'be.visible' );
	} );

	it( 'switches the whole request back to the modern stack', () => {
		cy.setListingLabPreference( 'on' );
		cy.visitObjectListing( 'my_extension_object' );

		cy.get( 'script[src*="plugins-1.8.004.min.js"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="datatables-3.0.4.min.js"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="datatables-1.9.4.min.js"]' ).should( 'not.exist' );
		cy.get( 'script[src*="/presidecore/"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="/datatablesCoreModern/"]' ).should( 'have.length', 1 );
		cy.get( 'script[src*="/datatablesCore/"]' ).should( 'not.exist' );
		cy.get( '.everything-bar-input' ).should( 'be.visible' );
		cy.window().then( ( win ) => {
			expect( win.presideJQuery.fn.dataTable.version ).to.match( /^3\./ );
		} );
	} );
} );

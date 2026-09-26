describe( 'Asset manager listing', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
		cy.visit( '/admin/assetmanager/' );
	} );

	it( 'initialises as a DataTable with ColumnControl order icons and no everything bar', () => {
		cy.get( '#asset-listing-table.asset-listing-table' ).should( 'be.visible' );
		cy.get( '.dt-container, .dataTables_wrapper' ).should( 'exist' );
		cy.get( '.everything-bar-input' ).should( 'not.exist' );

		cy.get( '#asset-listing-table thead th[data-field="title"] button[aria-label="Toggle ordering"], #asset-listing-table thead th[data-field="title"] .dtcc-button_order' )
			.should( 'exist' );

		cy.get( '#asset-listing-table thead th.center .dtcc-button_order' ).should( 'not.exist' );
		cy.get( '.info-bar' ).should( 'be.visible' );
	} );
} );

describe( 'Static DataTables', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
		cy.visit( '/admin/emailcenter/systemtemplates/' );
	} );

	it( 'uses the shared search bar, card listing chrome, and ColumnControl sort', () => {
		cy.get( 'table.static-data-table' ).should( 'be.visible' );
		cy.get( '.dt-container .dt-search input.data-table-search, .dataTables_wrapper input.data-table-search' )
			.should( 'be.visible' )
			.and( 'have.attr', 'placeholder' );
		cy.get( '.dt-search .data-table-search-icon, .data-table-search-icon.fa-search' ).should( 'exist' );

		cy.get( 'table.static-data-table tbody tr' ).its( 'length' ).then( ( count ) => {
			expect( count ).to.be.greaterThan( 1 );
			cy.get( '.dt-search input.data-table-search, input.data-table-search' ).first().type( 'zzzz-no-such-template' );
			cy.get( 'table.static-data-table tbody' ).should( 'contain.text', 'No record' );
			cy.get( '.dt-search input.data-table-search, input.data-table-search' ).first().clear();
			cy.get( 'table.static-data-table tbody tr' ).should( 'have.length', count );
		} );

		cy.get( 'table.static-data-table thead button[aria-label="Toggle ordering"], table.static-data-table thead .dtcc-button_order' )
			.should( 'have.length.greaterThan', 0 );
	} );
} );

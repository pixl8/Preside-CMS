describe( 'Object listing DataTable', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'renders the everything bar, records, and listing chrome', () => {
		cy.get( '.everything-bar-input' )
			.should( 'be.visible' )
			.and( 'have.attr', 'placeholder' )
			.and( 'match', /Search.*views/i );

		cy.get( '.everything-bar-icon.fa-search, .data-table-search-icon.fa-search' ).should( 'exist' );
		cy.get( '.object-listing-table tbody tr' ).should( 'have.length', 10 );
		cy.contains( '.dt-info, .dataTables_info', /Showing 1 to 10 of 2[0-9] records/ ).should( 'be.visible' );

		cy.get( '.advanced-filter-toggle' ).should( 'contain.text', 'Advanced filter' );
		cy.get( 'th.listing-data-column button[aria-label="Toggle ordering"], th.listing-data-column .dtcc-button_order' )
			.should( 'have.length.greaterThan', 0 );
		cy.get( 'button[aria-label="Columns"]' ).should( 'be.visible' );
	} );

	it( 'searches records from the everything bar', () => {
		cy.get( '.everything-bar-input' ).click().type( 'E2E Alpha' );
		cy.get( '.everything-bar-dropdown' ).should( 'not.have.class', 'hide' );
		cy.contains( '.everything-bar-item', /Search records for/ ).click();

		cy.get( '.everything-chip-search' ).should( 'contain.text', 'E2E Alpha' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );
	} );

	it( 'paginates server-side results', () => {
		cy.get( '.object-listing-table tbody tr' ).should( 'have.length', 10 );
		cy.get( '[aria-label="Next"]' ).first().scrollIntoView().click();
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length.greaterThan', 0 );
		cy.contains( '.dt-info, .dataTables_info', /Showing 11 to/ ).should( 'be.visible' );
	} );

	it( 'sorts a column with the ColumnControl order button', () => {
		cy.get( 'th[data-field="label"] button[aria-label="Toggle ordering"], th[data-field="label"] .dtcc-button_order' )
			.first()
			.click();

		cy.get( '.object-listing-table tbody tr:first', { timeout : 15000 } ).should( 'contain.text', 'E2E' );
		cy.get( 'th[data-field="label"]' ).should( 'satisfy', ( $th ) => {
			const cls = $th.attr( 'class' ) || '';
			const aria = $th.attr( 'aria-sort' ) || '';
			return /sorting_|dt-ordering-|asc|desc/.test( cls ) || /ascending|descending/.test( aria );
		} );
	} );
} );

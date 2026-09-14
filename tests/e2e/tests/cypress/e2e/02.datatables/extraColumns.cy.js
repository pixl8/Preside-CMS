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

	it( 'fetches extra column data when a hidden column is shown', () => {
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E-NOTES-ALPHA-01' );

		cy.intercept( 'POST', /getObjectRecordsForAjaxDataTables/ ).as( 'listingAjax' );
		cy.showListingColumn( 'Notes' );

		cy.wait( '@listingAjax' ).then( ( interception ) => {
			const body       = interception.request.body;
			const gridFields = typeof body === 'string'
				? ( new URLSearchParams( body ).get( 'gridFields' ) || '' )
				: String( body.gridFields || '' );

			expect( gridFields.split( ',' ).map( ( field ) => field.trim() ) ).to.include( 'notes' );
		} );
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

	it( 'does not return excluded columns when they are posted to the listing ajax request', () => {
		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.get( '.object-listing-table' ).should( 'be.visible' );
		cy.get( '.listing-toolbar-data' ).invoke( 'text' ).then( ( raw ) => {
			const toolbar = JSON.parse( raw || '{}' );

			cy.get( '.object-listing-table' ).invoke( 'attr', 'data-datasource-url' ).then( ( url ) => {
				expect( url, 'listing ajax url' ).to.be.a( 'string' ).and.not.be.empty;

				cy.request( {
					  method : 'POST'
					, url    : url
					, form   : true
					, body   : {
						  sEcho                : 1
						, iDisplayStart        : 0
						, iDisplayLength       : 10
						, listingKey           : toolbar.listingKey || 'my_extension_object'
						, grantedGridFields    : ( toolbar.grantedColumns || [] ).join( ',' )
						, grantedGridFieldsSig : toolbar.grantedColumnsSig || ''
						, gridFields           : 'label,status,category,datecreated,notes,sensitive_col,other_sensitive_col'
					  }
				} ).then( ( response ) => {
					const payload = JSON.stringify( response.body );

					expect( payload ).to.include( 'E2E Alpha 01' );
					expect( payload ).to.not.include( 'E2E-SENSITIVE-ALPHA-01' );
					expect( payload ).to.not.include( 'E2E-OTHER-SENSITIVE-ALPHA-01' );
				} );
			} );
		} );
	} );
} );

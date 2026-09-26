describe( 'Saved listing views', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
		cy.visit( '/admin/' );
		cy.clearListingViews();
	} );

	it( 'hides the view picker when the listing flag is off', () => {
		cy.visitObjectListing( 'my_extension_notes_object' );
		cy.get( '.listing-views' ).should( 'not.exist' );
		cy.get( '.everything-bar-input' )
			.should( 'have.attr', 'placeholder' )
			.and( 'not.match', /views/i );
	} );

	it( 'saves a view, restores it after reload, and Default clears filters and columns', () => {
		const viewName = `Cypress alphas ${ Date.now() }`;

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
		cy.get( '.listing-views-toggle' ).should( 'be.visible' );
		cy.get( '.listing-views-name' ).should( 'contain.text', 'Default' );
		cy.get( '.everything-bar-input' )
			.should( 'have.attr', 'placeholder' )
			.and( 'match', /views/i );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );

		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.saveListingViewAs( viewName );

		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );
		cy.get( '.object-listing-wrap' ).should( 'have.class', 'listing-view-locked' );

		cy.intercept( 'POST', /saveListingColumns/ ).as( 'saveListingColumns' );
		cy.showListingColumn( 'Notes' );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
		cy.wait( 500 );
		cy.get( '@saveListingColumns.all' ).should( 'have.length', 0 );

		cy.closeListingOverlays();
		cy.openListingViews();
		cy.get( '[data-view-action="save-changes"]' ).should( 'not.exist' );
		cy.closeListingOverlays();

		cy.reload();
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
		cy.get( '.listing-views-name' ).should( 'contain.text', viewName );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );

		cy.editListingView();
		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'exist' );

		cy.showListingColumn( 'Notes' );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
		cy.wait( 500 );
		cy.get( '@saveListingColumns.all' ).should( 'have.length', 0 );

		cy.intercept( 'POST', /updateListingView/ ).as( 'updateListingView' );
		cy.closeListingOverlays();
		cy.openListingViews();
		cy.get( '[data-view-action="save-changes"]' ).click();
		cy.wait( '@updateListingView' ).its( 'response.statusCode' ).should( 'eq', 200 );
		cy.get( '.object-listing-wrap' ).should( 'have.class', 'listing-view-locked' );
		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );

		cy.reload();
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
		cy.get( '.listing-views-name' ).should( 'contain.text', viewName );
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E-NOTES-ALPHA-01' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.openListingViews();
		cy.get( '[data-view-action="apply"][data-view-id="default"]' ).click();
		cy.get( '.listing-views-name' ).should( 'contain.text', 'Default' );
		cy.get( '.everything-chip-saved' ).should( 'not.exist' );
		cy.get( '.object-listing-table thead' ).should( 'not.contain.text', 'Notes' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 10 );
	} );

	it( 'keeps a hidden-column filter when switching views and locks it until Edit view', () => {
		const viewName = `Cypress drafts ${ Date.now() }`;

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.filterListingColumnEquals( 'Status', 'draft' );
		cy.get( '.everything-chip-column' ).should( 'contain.text', 'draft' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Beta 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Alpha 01' );

		cy.saveListingViewAs( viewName );
		cy.get( '.everything-chip-column .everything-chip-remove' ).should( 'not.exist' );

		cy.editListingView();
		cy.hideListingColumn( 'Status' );
		cy.closeListingOverlays();
		cy.get( '.object-listing-table thead th.listing-data-column' ).should( 'not.contain.text', 'Status' );
		cy.get( '.everything-chip-column' ).should( 'contain.text', 'draft' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.intercept( 'POST', /updateListingView/ ).as( 'updateListingView' );
		cy.openListingViews();
		cy.get( '[data-view-action="save-changes"]' ).click();
		cy.wait( '@updateListingView' ).its( 'response.statusCode' ).should( 'eq', 200 );
		cy.get( '.everything-chip-column .everything-chip-remove' ).should( 'not.exist' );

		cy.openListingViews();
		cy.get( '[data-view-action="apply"][data-view-id="default"]' ).click();
		cy.get( '.listing-views-name' ).should( 'contain.text', 'Default' );
		cy.get( '.everything-chip-column' ).should( 'not.exist' );
		cy.get( '.object-listing-table thead th.listing-data-column' ).should( 'contain.text', 'Status' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 10 );

		cy.openListingViews();
		cy.contains( '.listing-views-item-label', viewName ).click();
		cy.get( '.listing-views-name' ).should( 'contain.text', viewName );
		cy.get( '.everything-chip-column' ).should( 'contain.text', 'draft' );
		cy.get( '.everything-chip-column .everything-chip-remove' ).should( 'not.exist' );
		cy.get( '.object-listing-table thead th.listing-data-column' ).should( 'not.contain.text', 'Status' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Beta 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Alpha 01' );
	} );

	it( 'allows extra search and filters on top of a locked view', () => {
		const viewName = `Cypress extras ${ Date.now() }`;

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.saveListingViewAs( viewName );

		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );
		cy.get( '.object-listing-wrap' ).should( 'have.class', 'listing-view-locked' );

		cy.get( '.everything-bar-input' ).click().type( 'E2E Alpha 01' );
		cy.contains( '.everything-bar-item', /Search records for/ ).click();
		cy.get( '.everything-chip-search' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.everything-chip-search .everything-chip-remove' ).should( 'exist' );
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 1 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );

		cy.get( '.everything-chip-search .everything-chip-remove' ).click();
		cy.get( '.everything-chip-search' ).should( 'not.exist' );
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.filterListingColumnEquals( 'Status', 'active' );
		cy.get( '.everything-chip-column' ).should( 'contain.text', 'active' );
		cy.get( '.everything-chip-column .everything-chip-remove' ).should( 'exist' );
		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.get( '.everything-chip-column .everything-chip-remove' ).click();
		cy.get( '.everything-chip-column' ).should( 'not.exist' );
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.openEverythingBar();
		cy.expandEverythingBarSection( 'Uncategorised filters' );
		cy.contains( '.everything-bar-item', 'Loose other filter' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Loose other filter' );
		cy.contains( '.everything-chip-saved', 'Starred alphas' ).find( '.everything-chip-remove' ).should( 'not.exist' );
		cy.contains( '.everything-chip-saved', 'Loose other filter' ).find( '.everything-chip-remove' ).should( 'exist' );
		cy.get( '.object-listing-table tbody', { timeout : 15000 } ).should( 'not.contain.text', 'E2E Alpha' );

		cy.contains( '.everything-chip-saved', 'Loose other filter' ).find( '.everything-chip-remove' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.everything-chip-saved' ).should( 'not.contain.text', 'Loose other filter' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
	} );

	it( 'finds and applies a view from the everything bar', () => {
		const viewName = `Cypress barview ${ Date.now() }`;

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();
		cy.saveListingViewAs( viewName );

		cy.get( '.everything-bar-input' ).click().type( 'Default' );
		cy.get( '.everything-bar-item[data-bar-action="view"]' ).should( 'contain.text', 'Default' ).click();
		cy.get( '.listing-views-name' ).should( 'contain.text', 'Default' );
		cy.get( '.everything-chip-saved' ).should( 'not.exist' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 10 );

		cy.get( '.everything-bar-input' ).click().type( viewName );
		cy.contains( '.everything-bar-group', 'Views' ).should( 'be.visible' );
		cy.get( '.everything-bar-item[data-bar-action="view"]' ).should( 'contain.text', viewName ).click();
		cy.get( '.listing-views-name' ).should( 'contain.text', viewName );
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
	} );

	it( 'saves and restores column sort with a named view', () => {
		const viewName = `Cypress sorted ${ Date.now() }`;

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();

		cy.get( 'th[data-field="label"] .dtcc-button_order' ).first().click();
		cy.get( 'th[data-field="label"]', { timeout : 15000 } ).should( 'satisfy', ( $th ) => {
			const aria = $th.attr( 'aria-sort' ) || '';
			const cls  = $th.attr( 'class' ) || '';
			return /ascending|descending/.test( aria ) || /sorting_|dt-ordering-|asc|desc/.test( cls );
		} );

		cy.saveListingViewAs( viewName );
		cy.openListingViews();
		cy.get( '[data-view-action="apply"][data-view-id="default"]' ).click();
		cy.get( '.listing-views-name' ).should( 'contain.text', 'Default' );

		cy.openListingViews();
		cy.contains( '.listing-views-item-label', viewName ).click();
		cy.get( 'th[data-field="label"]', { timeout : 15000 } ).should( 'satisfy', ( $th ) => {
			const aria = $th.attr( 'aria-sort' ) || '';
			const cls  = $th.attr( 'class' ) || '';
			return /ascending|descending/.test( aria ) || /sorting_|dt-ordering-|asc|desc/.test( cls );
		} );

		cy.reload();
		cy.get( '.listing-views-name', { timeout : 20000 } ).should( 'contain.text', viewName );
		cy.get( 'th[data-field="label"]', { timeout : 20000 } ).should( 'satisfy', ( $th ) => {
			const aria = $th.attr( 'aria-sort' ) || '';
			const cls  = $th.attr( 'class' ) || '';
			return /ascending|descending/.test( aria ) || /sorting_|dt-ordering-|asc|desc/.test( cls );
		} );
	} );

	it( 'uses a personal default assignment when Default is selected', () => {
		const viewName = `Cypress default ${ Date.now() }`;

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
		cy.openEverythingBar();
		cy.contains( '.everything-bar-item', 'Starred alphas' ).click();
		cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
		cy.saveListingViewAs( viewName );

		cy.openListingViews();
		cy.contains( 'a.listing-views-item-label', viewName )
			.invoke( 'attr', 'data-view-id' )
			.should( 'have.length.greaterThan', 0 )
			.then( ( viewId ) => {
				cy.get( '.object-listing-table' ).then( ( $table ) => {
					cy.request( {
						  method : 'POST'
						, url    : $table.attr( 'data-save-listing-view-default-url' )
						, form   : true
						, body   : {
							  object            : $table.attr( 'data-object-name' )
							, listingKey        : $table.attr( 'data-listing-key' ) || $table.attr( 'data-object-name' )
							, listingContextKey : $table.attr( 'data-listing-context-key' ) || ''
							, viewId            : viewId
							, scope             : 'individual'
						  }
					} ).its( 'body.success' ).should( 'eq', true );
				} );
			} );

		cy.reload();
		cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
		cy.get( '.listing-views-name' ).should( 'contain.text', viewName );
		cy.openListingViews();
		cy.get( '[data-view-action="apply"][data-view-id="default"]' ).should( 'not.exist' );
		cy.get( '.listing-views-dropdown' ).should( 'not.contain.text', 'using:' );
		cy.get( '[data-view-action="edit"]' ).should( 'be.visible' );
		cy.get( '[data-view-action="set-default"]' ).should( 'be.visible' );
		cy.contains( '.listing-views-item', viewName ).should( 'have.class', 'is-selected' );
		cy.contains( '.listing-views-item', viewName ).find( '.listing-views-default-badge' ).should( 'be.visible' );
		cy.get( '.listing-views-toggle' ).click();
		cy.get( '.listing-views-dropdown' ).should( 'have.class', 'hide' );
		cy.get( '.object-listing-wrap' ).should( 'have.class', 'listing-view-locked' );
		cy.get( '.everything-chip-saved', { timeout : 20000 } ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );

		cy.visit( '/admin/' );
		cy.visit( '/admin/datamanager/object/?id=my_extension_object' );
		cy.get( '.listing-views-name', { timeout : 20000 } ).should( 'contain.text', viewName );
		cy.get( '.object-listing-wrap' ).should( 'have.class', 'listing-view-locked' );
		cy.get( '.everything-chip-saved', { timeout : 20000 } ).should( 'contain.text', 'Starred alphas' );
		cy.get( '.everything-chip-saved .everything-chip-remove' ).should( 'not.exist' );
		cy.openListingViews();
		cy.get( '[data-view-action="edit"]' ).should( 'be.visible' );
	} );
} );

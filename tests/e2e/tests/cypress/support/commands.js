Cypress.Commands.add( 'superuserAdminLogin', () => {
	cy.visit( '/admin/login/' );

	cy.get( 'body' ).then( ( $body ) => {
		if ( $body.text().includes( 'First time setup' ) ) {
			 cy.get( 'input[ name=email_address ]' ).should( 'be.visible' ).type( Cypress.env( 'ADMIN_SUPERUSER_EMAIL' ) );
		    cy.get( 'input[ name=password ]' ).should( 'be.visible' ).type( Cypress.env( 'ADMIN_SUPERUSER_PASSWORD' ) );
		    cy.get( 'input[ name=passwordConfirmation ]' ).should( 'be.visible' ).type( Cypress.env( 'ADMIN_SUPERUSER_PASSWORD' ) );
		    cy.get( 'button.btn.btn-danger' ).should( 'be.visible' ).should( 'contain.text', 'Setup user' ).click();

		    cy.url().should( 'include', '/login/' );
		    cy.get( '.widget-main .alert.alert-success' ).should( 'contain.text', 'Your system administrator account has been setup.' );
		}

		cy.get( 'input[ name=loginId  ]' ).type( Cypress.env( 'ADMIN_SUPERUSER_EMAIL'    ) );
		cy.get( 'input[ name=password ]' ).type( Cypress.env( 'ADMIN_SUPERUSER_PASSWORD' ) );
		cy.get( 'button.btn.btn-primary' ).contains( 'Enter' ).click();

		cy.url().should( 'include', '/admin/' );
	});

});

Cypress.Commands.add( 'clearListingTableState', () => {
	cy.window().then( ( win ) => {
		Object.keys( win.localStorage ).forEach( ( key ) => {
			if ( key.indexOf( 'DataTables_listing_' ) === 0 || key.indexOf( 'PresideListingView_' ) === 0 ) {
				win.localStorage.removeItem( key );
			}
		} );
	} );
} );

Cypress.Commands.add( 'deleteSavedListingViews', () => {
	cy.get( '.object-listing-table' ).should( 'be.visible' ).then( ( $table ) => {
		const url        = $table.attr( 'data-delete-listing-view-url' );
		const object     = $table.attr( 'data-object-name' );
		const listingKey = $table.attr( 'data-listing-key' ) || object;
		const contextKey = $table.attr( 'data-listing-context-key' ) || '';

		if ( !url ) {
			return;
		}

		cy.get( '.listing-toolbar-data' ).invoke( 'text' ).then( ( raw ) => {
			const toolbar = JSON.parse( raw || '{}' );
			const views   = ( toolbar.savedViews || [] ).filter( ( view ) => view.id && view.id !== 'default' );

			views.forEach( ( view ) => {
				cy.request( {
					  method           : 'POST'
					, url              : url
					, form             : true
					, failOnStatusCode : false
					, body             : {
						  object            : object
						, listingKey        : listingKey
						, listingContextKey : contextKey
						, viewId            : view.id
					  }
				} );
			} );

			if ( views.length ) {
				cy.clearListingTableState();
				cy.reload();
				cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
			}
		} );
	} );
} );

Cypress.Commands.add( 'resetListingToDefaultView', () => {
	cy.get( 'body' ).then( ( $body ) => {
		if ( !$body.find( '.listing-views-toggle' ).length ) {
			return;
		}

		cy.get( '.listing-views-name' ).then( ( $name ) => {
			if ( ( $name.text() || '' ).indexOf( 'Default' ) !== -1 ) {
				return;
			}

			cy.openListingViews();
			cy.get( '[data-view-action="apply"][data-view-id="default"]' ).click();
			cy.get( '.listing-views-name' ).should( 'contain.text', 'Default' );
			cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
		} );
	} );
} );

Cypress.Commands.add( 'visitObjectListing', ( objectName ) => {
	cy.clearListingTableState();
	cy.visit( `/admin/datamanager/object/?id=${ objectName }` );
	cy.get( '.object-listing-table', { timeout : 20000 } ).should( 'be.visible' );
	cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
	cy.deleteSavedListingViews();
	cy.resetListingToDefaultView();
} );

Cypress.Commands.add( 'resetListingColumns', () => {
	cy.get( '.object-listing-table' ).should( 'be.visible' ).then( ( $table ) => {
		const url        = $table.attr( 'data-save-listing-columns-url' );
		const object     = $table.attr( 'data-object-name' );
		const listingKey  = $table.attr( 'data-listing-key' ) || object;
		const contextKey  = $table.attr( 'data-listing-context-key' ) || '';

		expect( url, 'listing column save url' ).to.be.a( 'string' ).and.not.be.empty;

		cy.request( {
			  method : 'POST'
			, url    : url
			, form   : true
			, body   : { object : object, listingKey : listingKey, listingContextKey : contextKey, columns : '' }
		} );
	} );

	cy.reload();
	cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
} );

Cypress.Commands.add( 'openEverythingBar', () => {
	cy.get( '.everything-bar-input' ).should( 'be.visible' ).click();
	cy.get( '.everything-bar-dropdown' ).should( 'not.have.class', 'hide' );
} );

Cypress.Commands.add( 'everythingBarGroups', () => {
	return cy.get( '.everything-bar-dropdown .everything-bar-group' ).then( ( $groups ) => {
		return [ ...$groups ].map( ( el ) => el.textContent.replace( /\s+/g, ' ' ).trim() );
	} );
} );

Cypress.Commands.add( 'openListingColumnPicker', () => {
	cy.get( 'body' ).then( ( $body ) => {
		if ( !$body.find( '.listing-colvis-list .listing-column-row' ).length ) {
			cy.get( 'button[aria-label="Columns"]' ).first().click( { force : true } );
		}
	} );
	cy.get( '.listing-colvis-list .listing-column-row', { timeout : 10000 } ).should( 'have.length.greaterThan', 0 );
} );

Cypress.Commands.add( 'showListingColumn', ( label ) => {
	cy.openListingColumnPicker();
	cy.contains( '.listing-colvis-list .listing-column-row label', label )
		.find( 'input[type=checkbox].listing-column-toggle' )
		.check();
} );

Cypress.Commands.add( 'hideListingColumn', ( label ) => {
	cy.openListingColumnPicker();
	cy.contains( '.listing-colvis-list .listing-column-row label', label )
		.find( 'input[type=checkbox].listing-column-toggle' )
		.uncheck();
} );

Cypress.Commands.add( 'closeListingOverlays', () => {
	cy.get( 'body' ).type( '{esc}', { force : true } );
} );

Cypress.Commands.add( 'filterListingColumnEquals', ( columnLabel, value ) => {
	cy.contains( '.object-listing-table thead th.listing-data-column', columnLabel )
		.scrollIntoView()
		.find( 'button[aria-label="Filter"]' )
		.click( { force : true } );
	cy.get( '.dtcc-dropdown:visible .dtcc-search input' )
		.first()
		.should( 'be.visible' )
		.clear()
		.type( value, { delay : 30 } );
	cy.get( '.everything-chip-column', { timeout : 15000 } ).should( 'contain.text', value );
	cy.closeListingOverlays();
} );

Cypress.Commands.add( 'editListingView', () => {
	cy.openListingViews();
	cy.get( '[data-view-action="edit"]' ).click();
	cy.get( '.object-listing-wrap' ).should( 'have.class', 'listing-view-editing' );
} );

Cypress.Commands.add( 'clearListingViews', () => {
	cy.clearListingTableState();
} );

Cypress.Commands.add( 'openListingViews', () => {
	cy.get( '.listing-views-toggle' ).should( 'be.visible' ).click();
	cy.get( '.listing-views-dropdown' ).should( 'not.have.class', 'hide' );
} );

Cypress.Commands.add( 'saveListingViewAs', ( name ) => {
	cy.intercept( 'POST', /saveListingView/ ).as( 'saveListingView' );
	cy.openListingViews();
	cy.get( '[data-view-action="save-as"]' ).click();
	cy.get( '.listing-views-save-dialog iframe', { timeout : 20000 } )
		.should( 'be.visible' )
		.its( '0.contentDocument.body' )
		.should( 'not.be.empty' )
		.then( ( body ) => {
			cy.wrap( body ).find( 'input[name=sharing_scope][value=global]' ).should( 'exist' );
			cy.wrap( body ).find( 'input[name=sharing_scope][value=individual]' ).should( 'exist' );
			cy.wrap( body ).find( 'input[name=sharing_scope][value=group]' ).should( 'exist' );
			cy.wrap( body ).find( 'input[name=context_scope][value=this]' ).should( 'be.checked' );
			cy.wrap( body ).find( 'input[name=context_scope][value=global]' ).should( 'exist' );
			cy.wrap( body ).find( 'input[name=label]' ).should( 'be.visible' ).clear( { force : true } ).type( name, { force : true } );
		} );
	cy.get( '.listing-views-save-dialog .btn-info' ).contains( 'Save view' ).click();
	cy.wait( '@saveListingView' ).its( 'response.statusCode' ).should( 'eq', 200 );
	cy.get( '.listing-views-name' ).should( 'contain.text', name );
} );

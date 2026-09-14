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

Cypress.Commands.add( 'visitObjectListing', ( objectName ) => {
	cy.visit( `/admin/datamanager/object/?id=${ objectName }` );
	cy.get( '.object-listing-table', { timeout : 20000 } ).should( 'be.visible' );
	cy.get( '.object-listing-table tbody tr', { timeout : 20000 } ).should( 'have.length.greaterThan', 0 );
} );

Cypress.Commands.add( 'resetListingColumns', () => {
	cy.get( '.object-listing-table' ).should( 'be.visible' ).then( ( $table ) => {
		const url        = $table.attr( 'data-save-listing-columns-url' );
		const object     = $table.attr( 'data-object-name' );
		const listingKey = $table.attr( 'data-listing-key' ) || object;

		expect( url, 'listing column save url' ).to.be.a( 'string' ).and.not.be.empty;

		cy.request( {
			  method : 'POST'
			, url    : url
			, form   : true
			, body   : { object : object, listingKey : listingKey, columns : '' }
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

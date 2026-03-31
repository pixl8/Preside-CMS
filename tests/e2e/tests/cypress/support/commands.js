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
	} );

} );

Cypress.Commands.add( 'visitPresideAdmin', ( path ) => {
	const trimmed = path.replace( /^\/?/, '' );
	const qIndex = trimmed.indexOf( '?' );
	const pathOnly = qIndex === -1 ? trimmed : trimmed.slice( 0, qIndex );
	const query = qIndex === -1 ? '' : trimmed.slice( qIndex );
	const needsSlash = pathOnly.length > 0 && !pathOnly.endsWith( '/' );
	cy.visit( '/admin/' + pathOnly + ( needsSlash ? '/' : '' ) + query );
} );

Cypress.Commands.add( 'visitSiteTree', () => {
	cy.visitPresideAdmin( 'sitetree' );
	cy.get( '.tree-table tbody', { timeout: 20000 } ).should( 'be.visible' );
} );

Cypress.Commands.add( 'presideSiteTreeHomepageRow', () => {
	cy.get( '.tree-table tbody tr[data-id]' ).first();
} );

Cypress.Commands.add( 'presideAddStandardPage', ( parentPageId, title ) => {
	const qs = `parent_page=${ encodeURIComponent( parentPageId ) }&page_type=standard_page`;
	cy.visitPresideAdmin( `sitetree/addPage/?${ qs }` );
	cy.get( 'input[name=title]', { timeout: 20000 } ).should( 'be.visible' ).clear().type( title );
	cy.get( 'button[name=_saveAction][value=publish]' ).click();
	cy.url( { timeout: 30000 } ).should( 'match', /[?&]selected=/ );
	cy.get( '.gritter-item-wrapper', { timeout: 15000 } ).should( 'contain.text', 'Page added successfully' );
} );

Cypress.Commands.add( 'presideWaitForRicheditor', ( fieldName ) => {
	cy.get( `textarea[name="${ fieldName }"]`, { timeout: 30000 } ).should( 'exist' ).then( ( $ta ) => {
		const id = $ta.attr( 'id' );
		cy.get( `#cke_${ id }`, { timeout: 30000 } ).should( 'be.visible' );
	} );
	cy.window( { timeout: 30000 } ).should( ( win ) => {
		const inst = win.CKEDITOR?.instances?.[ fieldName ];
		expect( inst, `CKEDITOR.instances.${ fieldName }` ).to.exist;
	} );
} );

Cypress.Commands.add( 'presideCkeditorInstance', ( fieldName ) => {
	return cy.window().then( ( win ) => {
		const inst = win.CKEDITOR.instances[ fieldName ];
		expect( inst, `CKEDITOR.instances.${ fieldName }` ).to.exist;
		return inst;
	} );
} );

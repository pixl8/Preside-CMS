Cypress.Commands.add( 'superuserAdminLogin', () => {
	cy.visit( '/admin/login/' );

	cy.env( [ 'ADMIN_SUPERUSER_EMAIL', 'ADMIN_SUPERUSER_PASSWORD' ] ).then( ( { ADMIN_SUPERUSER_EMAIL, ADMIN_SUPERUSER_PASSWORD } ) => {
		cy.get( 'body' ).then( ( $body ) => {
			if ( $body.text().includes( 'First time setup' ) ) {
				cy.get( 'input[ name=email_address ]' ).should( 'be.visible' ).type( ADMIN_SUPERUSER_EMAIL );
				cy.get( 'input[ name=password ]' ).should( 'be.visible' ).type( ADMIN_SUPERUSER_PASSWORD );
				cy.get( 'input[ name=passwordConfirmation ]' ).should( 'be.visible' ).type( ADMIN_SUPERUSER_PASSWORD );
				cy.get( 'button.btn.btn-danger' ).should( 'be.visible' ).should( 'contain.text', 'Setup user' ).click();

				cy.url().should( 'include', '/login/' );
				cy.get( '.widget-main .alert.alert-success' ).should( 'contain.text', 'Your system administrator account has been setup.' );
			}

			cy.get( 'input[ name=loginId  ]' ).type( ADMIN_SUPERUSER_EMAIL );
			cy.get( 'input[ name=password ]' ).type( ADMIN_SUPERUSER_PASSWORD );
			cy.get( 'button.btn.btn-primary' ).contains( 'Enter' ).click();

			cy.url().should( 'include', '/admin/' );
		} );
	} );
} );

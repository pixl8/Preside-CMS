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

Cypress.Commands.add( 'ensureFrontendUserSetup', () => {
	cy.superuserAdminLogin();
	cy.visit( '/admin/websiteUserManager/' );
	cy.wait( 500 );

	cy.get( '.object-listing-table' ).then( ( $objListingTable ) => {
		var noRecord  = $objListingTable.text().includes( 'No records found' );
		var userExist = $objListingTable.find( 'tr.clickable td' ).text().includes( Cypress.env( 'FRONTEND_USER_EMAIL' ) );

		if ( noRecord || !userExist ) {
			cy.get( '.top-right-button-group button' ).should( 'contain.text', 'Add Website user' ).click();

			cy.get( 'input[ name=login_id  ]' ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_EMAIL' ) );
			cy.get( 'input[ name=email_address  ]' ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_EMAIL' ) );
			cy.get( 'input[ name=display_name  ]' ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_NAME' ) );
			cy.get( 'button.btn.btn-info' ).contains( 'Add Website user' ).click();

			cy.location( 'pathname' ).should( 'eq', '/admin/websiteUserManager/' );
		}

		$objListingTable.find( 'tr.clickable td:contains("' + Cypress.env( 'FRONTEND_USER_EMAIL' ) +'")' ).closest( 'tr' ).find( '.action-buttons i.fa.fa-key' ).click();
		cy.wait( 500 );
		cy.get( 'input[ name=password  ]'         ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_PASSWORD' ) );
		cy.get( 'input[ name=confirm_password  ]' ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_PASSWORD' ) );
		cy.get( 'button.btn.btn-info' ).contains( 'Change password' ).click();
		cy.location( 'pathname' ).should( 'eq', '/admin/websiteUserManager/' );
	} );

	cy.visit( '/admin/login/logout/' );
});

Cypress.Commands.add( 'userFrontendLogin', () => {
	cy.visit( '/login.html' );
	cy.get( 'body' ).then( ( $body ) => {
		cy.get( 'input[ name=loginId  ]' ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_EMAIL'    ) );
		cy.get( 'input[ name=password ]' ).should( 'be.visible' ).type( Cypress.env( 'FRONTEND_USER_PASSWORD' ) );
		cy.get( 'button.btn.btn-default' ).contains( 'Login' ).click();
	});
});
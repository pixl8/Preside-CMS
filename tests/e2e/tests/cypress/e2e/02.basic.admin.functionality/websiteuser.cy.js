describe('Website user', () => {
	let TEST_USER_NAME  = 'John Doe';
	let TEST_USER_EMAIL = 'john.doe@example.com';

	beforeEach(() => {
		cy.superuserAdminLogin();

		cy.get( '.sidebar li' ).should( 'contain.text', 'Website users' );
		cy.get( '.sidebar li' ).contains( 'Website users' ).click();
		cy.location( 'pathname' ).should( 'eq', '/admin/websiteUserManager/' );
	})

	it('Should be accessible on login and have various UI features we can view and use immediately (basic scan of the feature)', () => {
		cy.get( '.top-right-button-group button' ).should( 'contain.text', 'Add Website user' );
		cy.get( '.table-responsive' ).contains( '.dataTables_filter', 'filter' );
		cy.get( '.dataTables_pagination .dataTables_paginate' ).contains( 'Export data' );
	});

	it('Should allow add a new website user', () => {
		cy.wait( 500 );

		cy.get( '.top-right-button-group button' ).should( 'contain.text', 'Add Website user' ).click();
		cy.get( 'input[ name=login_id  ]' ).should( 'be.visible' ).type( TEST_USER_EMAIL );
		cy.get( 'input[ name=email_address  ]' ).should( 'be.visible' ).type( TEST_USER_EMAIL );
		cy.get( 'input[ name=display_name  ]' ).should( 'be.visible' ).type( TEST_USER_NAME );
		cy.get( 'button.btn.btn-info' ).contains( 'Add Website user' ).click();

		cy.location( 'pathname' ).should( 'eq', '/admin/websiteUserManager/' );
	});

	it('Should allow edit a website user', () => {
		cy.wait( 500 );

		cy.get( '.object-listing-table' ).find( 'tr.clickable td:contains("' + TEST_USER_EMAIL +'")' ).closest( 'tr' ).find( '.action-buttons i.fa.fa-pencil' ).click();
		cy.get( 'input[ name=display_name  ]' ).should( 'be.visible' ).clear().type( TEST_USER_NAME + ' (Edited)' );
		cy.get( 'button.btn.btn-info' ).contains( 'Save changes' ).click();

		cy.get( '.object-listing-table' ).find( 'tr.clickable td:contains("' + TEST_USER_EMAIL +'")' ).closest( 'tr' ).find( '.action-buttons i.fa.fa-pencil' ).click();
		cy.get( 'input[ name=display_name  ]' ).should( 'be.visible' ).should( 'have.value', TEST_USER_NAME + ' (Edited)' );
		cy.wait( 500 );
		cy.get( 'input[ name=display_name  ]' ).clear().type( TEST_USER_NAME );
		cy.get( 'button.btn.btn-info' ).contains( 'Save changes' ).click();
	});

	it('Should allow delete a website user', () => {
		cy.wait( 500 );

		cy.get( '.object-listing-table' ).find( 'tr.clickable td:contains("' + TEST_USER_EMAIL +'")' ).closest( 'tr' ).find( '.action-buttons i.fa.fa-trash-o' ).click();
		cy.get( '.modal-dialog input.bootbox-input' ).should( 'be.visible' ).type( 'delete' );
		cy.get( '.modal-dialog button.btn.btn-primary' ).contains( 'Confirm' ).click();
		cy.wait( 500 );
		cy.location( 'pathname' ).should( 'eq', '/admin/websiteUserManager/' );
	});
});
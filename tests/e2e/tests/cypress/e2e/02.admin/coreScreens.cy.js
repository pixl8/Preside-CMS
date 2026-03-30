describe( 'Admin core screens', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'loads site tree', () => {
		cy.visitPresideAdmin( 'sitetree' );
		cy.url().should( 'include', '/admin/sitetree' );
		cy.get( '.info-bar' ).should( 'be.visible' );
	} );

	it( 'loads asset manager', () => {
		cy.visitPresideAdmin( 'assetmanager' );
		cy.url().should( 'include', '/admin/assetmanager' );
		cy.get( '.info-bar' ).should( 'be.visible' );
	} );

	it( 'loads data manager index', () => {
		cy.visitPresideAdmin( 'datamanager' );
		cy.url().should( 'include', '/admin/datamanager' );
		cy.get( 'body' ).should( 'be.visible' );
	} );

	it( 'loads form builder', () => {
		cy.visitPresideAdmin( 'formbuilder' );
		cy.url().should( 'include', '/admin/formbuilder' );
		cy.get( 'body' ).should( 'be.visible' );
	} );

	it( 'loads website user manager', () => {
		cy.visitPresideAdmin( 'websiteusermanager' );
		cy.url().should( 'include', '/admin/websiteusermanager' );
		cy.get( 'body' ).should( 'be.visible' );
	} );

	it( 'loads API manager', () => {
		cy.visitPresideAdmin( 'apimanager' );
		cy.url().should( 'include', '/admin/apimanager' );
		cy.get( 'body' ).should( 'be.visible' );
	} );
} );

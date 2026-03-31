describe( 'Admin site tree trash page', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'moves a standard child page to the recycle bin', () => {
		const title = `E2E trash ${ Date.now() }`;
		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.presideAddStandardPage( homepageId, title );
		} );
		cy.visitPresideAdmin( 'sitetree' );
		cy.contains( '.tree-table tbody tr', title ).should( 'be.visible' ).as( 'pageRow' );
		cy.get( '@pageRow' ).within( () => {
			cy.get( '.dropdown-toggle' ).click();
			cy.contains( 'a', 'Delete page' ).should( 'be.visible' ).click();
		} );
		cy.get( '.bootbox' ).should( 'be.visible' );
		cy.contains( '.bootbox button', 'Confirm' ).click();
		cy.get( '.gritter-item-wrapper', { timeout: 15000 } ).should( 'contain.text', 'Page sent to recycle bin' );
		cy.visitSiteTree();
		cy.contains( '.tree-table tbody tr .page-title', title ).should( 'not.exist' );
	} );
} );

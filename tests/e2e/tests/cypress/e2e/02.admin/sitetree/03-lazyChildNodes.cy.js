describe( 'Admin site tree lazy child rows', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'loads children via ajax when expanding the homepage', () => {
		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			const title = `E2E lazy ${ Date.now() }`;
			cy.presideAddStandardPage( homepageId, title );
			cy.visitPresideAdmin( 'sitetree' );
			cy.presideSiteTreeHomepageRow().find( '.tree-toggler' ).should( 'be.visible' ).click();
			cy.get( `.tree-table tbody tr[data-parent="${ homepageId }"]`, { timeout: 15000 } ).should( 'exist' );
			cy.contains( '.tree-table tbody tr .page-title', title ).should( 'be.visible' );
		} );
	} );
} );

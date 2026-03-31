describe( 'Admin site tree add standard page', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'adds a published standard page under the homepage', () => {
		const title = `E2E add ${ Date.now() }`;
		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.presideAddStandardPage( homepageId, title );
		} );
		cy.contains( '.tree-table tbody tr .page-title', title ).should( 'be.visible' );
	} );
} );

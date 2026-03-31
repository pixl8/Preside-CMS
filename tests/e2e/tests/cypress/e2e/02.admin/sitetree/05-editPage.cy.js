describe( 'Admin site tree edit page', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'updates title and publishes', () => {
		const originalTitle = `E2E edit ${ Date.now() }`;
		const updatedTitle = `${ originalTitle } updated`;
		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.presideAddStandardPage( homepageId, originalTitle );
		} );
		cy.url().then( ( href ) => {
			const match = href.match( /[?&]selected=([^&]+)/ );
			expect( match, 'selected page id in URL' ).to.not.be.null;
			const pageId = decodeURIComponent( match[ 1 ] );
			cy.visitPresideAdmin( `sitetree/editPage/?id=${ pageId }` );
		} );
		cy.get( 'input[name=title]', { timeout: 20000 } ).should( 'be.visible' ).clear().type( updatedTitle );
		cy.get( 'button[name=_saveAction][value=publish]' ).click();
		cy.get( '.gritter-item-wrapper', { timeout: 15000 } ).should( 'contain.text', 'Page saved successfully' );
		cy.visitSiteTree();
		cy.contains( '.tree-table tbody tr .page-title', updatedTitle ).should( 'be.visible' );
	} );
} );

describe( 'Admin site tree shell', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'shows tree tab, search bar, table, and trash link', () => {
		cy.visitSiteTree();
		cy.get( '.nav-tabs a[href="#tab-sitetree"]' ).parent().should( 'have.class', 'active' );
		cy.get( '#sitetree-search-box' ).should( 'be.visible' );
		cy.get( '.tree-table thead th' ).should( 'have.length.at.least', 4 );
		cy.presideSiteTreeHomepageRow().should( 'be.visible' );
		cy.get( 'a[href*="sitetree/trash"]' ).should( 'be.visible' );
	} );

	it( 'switches to grid view tab', () => {
		cy.visitSiteTree();
		cy.contains( '.nav-tabs a', 'Grid view' ).click();
		cy.get( '#tab-page' ).should( 'have.class', 'active' );
		cy.get( '#tab-page .table' ).should( 'be.visible' );
	} );

	it( 'honours selected query string on homepage row', () => {
		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.visitPresideAdmin( `sitetree/?selected=${ homepageId }` );
			cy.presideSiteTreeHomepageRow().should( 'have.class', 'selected' );
		} );
	} );
} );

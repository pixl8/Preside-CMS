describe('The sitetree admin', () => {
  beforeEach(() => {
    cy.superuserAdminLogin()
  })

  it('Should be accessible immediately on login and have various UI features we can view and use immediately (basic scan of the feature)', () => {
    cy.get( '.page-header h1' ).should( 'contain.text', 'Default site' );
    cy.get( '.nav-tabs a[href="#tab-sitetree"]' ).should( 'contain.text', 'Site tree' );
    cy.get( '.nav-tabs a[href="#tab-page"]' ).should( 'contain.text', 'Grid view' );

    cy.get( 'table.tree-table a.page-title' ).should( 'contain.text', 'Homepage' );
    cy.get( 'table.tree-table a.page-title' ).should( 'contain.text', 'Login' );
    cy.get( 'table.tree-table a.page-title' ).should( 'contain.text', '401 Access denied' );
    cy.get( 'table.tree-table a.page-title' ).should( 'contain.text', '404 Not found' );

    cy.get( 'table.tree-table i.fa.fa-caret-right.tree-toggler' ).click();

    cy.get( 'table.tree-table tr.depth-2 a.page-title' ).should( 'contain.text', 'Forgotten password' );
    cy.get( 'table.tree-table tr.depth-2 a.page-title' ).should( 'contain.text', 'Reset password' );
  });

  it('Should allow editing of pages', () => {
    cy.get( 'table.tree-table a.page-title' ).contains( 'Homepage' ).click();

    cy.get( 'textarea#teaser' ).should( 'be.visible' );
    cy.wait( 500 );
    cy.get( 'textarea#teaser' ).clear().type( 'This is a teaser' );
    cy.get( 'button[value=publish]' ).click();

    cy.get( '.gritter-success' ).should( 'contain.text', 'Page saved successfully' )

    cy.get( 'table.tree-table a.page-title' ).contains( 'Homepage' ).click();
    cy.get( 'textarea#teaser' ).should( 'be.visible' ).should( 'have.value', 'This is a teaser' );
    cy.wait( 500 );
    cy.get( 'textarea#teaser' ).clear();
    cy.get( 'button[value=publish]' ).click();
  });
});
describe( 'extensions_app convention', () => {
  it( 'should serve static assets with the static asset route handler correctly', () => {
    cy.request( '/preside/system/assets/extension/myextension/assets/css/test.css' )
      .its( 'body' ).should( 'include', '.hello-world { color:"black"; }' );
  })

  it( 'should have handlers, db migrations, preside objects and services all running as with normal extensions', () => {
    cy.request( '/myextensionhandler/' ).then( (resp) => {
      expect( resp.body[0].label ).to.eq( 'Hello world' );
    } );
  } )

  it( 'should have its error handler registered and used', () => {
    cy.request( '/myextensionhandler/?e2etesterror=true' ).then( (resp) => {
      expect( resp.body.testpassed ).to.eq( true );
    } );
  } )
})
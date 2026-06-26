describe( 'custom tag path conventions', () => {
  it( 'should make app and extension customtags folders available as cf_ tags', () => {
    cy.request( '/myextensionhandler/customtags' ).then( ( resp ) => {
      expect( resp.status ).to.eq( 200 );
      expect( resp.body ).to.include( 'app-custom-tag:from-app' );
      expect( resp.body ).to.include( 'extension-custom-tag:from-extension' );
    } );
  } );
} );

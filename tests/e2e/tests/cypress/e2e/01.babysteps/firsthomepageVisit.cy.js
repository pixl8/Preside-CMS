describe('template spec', () => {
  it('passes', () => {
    cy.visit("/");
    cy.get( ".jumbotron > h1" ).should( "be.visible" ).should( "have.text", "Homepage" );
  })
})
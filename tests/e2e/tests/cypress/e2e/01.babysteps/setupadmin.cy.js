describe('First time admin user setup', () => {
  it('Should prompt user to fill in user details and then allow login', () => {
    cy.superuserAdminLogin();
  })
})
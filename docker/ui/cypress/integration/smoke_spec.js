describe('Smoke Test', () => {
  before(() => {
    // runs once before all tests in the block
    cy.login()
  })

  beforeEach(() => {
    // maintain current session through smoke tests
    Cypress.Cookies.preserveOnce('_opencspm_session', '_opencspm_token')
  })

  after(() => {
    cy.clearCookies()
  })

  it('can see current campaigns', () => {
    cy.contains('Campaigns').click()
    cy.contains('Campaigns allow you to track the progress of controls you care about.')
    cy.url().should('include', '/campaigns')
  })

  it('can see current profiles and view one', () => {
    cy.contains('Profiles').click()
    cy.url().should('include', '/profiles')
    cy.contains('K8s Visibility').click()
    cy.contains('Send to campaign')
    cy.contains('Control (5)')
    cy.url().should('include', '/controls')
  })

  it('can see all controls and create a campaign', () => {
    cy.contains('Controls').click()
    cy.url().should('include', '/controls')
    cy.contains('Control (5)')
    cy.contains('Send to campaign').click()
    cy.contains('Send 5 controls to campaign').click()
    cy.contains('New Campaign')
    cy.url().should('include', '/campaigns')
  })

  it('can see current data sources', () => {
    cy.contains('Sources').click()
    cy.url().should('include', '/sources')
    cy.contains('Inventory Sources')
  })

  it('can see admin details', () => {
    cy.contains('Admin').click()
    cy.url().should('include', '/admin')
    cy.contains('Recent activity')
  })

})
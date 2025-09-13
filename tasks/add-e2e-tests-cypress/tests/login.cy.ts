describe('Login Flow', () => {
    beforeEach(() => {
        // For a real test suite, we would seed the database.
        // For this test, we assume a user exists: 'admin@example.com' / 'password123'
        // from the baseline seed data.
        cy.visit('/');
    });

    it('should allow a user to log in and see the logout button', () => {
        // For the test to be robust, we need to give elements data-cy attributes.
        // The agent will have to add these. For this solution, we'll use text selectors.
        cy.contains('Login').click();

        cy.get('input[placeholder="Email"]').type('admin@example.com');
        cy.get('input[placeholder="Password"]').type('password123');
        cy.get('button[type="submit"]').click();

        // After login, the user should be back at the catalog and see a logout button
        cy.contains('Logout').should('be.visible');
    });

    it('should show an error for invalid credentials', () => {
        cy.contains('Login').click();

        cy.get('input[placeholder="Email"]').type('admin@example.com');
        cy.get('input[placeholder="Password"]').type('wrongpassword');
        cy.get('button[type="submit"]').click();

        cy.contains('Invalid credentials').should('be.visible');
    });
});

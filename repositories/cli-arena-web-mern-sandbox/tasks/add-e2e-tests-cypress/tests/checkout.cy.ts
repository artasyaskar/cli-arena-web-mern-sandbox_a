describe('Checkout Flow', () => {
    beforeEach(() => {
        // We can programmatically log in to speed up tests that aren't about logging in.
        cy.request('POST', 'http://localhost:8080/api/auth/login', {
            email: 'admin@example.com',
            password: 'password123'
        }).then(response => {
            // Save the token to localStorage to simulate a logged-in session
            window.localStorage.setItem('token', response.body.token);
        });
        cy.visit('/');
    });

    it('should allow a logged-in user to add an item to the cart and check out', () => {
        // This test assumes the UI has "Add to Cart" buttons and a "View Cart" button.
        // An agent would need to add these. We will use text selectors as placeholders.

        // 1. Add item to cart
        cy.contains('Laptop Pro').parents('.product-item').contains('Add to Cart').click();

        // 2. Go to cart
        cy.contains('View Cart').click();

        // 3. Verify item is in cart
        cy.get('.cart-view').should('contain', 'Laptop Pro');
        cy.get('.cart-view').should('contain', 'Total:');

        // 4. "Pay" and verify success
        cy.get('.cart-view').contains('Pay (Success)').click();

        // Cypress's `cy.on('window:alert', ...)` can be used to check alerts.
        cy.on('window:alert', (text) => {
            expect(text).to.contains('Checkout successful!');
        });
    });
});

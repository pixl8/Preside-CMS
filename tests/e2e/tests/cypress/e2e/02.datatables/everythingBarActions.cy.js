describe( 'Everything bar custom query actions', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'applies and removes a stubbed custom query action as an extra filter', () => {
		cy.intercept( 'POST', /e2eListingAskFilter/, {
			  statusCode : 200
			, headers    : { 'content-type' : 'application/json' }
			, body       : {
				  ok         : true
				, label      : 'Stubbed widgets filter'
				, expression : [ {
					  expression : 'presideobject_stringmatches_my_extension_object.category'
					, fields     : { value : 'widgets', _stringOperator : 'eq' }
				  } ]
			  }
		} ).as( 'askFilter' );

		cy.get( '.everything-bar-input' ).click().type( 'widgets' );
		cy.contains( '.everything-bar-item', /Ask filter for/ ).should( 'be.visible' ).click();

		cy.wait( '@askFilter' ).then( ( interception ) => {
			const body = interception.request.body;
			const raw  = typeof body === 'string'
				? body
				: new URLSearchParams( body || {} ).toString();

			expect( raw ).to.include( 'query' );
			expect( raw ).to.include( 'widgets' );
			expect( raw ).to.include( 'my_extension_object' );
		} );

		cy.get( '.everything-chip-extra' ).should( 'contain.text', 'Stubbed widgets filter' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );

		cy.get( '.everything-chip-extra .everything-chip-remove' ).click();
		cy.get( '.everything-chip-extra' ).should( 'not.exist' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 10 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Beta 01' );
	} );
} );

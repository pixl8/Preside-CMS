const widgetsExpression = [ {
	  expression : 'presideobject_stringmatches_my_extension_object.category'
	, fields     : { value : 'widgets', _stringOperator : 'eq' }
} ];

const parsePostedForm = ( interception ) => {
	const body = interception.request.body;

	if ( typeof body === 'string' ) {
		return Object.fromEntries( new URLSearchParams( body ) );
	}

	return body || {};
};

const stubAskFilter = ( result ) => {
	cy.intercept( 'POST', /e2eListingAskFilter/, {
		  statusCode : 200
		, headers    : { 'content-type' : 'application/json' }
		, body       : Object.assign( { ok : true }, result )
	} ).as( 'askFilter' );
};

const runAskFilter = ( query ) => {
	cy.get( '.everything-bar-input' ).click().clear().type( query );
	cy.contains( '.everything-bar-item', /Ask filter for/ ).should( 'be.visible' ).click();
	cy.wait( '@askFilter' );
};

describe( 'Everything bar custom query actions', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.visitObjectListing( 'my_extension_object' );
	} );

	it( 'applies and removes a stubbed custom query action as an extra filter', () => {
		stubAskFilter( {
			  label      : 'Stubbed widgets filter'
			, expression : widgetsExpression
		} );

		cy.get( '.everything-bar-input' ).click().clear().type( 'widgets' );
		cy.contains( '.everything-bar-item', /Ask filter for/ ).should( 'be.visible' ).click();

		cy.wait( '@askFilter' ).then( ( interception ) => {
			const posted  = parsePostedForm( interception );
			const current = typeof posted.currentFilters === 'string'
				? JSON.parse( posted.currentFilters || '{}' )
				: ( posted.currentFilters || {} );

			expect( posted.query ).to.include( 'widgets' );
			expect( posted.object ).to.equal( 'my_extension_object' );
			expect( current ).to.have.property( 'search' );
			expect( current ).to.have.property( 'savedFilterIds' );
			expect( current ).to.have.property( 'extraFilters' );
			expect( current ).to.have.property( 'columnSearch' );
			expect( current ).to.have.property( 'advancedFilter' );
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

	it( 'applies a raw search chip from the ajax result', () => {
		stubAskFilter( { search : 'E2E Alpha' } );

		runAskFilter( 'alpha records' );

		cy.get( '.everything-chip-search' ).should( 'contain.text', 'E2E Alpha' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );
	} );

	it( 'applies a saved filter chip from the ajax result', () => {
		cy.get( '.listing-toolbar-data' ).invoke( 'text' ).then( ( raw ) => {
			const starred = ( JSON.parse( raw || '{}' ).savedFilters || [] ).find( ( item ) => item.name === 'Starred alphas' );

			expect( starred && starred.id, 'Starred alphas saved filter id' ).to.be.ok;
			stubAskFilter( { savedFilterIds : [ starred.id ] } );
			runAskFilter( 'starred' );

			cy.get( '.everything-chip-saved' ).should( 'contain.text', 'Starred alphas' );
			cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
			cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
			cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Other 01' );
		} );
	} );

	it( 'applies a quick column filter chip from the ajax result', () => {
		stubAskFilter( {
			columnSearch : {
				category : { search : { logic : 'equal', value : 'widgets' } }
			}
		} );

		runAskFilter( 'category widgets' );

		cy.get( '.everything-chip-column' ).should( 'contain.text', 'widgets' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );
	} );

	it( 'opens the advanced filter with expressions from the ajax result', () => {
		stubAskFilter( {
			  advancedFilter     : widgetsExpression
			, openAdvancedFilter : true
		} );

		runAskFilter( 'advanced widgets' );

		cy.get( '.object-listing-advanced-filter' ).should( 'not.have.class', 'hide' );
		cy.get( '.object-listing-table tbody tr', { timeout : 15000 } ).should( 'have.length', 5 );
		cy.get( '.object-listing-table tbody' ).should( 'contain.text', 'E2E Alpha 01' );
		cy.get( '.object-listing-table tbody' ).should( 'not.contain.text', 'E2E Beta 01' );
	} );
} );

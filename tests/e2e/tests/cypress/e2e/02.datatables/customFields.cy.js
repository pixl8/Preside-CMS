describe( 'Custom fields', () => {
	const fieldLabel = 'E2E custom nickname';
	const fieldValue = 'E2E-NICKNAME-VALUE';
	const fieldKey   = `e2e_nick_${ Date.now().toString( 36 ).replace( /[^a-z0-9]/g, '' ) }`.substring( 0, 40 );

	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'lets an admin create a static field, pick it as a column, then edit and view the value', () => {
		cy.visit( `/admin/datamanager/addRecord/?object=custom_field&target_object=my_extension_object` );

		cy.get( 'input[name="key"]' ).should( 'be.visible' ).clear().type( fieldKey );
		cy.get( 'input[name="label"]' ).should( 'be.visible' ).clear().type( fieldLabel );
		cy.get( 'body' ).then( ( $body ) => {
			if ( $body.find( 'input[name="kind"][value="static"]' ).length ) {
				cy.get( 'input[name="kind"][value="static"]' ).check( { force : true } );
			}
		} );
		cy.get( 'select[name="data_type"], input[name="data_type"]' ).first().then( ( $el ) => {
			if ( $el.is( 'select' ) ) {
				cy.wrap( $el ).select( 'text' );
			}
		} );
		cy.get( 'form.form-horizontal button[type="submit"], form button.btn-info[type="submit"]' )
			.first()
			.click();

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
		cy.openListingColumnPicker();
		cy.get( '.listing-colvis-list' ).should( 'contain.text', fieldLabel );

		cy.showListingColumn( fieldLabel );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', fieldLabel );

		cy.get( '.object-listing-table tbody tr a' ).first().click();
		cy.contains( 'a, button', 'Edit custom fields' ).click();
		cy.get( `input[name="${ fieldKey }"], textarea[name="${ fieldKey }"]` )
			.first()
			.clear()
			.type( fieldValue );
		cy.get( 'form button[type="submit"]' ).first().click();

		cy.contains( fieldLabel ).should( 'be.visible' );
		cy.contains( fieldValue ).should( 'be.visible' );
	} );
} );

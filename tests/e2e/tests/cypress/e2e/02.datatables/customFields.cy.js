describe( 'Custom fields', () => {
	const fieldLabel = 'E2E custom nickname';
	const fieldValue = 'E2E-NICKNAME-VALUE';
	const fieldKey   = `e2e_nick_${ Date.now().toString( 36 ).replace( /[^a-z0-9]/g, '' ) }`.substring( 0, 40 );

	const clickWebflowNext = () => {
		cy.get( 'form.webflow-form button.webflow-next-btn' ).should( 'be.visible' ).click();
	};

	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
	} );

	it( 'lets an admin create a static field, activate it, pick it as a column, then edit and view the value', () => {
		cy.visit( `/admin/datamanager/addRecord/?object=custom_field&target_object=my_extension_object` );

		cy.get( 'form.webflow-form' ).should( 'be.visible' );
		cy.get( 'input[name="label"]' ).should( 'be.visible' ).clear().type( fieldLabel );
		cy.get( 'input[name="key"]' ).clear().type( fieldKey );
		cy.get( 'input[name="kind"][value="static"]' ).check( { force : true } );
		cy.get( 'input[name="data_type"][value="text"]' ).check( { force : true } );
		clickWebflowNext();

		cy.get( 'input[name="include_in_edit_form"]' ).should( 'exist' );
		clickWebflowNext();

		cy.get( 'input[name="flags"]' ).should( 'exist' );
		clickWebflowNext();

		cy.url( { timeout : 20000 } ).should( 'include', 'viewRecord' );
		cy.contains( fieldLabel ).should( 'be.visible' );

		cy.get( '.alert-warning a.btn-success' )
			.should( 'be.visible' )
			.invoke( 'attr', 'href' )
			.then( ( href ) => {
				cy.request( href );
			} );
		cy.reload();
		cy.get( '.alert-success' ).should( 'be.visible' );

		cy.visitObjectListing( 'my_extension_object' );
		cy.resetListingColumns();
		cy.openListingColumnPicker();
		cy.get( '.listing-colvis-list' ).should( 'contain.text', fieldLabel );

		cy.showListingColumn( fieldLabel );
		cy.get( '.object-listing-table thead' ).should( 'contain.text', fieldLabel );
		cy.closeListingOverlays();

		cy.get( '.object-listing-table tbody tr a' ).first().click();
		cy.get( 'a[href*="editRecord"]' ).filter( ':visible' ).first().click();
		cy.contains( '.nav-tabs a', 'Custom fields' ).click();
		cy.get( `input[name="${ fieldKey }"], textarea[name="${ fieldKey }"]` )
			.first()
			.clear()
			.type( fieldValue );
		cy.get( 'form.edit-object-form button[type="submit"]' ).first().click();

		cy.contains( fieldLabel ).should( 'be.visible' );
		cy.contains( fieldValue ).should( 'be.visible' );
	} );
} );

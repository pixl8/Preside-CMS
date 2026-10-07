describe( 'Custom objects', () => {
	const stamp      = Date.now().toString( 36 ).replace( /[^a-z0-9]/g, '' );
	const objectKey  = `e2e_store_${ stamp }`.substring( 0, 40 );
	const objectName = `cobj_${ objectKey }`;
	const plural     = `E2E Stores ${ stamp }`;
	const singular   = `E2E Store ${ stamp }`;
	const category   = `E2E custom stores ${ stamp }`;
	const recordLabel = `E2E record ${ stamp }`;
	const fieldLabel  = `E2E note ${ stamp }`;
	const fieldKey    = `e2e_note_${ stamp }`.substring( 0, 40 );

	const clickWebflowNext = () => {
		cy.get( 'form.webflow-form button.webflow-next-btn' ).should( 'be.visible' ).click();
	};

	beforeEach( () => {
		cy.superuserAdminLogin();
		cy.setListingLabPreference( 'on' );
	} );

	it( 'creates a custom object, lists it under its category, stores a record, exports it and accepts a custom field', () => {
		cy.visit( '/admin/datamanager/addRecord/?object=custom_object' );
		cy.get( 'form.form-horizontal' ).should( 'be.visible' );
		cy.get( 'input[name="label"]' ).clear().type( plural );
		cy.get( 'input[name="key"]' ).clear().type( objectKey );
		cy.get( 'input[name="label_singular"]' ).clear().type( singular );
		cy.get( 'input[name="category"]' ).clear().type( category );
		cy.get( 'form.form-horizontal button[type="submit"]' ).first().click();

		cy.visit( '/admin/datamanager/' );
		cy.contains( category ).should( 'be.visible' );
		cy.contains( 'a', plural ).should( 'be.visible' ).click();

		cy.visit( `/admin/datamanager/addRecord/?object=${ objectName }` );
		cy.get( 'input[name="label"]' ).clear().type( recordLabel );
		cy.get( 'form.form-horizontal button[type="submit"], form button[type="submit"]' ).first().click();
		cy.visit( `/admin/datamanager/object/?id=${ objectName }` );
		cy.contains( recordLabel ).should( 'be.visible' );

		const exportFileName = `e2e-store-export-${ stamp }`;

		cy.get( 'a.object-listing-data-export-button' ).should( 'be.visible' ).click();
		cy.get( '.bootbox-body iframe, .modal iframe' ).should( ( $iframe ) => {
			const frameWindow = $iframe[ 0 ].contentWindow;

			expect( frameWindow && frameWindow.parentPresideBootbox, 'export dialog' ).to.exist;
			expect( frameWindow.document.querySelector( 'input[name="filename"]' ), 'filename' ).to.exist;
		} ).then( ( $iframe ) => {
			$iframe[ 0 ].contentDocument.querySelector( 'input[name="filename"]' ).value = exportFileName;
		} );
		cy.get( '.bootbox .ok-button, .modal .ok-button' ).click();
		cy.readFile( `cypress/downloads/${ exportFileName }.csv`, { timeout : 20000 } ).should( 'include', recordLabel );

		cy.visit( `/admin/datamanager/addRecord/?object=custom_field&target_object=${ objectName }` );
		cy.get( 'form.webflow-form' ).should( 'be.visible' );
		cy.get( 'input[name="label"]' ).clear().type( fieldLabel );
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
	} );
} );

describe( 'Admin richeditor widgets (CKEditor)', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'inserts htmlcode widget in main content and renders it on the homepage', () => {
		const dateNowString = Date.now().toString();
		const marker = `e2e_widget_${ dateNowString }`;
		const htmlSnippet = `<p>${ marker }</p>`;

		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.visitPresideAdmin( `sitetree/editPage/?id=${ homepageId }` );
		} );
		cy.url( { timeout: 30000 } ).should( 'include', 'editPage' );

		cy.presideWaitForRicheditor( 'main_content' );
		cy.window().its( 'CKEDITOR' ).should( 'exist' );

		cy.window().then( ( win ) => {
			const editor = win.CKEDITOR.instances.main_content;
			const savedConfig = { html_code: htmlSnippet };
			const payload = win.encodeURIComponent( win.JSON.stringify( savedConfig ) );
			const raw = `{{widget:htmlcode:${ payload }:widget}}`;
			const chunk = `<p>${ raw }</p>`;
			editor.setData( editor.getData() + chunk );
			editor.updateElement();
		} );

		cy.window().should( ( win ) => {
			const data = win.CKEDITOR.instances.main_content.getData();
			const encodedMarker = win.encodeURIComponent( marker );
			expect( data, 'editor HTML after widget insert' ).to.include( '{{widget:htmlcode:' );
			expect(
				data.includes( marker ) || data.includes( encodedMarker ),
				'marker (literal or url-encoded inside token) present in editor output'
			).to.eq( true );
		} );

		cy.intercept( 'POST', '**/admin/sitetree/editPageAction/**' ).as( 'editPageSave' );
		cy.get( 'button[name=_saveAction][value=publish]' ).click();
		cy.wait( '@editPageSave', { timeout: 60000 } );
		cy.get( '.gritter-item-wrapper', { timeout: 30000 } ).should( 'contain.text', 'Page saved successfully' );

		const baseUrl = Cypress.config( 'baseUrl' ).replace( /\/$/, '' );
		cy.request( { url: `${ baseUrl }/?__e2e=${ Date.now() }`, failOnStatusCode: true, timeout: 30000 } )
			.its( 'body' )
			.should( 'include', marker );
	} );
} );

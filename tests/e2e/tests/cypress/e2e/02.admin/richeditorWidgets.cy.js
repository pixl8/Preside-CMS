describe( 'Admin richeditor widgets (CKEditor)', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'inserts htmlcode widget in main content and renders it on the homepage', () => {
		const marker = `e2e_widget_${ Date.now() }`;
		const htmlSnippet = `<p>${ marker }</p>`;

		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.visitPresideAdmin( `sitetree/editPage/?id=${ homepageId }` );
		} );
		cy.url( { timeout: 30000 } ).should( 'include', 'editPage' );

		cy.presideWaitForRicheditor( 'main_content' );
		cy.window().its( 'CKEDITOR' ).should( 'exist' );

		cy.get( '.cke_button__widgets', { timeout: 30000 } ).should( 'be.visible' ).click();

		cy.get( '.cke_dialog:visible', { timeout: 30000 } ).should( 'be.visible' );
		cy.get( '.cke_dialog:visible .cke_dialog_ui_iframe iframe', { timeout: 30000 } ).should( ( $iframe ) => {
			const doc = $iframe[ 0 ].contentDocument;
			expect( doc.querySelector( 'a[href*="widget=htmlcode"]' ), 'htmlcode widget link in dialog iframe' ).to.exist;
		} );

		cy.get( '.cke_dialog:visible .cke_dialog_ui_iframe iframe' ).then( ( $iframe ) => {
			const link = $iframe[ 0 ].contentDocument.querySelector( 'a[href*="widget=htmlcode"]' );
			link.click();
		} );

		cy.get( '.cke_dialog:visible .cke_dialog_ui_iframe iframe', { timeout: 30000 } ).should( ( $iframe ) => {
			expect( $iframe[ 0 ].contentDocument.querySelector( 'textarea[name=html_code]' ), 'html_code config field' ).to.exist;
		} );

		cy.get( '.cke_dialog:visible .cke_dialog_ui_iframe iframe' ).then( ( $iframe ) => {
			const ta = $iframe[ 0 ].contentDocument.querySelector( 'textarea[name=html_code]' );
			cy.wrap( ta ).should( 'be.visible' ).clear().type( htmlSnippet, { parseSpecialCharSequences: false } );
		} );

		cy.get( '.cke_dialog:visible a.cke_dialog_ui_button_ok' ).click();

		cy.get( '.cke_dialog', { timeout: 60000 } ).should( 'not.exist' );

		cy.presideCkeditorInstance( 'main_content' ).then( ( editor ) => {
			const data = editor.getData();
			expect( data, 'editor HTML after widget insert' ).to.include( '{{widget:htmlcode:' );
			expect( data, 'marker echoed in editor source' ).to.include( marker );
		} );

		cy.get( 'button[name=_saveAction][value=publish]' ).click();
		cy.get( '.gritter-item-wrapper', { timeout: 20000 } ).should( 'contain.text', 'Page saved successfully' );

		cy.visit( '/' );
		cy.contains( 'p', marker, { timeout: 20000 } ).should( 'be.visible' );
	} );
} );

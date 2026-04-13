describe( 'Admin richeditor widgets (CKEditor)', () => {
	beforeEach( () => {
		cy.superuserAdminLogin();
	} );

	it( 'inserts htmlcode widget in main content and renders it on the homepage', () => {
		const dateNowString = Date.now().toString();
		const marker = `e2e_widget_${ dateNowString }`;
		const encodedMarker = `e2e%5Fwidget%5F${ dateNowString }`;
		const htmlSnippet = `<p>${ marker }</p>`;

		cy.visitSiteTree();
		cy.presideSiteTreeHomepageRow().invoke( 'attr', 'data-id' ).then( ( homepageId ) => {
			cy.visitPresideAdmin( `sitetree/editPage/?id=${ homepageId }` );
		} );
		cy.url( { timeout: 30000 } ).should( 'include', 'editPage' );

		cy.presideWaitForRicheditor( 'main_content' );
		cy.window().its( 'CKEDITOR' ).should( 'exist' );

		cy.wait( 500 );

		cy.get( '.cke_button__widgets', { timeout: 30000 } ).should( 'be.visible' ).click();

		cy.get( '.cke_dialog:visible', { timeout: 30000 } ).should( 'be.visible' );
		cy.get( '.cke_dialog:visible iframe.cke_dialog_ui_iframe', { timeout: 30000 } ).should( ( $iframe ) => {
			const doc = $iframe[ 0 ].contentDocument;
			expect( doc.querySelector( 'a[href*="widget=htmlcode"]' ), 'htmlcode widget link in dialog iframe' ).to.exist;
		} );

		cy.get( '.cke_dialog:visible iframe.cke_dialog_ui_iframe' ).then( ( $iframe ) => {
			const link = $iframe[ 0 ].contentDocument.querySelector( 'a[href*="widget=htmlcode"]' );
			link.click();
		} );

		cy.get( '.cke_dialog:visible iframe.cke_dialog_ui_iframe', { timeout: 30000 } ).should( ( $iframe ) => {
			const ta = $iframe[ 0 ].contentDocument?.querySelector( 'textarea[name=html_code]' );
			expect( ta, 'html_code textarea' ).to.not.be.null;
			ta.value = htmlSnippet;
			ta.dispatchEvent( new Event( 'input', { bubbles: true } ) );
		} );

		cy.get( '.cke_dialog:visible a.cke_dialog_ui_button_ok' ).click();

		cy.get( 'body', { timeout: 60000 } ).should( ( $body ) => {
			expect( $body.find( '.cke_dialog:visible' ).length, 'no visible CKEditor dialog' ).to.eq( 0 );
		} );

		cy.presideCkeditorInstance( 'main_content' ).then( ( editor ) => {
			const data = editor.getData();
			expect( data, 'editor HTML after widget insert' ).to.include( '{{widget:htmlcode:' );
			expect(
				data.includes( encodedMarker ),
				'marker echoed in editor source (raw or url-encoded)',
			).to.be.true;
		} );

		cy.get( 'button[name=_saveAction][value=publish]' ).click();
		cy.get( '.gritter-item-wrapper', { timeout: 20000 } ).should( 'contain.text', 'Page saved successfully' );

		cy.visit( '/' );
		cy.contains( marker, { timeout: 20000 } ).should( 'be.visible' );
	} );
} );

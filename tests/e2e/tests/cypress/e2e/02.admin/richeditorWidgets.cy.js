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

		cy.get( '.cke_button__widgets', { timeout: 30000 } )
			.scrollIntoView()
			.should( 'be.visible' )
			.should( 'have.attr', 'aria-disabled', 'false' )
			.click();

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
			ta.dispatchEvent( new Event( 'change', { bubbles: true } ) );
			ta.dispatchEvent( new KeyboardEvent( 'keyup', { bubbles: true } ) );
			ta.blur();
		} );

		cy.get( '.cke_dialog:visible a.cke_dialog_ui_button_ok' )
			.scrollIntoView()
			.should( 'be.visible' )
			.click();

		const tokenStart = '{{widget:htmlcode:';
		const tokenEnd = ':widget}}';

		cy.window( { timeout: 90000 } ).should( ( win ) => {
			const editor = win.CKEDITOR?.instances?.main_content;
			expect( editor, 'CKEDITOR.instances.main_content' ).to.exist;
			const data = editor.getData();
			expect( data, 'editor HTML after widget insert' ).to.include( tokenStart );

			const markerInPayload = ( payload ) => {
				let decoded = payload;
				try {
					decoded = decodeURIComponent( payload.replace( /\+/g, '%20' ) );
				} catch ( _e ) {
					decoded = payload;
				}
				return decoded.includes( marker )
					|| decoded.includes( encodedMarker )
					|| decoded.includes( dateNowString )
					|| payload.includes( encodeURIComponent( marker ) );
			};

			let searchFrom = 0;
			let anyMatch = false;
			for ( ;; ) {
				const start = data.indexOf( tokenStart, searchFrom );
				if ( start === -1 ) {
					break;
				}
				const after = data.slice( start + tokenStart.length );
				const endRel = after.indexOf( tokenEnd );
				if ( endRel < 1 ) {
					searchFrom = start + tokenStart.length;
					continue;
				}
				const payload = after.slice( 0, endRel );
				if ( markerInPayload( payload ) ) {
					anyMatch = true;
					break;
				}
				searchFrom = start + tokenStart.length;
			}
			expect( anyMatch, 'marker inside some htmlcode widget token (editor may contain older widgets)' ).to.be.true;
		} );

		cy.get( 'button[name=_saveAction][value=publish]' ).click();
		cy.get( '.gritter-item-wrapper', { timeout: 20000 } ).should( 'contain.text', 'Page saved successfully' );

		cy.visit( '/' );
		cy.contains( marker, { timeout: 20000 } ).should( 'be.visible' );
	} );
} );

/**
 * Harness-only mock of Preside core's frontendEditors.js
 * (Preside-CMS/system/assets/js/admin/frontend/frontendEditors.js).
 *
 * A faithful TRIMMED TRANSCRIPTION, not a reimagining - this file is the
 * regression surface the extension's Modern inline mode composes with, so the
 * contract parts are kept byte-close to core: base64 template decode +
 * re-parenting, the comment-delimited region, overlay click -> toggleEditMode
 * -> `new PresideRichEditor( ta ).editor`, setContent()'s node walk,
 * saveContent/publishChanges/cancel delegated buttons, the `_presideEditMode`
 * cookie restore, the "e" hotkey and the 1s reposition interval.
 *
 * Dropped: the version-history dataTable UI (needs jquery.dataTables) - the
 * .version-history-link is left inert; gritter alerts (replaced by a $.alert
 * stub that records calls on window.__alerts for assertions).
 */
( function( $ ){
	// ---- shims for presidecore pieces the harness does not load ---------------
	if ( !$.cookie ) {
		$.cookie = function( name, value ) {
			if ( arguments.length > 1 ) { document.cookie = name + "=" + encodeURIComponent( value ); return value; }
			var m = document.cookie.match( new RegExp( "(?:^|;\\s*)" + name + "=([^;]*)" ) );
			return m ? decodeURIComponent( m[ 1 ] ) : undefined;
		};
	}
	window.__alerts = [];
	if ( !$.alert ) { $.alert = function( a ) { window.__alerts.push( a || {} ); }; }
	if ( !window.presideBootbox ) {
		// auto-confirm so the publish flow can run unattended in tests
		window.presideBootbox = { confirm: function( msg, cb ) { cb( true ); }, alert: function() {} };
	}
	if ( !window.userIsTyping ) {
		window.userIsTyping = function() {
			var el = document.activeElement;
			return !!( el && ( el.isContentEditable || /^(input|textarea|select)$/i.test( el.tagName ) ) );
		};
	}
	var translate = function( key ) { return ( window.i18n && i18n.translateResource ) ? i18n.translateResource( key ) : key; };

	// ---- the transcription -----------------------------------------------------
	var $adminBar       = $( "#preside-admin-toolbar" )
	  , $body           = $( 'body' )
	  , $editors        = $( "script.content-editor" )
	  , htmlComments    = $( "*" ).contents().filter( function(){ return this.nodeType === 8; } )
	  , dummyDivs       = []
	  , currentEditMode = false
	  , setEditorSizesAndPosition
	  , removeDummyDivs
	  , setEditMode
	  , togglePageEditMode;

	setEditorSizesAndPosition = function(){
		$editors.each( function(){
			var $editor           = $( this ).data( "presideeditor" )
			  , $overlay          = $editor.find( ".content-editor-overlay .inner" )
			  , $contentContainer = $editor.data( "parent" )
			  , editorId          = $editor.attr( "id" )
			  , startComment      = "container: " + editorId
			  , endComment        = "!" + startComment
			  , position          = {}
			  , $before           = $( "<div></div>" )
			  , $after            = $( "<div></div>" )
			  , $endComment;

			if ( typeof $contentContainer !== "undefined" ) {
				htmlComments.each( function(){
					if ( $.trim( this.nodeValue ) === startComment ) {
						$( this ).before( $before );
					} else if ( $.trim( this.nodeValue ) === endComment ) {
						$endComment = $( this );
						$endComment.after( $after );
					}
				} );

				position.width  = $before.width();
				position.top    = $before.offset().top + $before.height();
				position.left   = $before.offset().left;
				position.height = $after.offset().top - position.top;

				if ( position.height < 25 ) {
					dummyDivs.push( $( "<div></div>" ).height( 25 - position.height ) );
					$endComment.before( dummyDivs[ dummyDivs.length-1 ] );
					position.height = 25;
				}

				$before.remove();
				$after.remove();

				$editor.css( { top: position.top + "px", left: position.left + "px" } );
				$editor.width( position.width );
				$editor.height( position.height );
				$overlay.width( $editor.outerWidth( true ) );
				$overlay.height( $editor.outerHeight( true ) );
			}
		} );
	};

	removeDummyDivs = function(){
		while( dummyDivs.length ) {
			try { dummyDivs[0].remove(); } catch(e){}
			dummyDivs.shift();
		}
	};

	setEditMode = function( mode ){
		currentEditMode = mode;
		if ( mode ) {
			$body.addClass( "show-frontend-editors" );
			setEditorSizesAndPosition();
		} else {
			$body.removeClass( "show-frontend-editors" );
			removeDummyDivs();
		}
		$.cookie( "_presideEditMode", mode ? "true" : "false" );
	};

	togglePageEditMode = function(){
		var $checkbox = $( "#edit-mode-options" )
		  , isChecked = $checkbox.prop( "checked" )
		  , newStatus = !isChecked;

		$checkbox.prop( "checked", newStatus );
		$checkbox.trigger( "change" );
	};

	$adminBar.on( "click change", "#edit-mode-options", function(){
		setEditMode( $( this ).prop( "checked" ) );
	} );

	// core uses jquery.hotkeys ($body.keydown("e", fn)); plain filter here
	$body.on( "keydown", function( e ){
		if ( ( e.key === "e" || e.key === "E" ) && !e.ctrlKey && !e.metaKey && !e.altKey && !window.userIsTyping() ) {
			e.preventDefault();
			togglePageEditMode();
		}
	} );

	$( window ).resize( function(){ setEditorSizesAndPosition(); } );

	setInterval( function(){
		if ( currentEditMode ) { setEditorSizesAndPosition(); }
	}, 1000 );

	$.fn.presideFrontEndEditor = function(){
		return this.each( function(){
			var $scriptContainer      = $( this )
			  , $editor               = $( atob( $scriptContainer.html().trim() ) )
			  , $editorContainer      = $editor.find( '.content-editor-editor-container' )
			  , $form                 = $editorContainer.find( "form" )
			  , $contentInput         = $form.find( "[name=content]" )
			  , $editorParent         = $scriptContainer.parent()
			  , $notificationsArea    = $editor.find( ".content-editor-editor-notifications" )
			  , isRichEditor          = $editor.hasClass( "richeditor" )
			  , saveAction            = $form.attr( "action" )
			  , publishAction         = $form.data( "publishAction" )
			  , publishPromptEndpoint = $form.data( "publishPromptEndpoint" )
			  , originalValue         = $contentInput.val()
			  , formEnabled           = false
			  , editor, toggleEditMode, disableOrEnableSaveButtons, saveContent, saveDraft, publishChanges, fetchPublishPrompt, notify, clearNotifications, disableEditForm, isDirty, exitProtectionListener, ensureEditorIsNotMaximized, setupCkEditor, tearDownCkEditor, setupPlainControl, setContent, commonSuccessHandler, commonFailHandler, commonAlwaysHandler;

			$scriptContainer.appendTo( "body" );
			$editor.appendTo( "body" );
			$editor.data( "parent", $editorParent );
			$editorContainer.appendTo( 'body' );
			$scriptContainer.data( "presideeditor", $editor );

			toggleEditMode = function( editMode ){
				formEnabled = editMode;
				if ( editMode ) {
					window.addEventListener( "beforeunload", exitProtectionListener, false );
					$editorContainer.addClass( "edit-active" );
					$body.addClass( "frontend-editors-editing" );
					if ( isRichEditor ) { setupCkEditor(); } else { setupPlainControl(); }
				} else {
					window.removeEventListener( "beforeunload", exitProtectionListener, false );
					if ( isRichEditor ) { tearDownCkEditor(); }
					$editorContainer.removeClass( "edit-active" );
					$body.removeClass( "frontend-editors-editing" );
				}
				setEditorSizesAndPosition();
			};

			setupCkEditor = function(){
				$editor.data( "_rawContent", $contentInput.val() );
				editor = new PresideRichEditor( $contentInput.get(0) ).editor;
				editor.on( "change", function(){ disableOrEnableSaveButtons(); } );
				editor.on( "instanceReady", function( e ){
					originalValue = e.editor.getData();
					disableOrEnableSaveButtons();
					e.editor.focus();
					$('html, body').scrollTop( $editor.offset().top - 20 );
				} );
				editor.on( "key", function( e ){
					var code      = e.data.keyCode
					  , esc       = 27
					  , ctrlEnter = 13 + CKEDITOR.CTRL
					  , altEnter  = 13 + CKEDITOR.ALT;

					if ( formEnabled ) {
						if ( code === esc )       { toggleEditMode( false ); return false; }
						if ( code === ctrlEnter ) { if ( isDirty() ) { saveDraft(); return false; } }
						if ( code === altEnter )  { editor.execCommand( "maximize" ); return false; }
					}
				} );
			};

			tearDownCkEditor = function(){
				$contentInput.val( $editor.data( "_rawContent" ) );
				ensureEditorIsNotMaximized();
				editor.destroy();
			};

			setupPlainControl = function(){
				$contentInput.on( "change keyup click focus blur", function(){ disableOrEnableSaveButtons(); } );
				$contentInput.focus();
			};

			ensureEditorIsNotMaximized = function(){
				if ( typeof editor.commands.maximize !== "undefined" && editor.commands.maximize.state === 1 ) {
					editor.execCommand( "maximize" );
				}
			};

			isDirty = function(){ return true; };

			disableOrEnableSaveButtons = function() {
				if ( formEnabled ) {
					$editorContainer.find( ".editor-btn" ).prop( "disabled", !isDirty() );
				}
			};

			notify             = function( message ){ $notificationsArea.html( message ); };
			clearNotifications = function(){ notify( "" ); };

			disableEditForm = function( disable ) {
				if ( typeof disable === "undefined" ) { disable = true; }
				formEnabled = !disable;
				$form.prop( "disabled", disable );
				$form.find( ":input" ).prop( "disabled", disable );
				if ( !disable ) { disableOrEnableSaveButtons(); }
			};

			saveDraft = function(){
				if ( isRichEditor ) { ensureEditorIsNotMaximized(); }
				saveContent();
			};

			publishChanges = function(){
				var formData = $form.serializeArray();
				if ( isRichEditor ) { ensureEditorIsNotMaximized(); }

				saveContent( function( data ) {
					if ( data.success && typeof data.rendered != "undefined" ) {
						originalValue = $contentInput.val();
						setContent( data.rendered );
						clearNotifications();
						disableEditForm( false );

						fetchPublishPrompt( function( data ){
							if ( data.publishable ) {
								presideBootbox.confirm( data.prompt, function( confirmed ) {
									if ( confirmed ) {
										notify( translate( "cms:frontendeditor.publishing.notification" ) );
										disableEditForm();
										$.post( publishAction, formData, function( data ){
											if ( data.success ) {
												toggleEditMode( false );
												if ( data.message ) { $.alert( { message: data.message } ); }
											} else {
												$.alert( { type: "error", message: data.error || "unknown error", sticky: true } );
											}
										} ).fail( commonFailHandler ).always( commonAlwaysHandler );
									}
								});
							} else if ( data.nondraft ) {
								toggleEditMode( false );
								$.alert( { message: data.message } );
							} else {
								presideBootbox.alert( data.prompt );
							}
						} );
					} else {
						$.alert( { type: "error", message: data.error || "unknown error", sticky: true } );
					}
				} );
			};

			fetchPublishPrompt = function( callback ){
				$.post( publishPromptEndpoint, $form.serializeArray(), callback );
			};

			setContent = function( content ){
				var nodes        = $editorParent.contents()
				  , editorId     = $editor.attr( "id" )
				  , startComment = "container: " + editorId
				  , endComment   = "!" + startComment
				  , i=0, nNodes=nodes.length, started=false, n, $startComment;

				for( ; i < nNodes; i++ ){
					n = nodes[i];
					if ( !started && n.nodeType === 8 && $.trim( n.nodeValue ) === startComment ) {
						started=true;
						$startComment = $( n );
						continue;
					}
					if ( started ) {
						if ( n.nodeType === 8 && $.trim( n.nodeValue ) === endComment ) { break; }
						$( n ).remove();
					}
				}

				if ( typeof $startComment !== "undefined" ) {
					$startComment.after( content );
				}
			};

			saveContent = function( success, fail, always ){
				var formData;

				success = success || commonSuccessHandler;
				fail    = fail    || commonFailHandler;
				always  = always  || commonAlwaysHandler;

				if ( isRichEditor ) {
					$contentInput.val( editor.getData() );
					$editor.data( "_rawContent", $contentInput.val() );
				}

				formData = $form.serializeArray();

				notify( translate( "cms:frontendeditor.saving.notification" ) );
				disableEditForm();

				$.post( saveAction, formData, success ).fail( fail ).always( always );
			};

			exitProtectionListener = function(){
				if ( isDirty() ) { return translate( "cms:frontendeditor.browser.exit.warning" ); }
			};

			commonSuccessHandler = function( data ) {
				if ( data.success && typeof data.rendered != "undefined" ) {
					originalValue = $contentInput.val();
					setContent( data.rendered );
					toggleEditMode( false );
					if ( data.message ) { $.alert( { message: data.message } ); }
				} else {
					$.alert( { type: "error", message: data.error || "unknown error", sticky: true } );
				}
			};

			commonFailHandler = function( xhr ){
				var data = ( xhr && xhr.responseJSON ) || {};
				$.alert( { type: "error", message: data.error || "unknown error", sticky: true } );
			};

			commonAlwaysHandler = function(){
				clearNotifications();
				disableEditForm( false );
			};

			$editor.on( "click", ".content-editor-overlay,.content-editor-label", function( e ){
				e.preventDefault();
				toggleEditMode( true );
			} );

			$editorContainer.on( "click", ".editor-btn-cancel", function( e ){
				e.preventDefault();
				toggleEditMode( false );
			} );

			$editorContainer.on( "click", ".editor-btn-save", function( e ){
				e.preventDefault();
				saveDraft();
			} );

			$editorContainer.on( "click", ".editor-btn-publish", function( e ){
				e.preventDefault();
				publishChanges();
			} );

			$editorContainer.on( "submit", ".content-editor-form", function( e ){
				e.preventDefault();
			} );
		} );
	};

	$editors.presideFrontEndEditor();

	if ( $editors.length ) {
		$body.append( '<div class="frontend-editor-modal-sheen"></div>' );
	}

	if ( typeof $.cookie( "_presideEditMode" ) !== "undefined" ) {
		var mode      = $.cookie( "_presideEditMode" )
		  , $checkbox = $( "#edit-mode-options" )
		  , editMode  = mode == "true";

		$checkbox.prop( "checked", editMode );
		setEditMode( editMode );
	}
} )( window.presideJQuery || window.jQuery );

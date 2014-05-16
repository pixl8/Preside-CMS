( function( $ ){
	var $adminBar       = $( "#preside-admin-toolbar" )
	  , $body           = $( 'body' )
	  , $editors        = $( ".content-editor" )
	  , currentEditMode = false
	  , setEditorSizes
	  , setEditMode
	  , togglePageEditMode;

	setEditorSizes = function(){
		$editors.each( function(){
			var $editor  = $( this )
			  , $overlay = $editor.find( ".content-editor-overlay .inner" );

			$overlay.width( $editor.outerWidth( true ) );
			$overlay.height( $editor.outerHeight( true ) );

			if ( $overlay.height() < 60 ) {
				$overlay.height( 60 );
			}
		} );
	};

	setEditMode = function( mode ){
		currentEditMode = mode;

		if ( mode ) {
			$body.addClass( "show-frontend-editors" );
			setEditorSizes();
		} else {
			$body.removeClass( "show-frontend-editors" );
		}

		$.cookie( "_presideEditMode", mode ? "true" : "false" );
	}

	togglePageEditMode = function(){
		var $checkbox = $( "#edit-mode-options" )
		  , isChecked = $checkbox.prop( "checked" )
		  , newStatus = !isChecked;

		$checkbox.prop( "checked", newStatus );
		$checkbox.trigger( "change" );
	};

	$adminBar.on( "click change", "#edit-mode-options", function( e ){
		var $checkbox = $( this );

		setEditMode( $checkbox.prop( "checked" ) );
	} );

	$body.keydown( "e", function( e ){
		if ( !userIsTyping() ) {
			e.preventDefault();
			togglePageEditMode();
		}
	} );

	$( window ).resize( function(){
		setEditorSizes();
	} );

	setInterval( function(){
		if ( currentEditMode ) { setEditorSizes(); }
	}, 200 );

	if ( typeof $.cookie( "_presideEditMode" ) !== "undefined" ) {
		var mode      = $.cookie( "_presideEditMode" )
		  , $checkbox = $( "#edit-mode-options" )
		  , editMode  = mode == "true";

		$checkbox.prop( "checked", editMode );
		setEditMode( editMode );
	}

	if ( $editors.length ) {
		var nextTabIndex = ( function(){
			var max = 0;
			$( "[tabindex]" ).each( function(){
				var ix = parseInt( $(this).attr( 'tabindex' ) );
				if ( !isNaN( ix ) && ix > max ) {
					max = ix;
				}
			} );

			return max+1;
		} )();

		$body.attr( "data-nav-list", "1" );
		$body.data( "navListChildSelector", ".content-editor" );
		$editors.each( function( i ){
			$( this ).attr( "tabindex", nextTabIndex+i );
		} );

		$body.append( '<div class="frontend-editor-modal-sheen"></div>' );
	}

	$.fn.presideFrontEndEditor = function( command ){

		return this.each( function(){
			var $editor            = $( this )
			  , $editorContainer   = $editor.find( '.content-editor-editor-container' )
			  , $overlay           = $editor.find( ".content-editor-overlay .inner" )
			  , $form              = $editorContainer.find( "form" )
			  , $contentInput      = $form.find( "[name=content]" )
			  , $drafttextarea     = $editorContainer.find( "textarea[name=draftContent]" )
			  , $contentArea       = $editor.find( ".content-editor-content" )
			  , $notificationsArea = $editor.find( ".content-editor-editor-notifications" )
			  , isRichEditor       = $editor.hasClass( "richeditor" )
			  , saveAction         = $form.attr( "action" )
			  , saveDraftAction    = $form.data( "saveDraftAction" )
			  , discardDraftAction = $form.data( "discardDraftAction" )
			  , originalValue      = $contentInput.val()
			  , savedDraftValue    = $drafttextarea.length && $drafttextarea.val().length ? $drafttextarea.val() : originalValue
			  , formEnabled        = false
			  , autoSaveInterval   = 1500 // auto save draft 1.5 seconds after typing stopped
			  , autoSaveTimeout    = null
			  , discardDraftIcon   = '<i class="preside-icon fa fa-trash-o discard-draft" title="' + i18n.translateResource( "cms:frontendeditor.discard.draft.link" ) + '"></i> '
			  , editor, toggleEditMode, disableOrEnableSaveButtons, saveContent, confirmAndSave, notify, clearNotifications, disableEditForm, autoSave, discardDraft, clearLocalDraft, draftIsDirty, isDirty, exitProtectionListener, ensureEditorIsNotMaximized, setupCkEditor, tearDownCkEditor, setupPlainControl;

			toggleEditMode = function( editMode ){
				formEnabled = editMode;

				if ( editMode ) {
					window.addEventListener( "beforeunload", exitProtectionListener, false );
					$editor.addClass( "edit-active" );
					$body.addClass( "frontend-editors-editing" );

					if ( isRichEditor ) {
						setupCkEditor();
					} else {
						setupPlainControl();
					}

				} else {
					window.removeEventListener( "beforeunload", exitProtectionListener, false );
					if ( isRichEditor ) {
						tearDownCkEditor();
					}

					$editor.removeClass( "edit-active" );
					$body.removeClass( "frontend-editors-editing" );
				}
				setEditorSizes();
			};

			setupCkEditor = function(){
				$editor.data( "_rawContent", $contentInput.val() );
				if ( $drafttextarea.val().length ) {
					notify( discardDraftIcon + i18n.translateResource( "cms:frontendeditor.draft.loaded.notification" ) );
					$contentInput.val( $drafttextarea.val() );
				}
				editor = new PresideRichEditor( $contentInput.get(0) ).editor;
				editor.on( "change", function( e ){ disableOrEnableSaveButtons(); } );
				editor.on( "instanceReady", function( e ){
					if ( originalValue === savedDraftValue ) {
						originalValue = e.editor.getData();
					} else {
						savedDraftValue = e.editor.getData();
					}

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
						if ( code === esc ) {
							toggleEditMode( false );
							return false;
						}

						if ( code === ctrlEnter ) {
							if ( isDirty() ) {
								confirmAndSave();
								return false;
							}
						}

						if ( code === altEnter ) {
							editor.execCommand( "maximize" );
							return false;
						}

						if ( autoSaveTimeout !== null ) {
							window.clearTimeout( autoSaveTimeout );
						}
						autoSaveTimeout = window.setTimeout( autoSave, autoSaveInterval );
					}
				} );
			};

			tearDownCkEditor = function(){
				autoSave();
				$contentInput.val( $editor.data( "_rawContent" ) );
				ensureEditorIsNotMaximized();
				editor.destroy();
			}

			setupPlainControl = function(){
				$contentInput.on( "change keyup click focus blur", function(e){ disableOrEnableSaveButtons(); } );
				$contentInput.focus();
			};

			ensureEditorIsNotMaximized = function(){
				if ( typeof editor.commands.maximize !== "undefined" && editor.commands.maximize.state === 1 ) {
					editor.execCommand( "maximize" );
				}
			};

			draftIsDirty = function(){
				return editor.getData() != savedDraftValue && editor.getData() != originalValue;
			};
			isDirty = function(){
				return true; // temporarily always enabling save buttons due to ckeditor bugs, etc. return ( isRichEditor ? editor.getData() : $contentInput.val() ) != originalValue;
			};

			disableOrEnableSaveButtons = function() {
				if ( formEnabled ) {
					$editor.find( ".editor-btn-save" ).prop( "disabled", !isDirty() );
					if ( isRichEditor ) {
						$editor.find( ".editor-btn-draft" ).prop( "disabled", !draftIsDirty() );
					}
				}
			};

			notify = function( message ){
				$notificationsArea.html( message );
			};
			clearNotifications = function(){
				notify( "" );
			};

			disableEditForm = function( disable ) {
				if ( typeof disable === "undefined" ) {
					disable = true;
				}

				formEnabled = !disable;
				$form.prop( "disabled", disable );
				$form.find( ":input" ).prop( "disabled", disable );

				if ( !disable ) {
					disableOrEnableSaveButtons();
				}
			};

			confirmAndSave = function(){
				if ( isRichEditor ) {
					ensureEditorIsNotMaximized();
				}

				if ( confirm( i18n.translateResource( "cms:frontendeditor.confirm.save.prompt" ) ) ) {
					saveContent();
				} else {
					editor.focus();
				}
			};

			saveContent = function( options ){
				var formData, content;

				options = $.extend( {
					  draft : false
					, url   : saveAction
				}, options );

				if ( isRichEditor ) {
					$contentInput.val( editor.getData() );
					if ( !options.draft ) {
						$editor.data( "_rawContent", $contentInput.val() );
					}
				}
				content = $contentInput.val();

				formData = $form.serializeArray();

				if ( options.draft ) {
					notify( i18n.translateResource( "cms:frontendeditor.saving.draft.notification" ) );
				} else {
					notify( i18n.translateResource( "cms:frontendeditor.saving.notification" ) );
				}
				disableEditForm();

				$.post( options.url, formData, function( data ) {
					if ( data.success && ( options.draft || typeof data.rendered != "undefined" ) )  {
						savedDraftValue = content;

						if ( options.draft ) {
							$drafttextarea.val( content );
							$editor.addClass( "has-draft" );
							notify( discardDraftIcon + i18n.translateResource( "cms:frontendeditor.saved.draft.notification", { data : [ $.dateformat.date( new Date(), "HH:mm:ss" ) ] } ) );
						} else {
							originalValue = content;
							$contentArea.html( data.rendered );
							toggleEditMode( false );
							if ( isRichEditor ) {
								clearLocalDraft();
							}

							if ( data.message ) {
								$.alert( { message : data.message } );
							}
						}

					} else if ( data.error ) {
						$.alert( { type : "error", message : data.error, sticky : true } );
					} else {
						$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
					}
				} ).fail( function( xhr ){
					var data = xhr.responseJSON || {};

					if ( data.error ) {
						$.alert( { type : "error", message : data.error, sticky : true } );
					} else {
						$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
					}
				} ).always( function( xhr ){
					if ( !options.draft || !xhr.success ) {
						clearNotifications();
					}
					disableEditForm( false );
				} );
			};

			discardDraft = function(){
				notify( discardDraftIcon + i18n.translateResource( "cms:frontendeditor.discarding.draft.notification" ) );
				$.post( discardDraftAction, $form.serializeArray(), function( data ) {
					if ( data.success )  {
						clearLocalDraft();
						if ( data.message ) {
							$.alert( { message : data.message } );
						}
					} else if ( data.error ) {
						$.alert( { type : "error", message : data.error, sticky : true } );
					} else {
						$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
					}
				} ).fail( function( xhr ){
					var data = xhr.responseJSON || {};

					if ( data.error ) {
						$.alert( { type : "error", message : data.error, sticky : true } );
					} else {
						$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
					}
				} ).always( function(){
					clearNotifications();
				} );
			};

			clearLocalDraft = function(){
				$drafttextarea.val("");
				$contentInput.val( $editor.data( "_rawContent" ) );
				$editor.removeClass( "has-draft" );
				originalValue = savedDraftValue = $contentInput.val();
				editor.setData( originalValue );
				disableOrEnableSaveButtons();
			};

			autoSave = function(){
				if ( draftIsDirty() ) {
					saveContent( {
						  draft : true
						, url   : saveDraftAction
					} );
				}
			};

			exitProtectionListener = function(){
				autoSave();
				if ( isDirty() ) {
					return i18n.translateResource( "cms:frontendeditor.browser.exit.warning" );
				}
			};

			$editor.on( "click", ".content-editor-overlay,.content-editor-label", function( e ){
				e.preventDefault();
				toggleEditMode( true );
			} );

			$editor.keydown( "return", function( e ){
				if ( currentEditMode ) {
					e.preventDefault();
					toggleEditMode( true );
				}
			} );

			$editor.on( "click", ".editor-btn-cancel", function( e ){
				e.preventDefault();
				toggleEditMode( false );
			} );

			$editor.on( "click", ".editor-btn-save", function( e ){
				e.preventDefault();
				confirmAndSave();
			} );

			$editor.on( "click", ".editor-btn-draft", function( e ){
				e.preventDefault();
				saveContent( {
					  draft     : true
					, url : saveDraftAction
				} );
			} );

			$editor.on( "click", ".discard-draft", function( e ){
				e.preventDefault();
				discardDraft();
			} );

			$editor.on( "submit", "form", function( e ){
				e.preventDefault();
			} );
		} );
	};

	$editors.presideFrontEndEditor();

} )( presideJQuery );
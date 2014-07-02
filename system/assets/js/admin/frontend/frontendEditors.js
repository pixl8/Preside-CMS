( function( $ ){
	var $adminBar       = $( "#preside-admin-toolbar" )
	  , $body           = $( 'body' )
	  , $editors        = $( ".content-editor" )
	  , htmlComments    = $( "*" ).contents().filter( function(){ return this.nodeType === 8; } )
	  , dummyDivs       = []
	  , currentEditMode = false
	  , setEditorSizesAndPosition
	  , removeDummyDivs
	  , setEditMode
	  , togglePageEditMode;

	setEditorSizesAndPosition = function(){
		$editors.each( function(){
			var $editor           = $( this )
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

				$editor.css( {
					  top  : position.top  + "px"
					, left : position.left + "px"
				} );
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
		setEditorSizesAndPosition();
	} );

	setInterval( function(){
		if ( currentEditMode ) { setEditorSizesAndPosition(); }
	}, 1000 );

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
			  , $editorParent      = $editor.parent()
			  , $notificationsArea = $editor.find( ".content-editor-editor-notifications" )
			  , $versioningLink    = $editorContainer.find( ".version-history-link" )
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
			  , editor, toggleEditMode, disableOrEnableSaveButtons, saveContent, confirmAndSave, notify, clearNotifications, disableEditForm, autoSave, discardDraft, clearLocalDraft, draftIsDirty, isDirty, exitProtectionListener, ensureEditorIsNotMaximized, setupCkEditor, tearDownCkEditor, setupPlainControl, setContent, setupVersionTableUi;

			$editor.appendTo( 'body' ); // shove the entire editor markup to the end of the body, avoiding issues with interfering with page layout
			$editor.data( "parent", $editorParent );
			$editorContainer.appendTo( 'body' ); // make its absolute position relative to the body

			toggleEditMode = function( editMode ){
				formEnabled = editMode;

				if ( editMode ) {
					window.addEventListener( "beforeunload", exitProtectionListener, false );
					$editorContainer.addClass( "edit-active" );
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

					$editorContainer.removeClass( "edit-active" );
					$body.removeClass( "frontend-editors-editing" );
				}
				setEditorSizesAndPosition();
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
					$editorContainer.find( ".editor-btn-save" ).prop( "disabled", !isDirty() );
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
						if ( n.nodeType === 8 && $.trim( n.nodeValue ) === endComment ) {
							break;
						}

						$( n ).remove();
					}
				}

				if ( typeof $startComment !== "undefined" ) {
					$startComment.after( content );
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
							setContent( data.rendered );
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

			setupVersionTableUi = function( modalDialog ){
				var $table    = $( modalDialog ).find( '.field-version-table' )
				  , entity    = i18n.translateResource( "cms:frontendeditor.version.entityname" )
				  , colConfig = [
						{ mData : "datemodified"   , sWidth : "18em" },
						{ mData : "_version_author" },
						{
							sClass    : "center",
							bSortable : false,
							mData     : "_options",
							sWidth    : "9em"
						}
				    ];

				$table.dataTable( {
					bServerSide   : true,
					bProcessing   : false,
					bFilter       : false,
					bLengthChange : false,
					aoColumns     : colConfig,
					sDom          : "t<'row'<'col-sm-6'i><'col-sm-6'p>>",
					sAjaxSource   : $table.data( "remote" ),
					oLanguage : {
		      			oAria : {
							sSortAscending : i18n.translateResource( "cms:datatables.sortAscending", {} ),
							sSortDescending : i18n.translateResource( "cms:datatables.sortDescending", {} )
						},
						oPaginate : {
							sFirst : i18n.translateResource( "cms:datatables.first", { data : [entity], defaultValue : "" } ),
							sLast : i18n.translateResource( "cms:datatables.last", { data : [entity], defaultValue : "" } ),
							sNext : i18n.translateResource( "cms:datatables.next", { data : [entity], defaultValue : "" } ),
							sPrevious : i18n.translateResource( "cms:datatables.previous", { data : [entity], defaultValue : "" } )
						},
						sEmptyTable : i18n.translateResource( "cms:datatables.emptyTable", { data : [entity], defaultValue : "" } ),
						sInfo : i18n.translateResource( "cms:datatables.info", { data : [entity], defaultValue : "" } ),
						sInfoEmpty : i18n.translateResource( "cms:datatables.infoEmpty", { data : [entity], defaultValue : "" } ),
						sInfoFiltered : i18n.translateResource( "cms:datatables.infoFiltered", { data : [entity], defaultValue : "" } ),
						sInfoThousands : i18n.translateResource( "cms:datatables.infoThousands", { data : [entity], defaultValue : "" } ),
						sLengthMenu : i18n.translateResource( "cms:datatables.lengthMenu", { data : [entity], defaultValue : "" } ),
						sLoadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [entity], defaultValue : "" } ),
						sProcessing : i18n.translateResource( "cms:datatables.processing", { data : [entity], defaultValue : "" } ),
						sZeroRecords : i18n.translateResource( "cms:datatables.zeroRecords", { data : [entity], defaultValue : "" } ),
						sSearch : '',
						sUrl : '',
						sInfoPostFix : ''
		    		}
				} )
			};

			$editor.on( "click", ".content-editor-overlay,.content-editor-label", function( e ){
				e.preventDefault();
				toggleEditMode( true );
			} );

			$editorContainer.keydown( "return", function( e ){
				if ( currentEditMode ) {
					e.preventDefault();
					toggleEditMode( true );
				}
			} );

			$editorContainer.on( "click", ".editor-btn-cancel", function( e ){
				e.preventDefault();
				toggleEditMode( false );
			} );

			$editorContainer.on( "click", ".editor-btn-save", function( e ){
				e.preventDefault();
				confirmAndSave();
			} );

			$editorContainer.on( "click", ".discard-draft", function( e ){
				e.preventDefault();
				discardDraft();
			} );

			$editorContainer.on( "submit", ".content-editor-form", function( e ){
				e.preventDefault();
			} );

			$versioningLink.presideBootboxModal( { onShow : setupVersionTableUi } );
		} );
	};

	$editors.presideFrontEndEditor();

} )( presideJQuery );
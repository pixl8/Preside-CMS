( function( $ ){
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

	$.fn.presideFrontEndEditor = function( command ){
		return this.each( function(){
			var $scriptContainer      = $( this )
			  , $editor               = $( $scriptContainer.html() )
			  , $editorContainer      = $editor.find( '.content-editor-editor-container' )
			  , $overlay              = $editor.find( ".content-editor-overlay .inner" )
			  , $form                 = $editorContainer.find( "form" )
			  , $contentInput         = $form.find( "[name=content]" )
			  , $editorParent         = $scriptContainer.parent()
			  , $notificationsArea    = $editor.find( ".content-editor-editor-notifications" )
			  , $versioningLink       = $editorContainer.find( ".version-history-link" )
			  , isRichEditor          = $editor.hasClass( "richeditor" )
			  , saveAction            = $form.attr( "action" )
			  , publishAction         = $form.data( "publishAction" )
			  , publishPromptEndpoint = $form.data( "publishPromptEndpoint" )
			  , originalValue         = $contentInput.val()
			  , formEnabled           = false
			  , versionIcon           = '<i class="preside-icon fa fa-history"></i> '
			  , editor, toggleEditMode, disableOrEnableSaveButtons, saveContent, saveDraft, publishChanges, fetchPublishPrompt, notify, clearNotifications, disableEditForm, isDirty, exitProtectionListener, ensureEditorIsNotMaximized, setupCkEditor, tearDownCkEditor, setupPlainControl, setContent, setupVersionTableUi, setVersionContent, commonSuccessHandler, commonFailHandler, commonAlwaysHandler;

			$scriptContainer.appendTo( "body" );
			$editor.appendTo( "body" );
			$editor.data( "parent", $editorParent );
			$editorContainer.appendTo( 'body' ); // make its absolute position relative to the body
			$scriptContainer.data( "presideeditor", $editor );

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
				editor = new PresideRichEditor( $contentInput.get(0) ).editor;
				editor.on( "change", function( e ){ disableOrEnableSaveButtons(); } );
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
						if ( code === esc ) {
							toggleEditMode( false );
							return false;
						}

						if ( code === ctrlEnter ) {
							if ( isDirty() ) {
								saveDraft();
								return false;
							}
						}

						if ( code === altEnter ) {
							editor.execCommand( "maximize" );
							return false;
						}
					}
				} );
			};

			tearDownCkEditor = function(){
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

			isDirty = function(){
				return true; // temporarily always enabling save buttons due to ckeditor bugs, etc. return ( isRichEditor ? editor.getData() : $contentInput.val() ) != originalValue;
			};

			disableOrEnableSaveButtons = function() {
				if ( formEnabled ) {
					$editorContainer.find( ".editor-btn" ).prop( "disabled", !isDirty() );
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

			saveDraft = function(){
				if ( isRichEditor ) {
					ensureEditorIsNotMaximized();
				}

				saveContent();
			};

			publishChanges = function(){
				var formData = $form.serializeArray();
				if ( isRichEditor ) {
					ensureEditorIsNotMaximized();
				}

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
										notify( i18n.translateResource( "cms:frontendeditor.publishing.notification" ) );
										disableEditForm();

										$.post( publishAction, formData, function( data ){
											if ( data.success ) {
												toggleEditMode( false );

												if ( data.message ) {
													$.alert( { message : data.message } );
												}

											} else if ( data.error ) {
												$.alert( { type : "error", message : data.error, sticky : true } );
											} else {
												$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
											}
										} ).fail( commonFailHandler ).always( commonAlwaysHandler );
									}
								});
							} else {
								presideBootbox.alert( data.prompt );
							}
						} );
					} else if ( data.error ) {
						$.alert( { type : "error", message : data.error, sticky : true } );
					} else {
						$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
					}
				} );
			};

			fetchPublishPrompt = function( callback ){
				var formData = $form.serializeArray();

				$.post( publishPromptEndpoint, formData, callback );
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

				notify( i18n.translateResource( "cms:frontendeditor.saving.notification" ) );
				disableEditForm();

				$.post( saveAction, formData, success ).fail( fail ).always( always );
			};

			exitProtectionListener = function(){
				if ( isDirty() ) {
					return i18n.translateResource( "cms:frontendeditor.browser.exit.warning" );
				}
			};

			setupVersionTableUi = function( modalDialog ){
				var $table       = $( modalDialog ).find( '.field-version-table' )
				  , $previewPane = $( modalDialog ).find( '.preview-pane' )
				  , entity       = i18n.translateResource( "cms:frontendeditor.version.entityname" )
				  , colConfig    = [
						{ mData : "datemodified"   , sWidth : "18em" },
						{ mData : "_version_author" },
						{
							sClass    : "center",
							bSortable : false,
							mData     : "_options",
							sWidth    : "9em"
						}
					];

				if ( typeof $table.data( 'setupVersionTableUi' ) === 'undefined' ) {
					$table.on( "click", ".preview-version", function( e ) {
						e.preventDefault();

						var $previewLink = $( this )
						  , $tr          = $previewLink.closest( "tr" )
						  , oldHtml      = $previewPane.html();

						$tr.addClass( 'selected' ).siblings().removeClass( 'selected' );

						$previewPane.html( "" );
						$previewPane.addClass( "loading" );

						$.ajax({
							  method   : "GET"
							, url      : $previewLink.attr( "href" )
							, success  : function( content ){
								setTimeout( function(){
									$previewPane.removeClass( "loading" );
									$previewPane.html( content );
								}, 400 ); // simulate at least a little bit of loading time so that the loading icon doesn't just flash annoyingly

							  }
							, error    : function(){
								$previewPane.html( oldHtml );
								$previewPane.removeClass( "loading" );
								$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.previewversion.unknown.error" ), sticky : true } );
							  }
						});
					} );
					$table.on( "click", ".load-version", function( e ){
						e.preventDefault();

						var $loadLink = $( this );

						$.ajax({
							  method  : "GET"
							, url     : $loadLink.attr( 'href' )
							, cache   : false
							, success : function( result ){
								if ( typeof result === "object" && result.success && typeof result.content !== "undefined" ) {
									setVersionContent( result.content );
									modalDialog.on('hidden.bs.modal', function () {
									    modalDialog.remove();
									});
									modalDialog.modal( "hide" );

								} else {
									$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.loadversion.unknown.error" ), sticky : true } );
								}
							  }
							, error : function(){
								$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.loadversion.unknown.error" ), sticky : true } );
							  }
						} );
					} );

					$table.dataTable( {
						bServerSide    : true,
						bProcessing    : false,
						bFilter        : false,
						bLengthChange  : false,
						iDisplayLength : 4,
						aoColumns      : colConfig,
						sDom           : "t<'row'<'col-sm-6'i><'col-sm-6'p>>",
						sAjaxSource    : $table.data( "remote" ),
						fnRowCallback : function( row ){
							$row = $( row );
							$row.attr( 'data-context-container', "1" ); // make work with context aware Preside hotkeys system
							$row.addClass( "clickable" ); // make work with clickable tr Preside system
						},
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
					} );

					$table.data( 'setupVersionTableUi', true );
				}
			};

			setVersionContent = function( content ){
				$editor.data( "_rawContent", content );

				originalValue = content;
				$contentInput.val( content );

				notify( versionIcon + i18n.translateResource( "cms:frontendeditor.version.loaded.notification" ) );
			};

			commonSuccessHandler = function( data ) {
				if ( data.success && typeof data.rendered != "undefined" ) {
					originalValue = $contentInput.val();
					setContent( data.rendered );
					toggleEditMode( false );

					if ( data.message ) {
						$.alert( { message : data.message } );
					}

				} else if ( data.error ) {
					$.alert( { type : "error", message : data.error, sticky : true } );
				} else {
					$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
				}
			};

			commonFailHandler = function( xhr ){
				var data = xhr.responseJSON || {};

				if ( data.error ) {
					$.alert( { type : "error", message : data.error, sticky : true } );
				} else {
					$.alert( { type : "error", message : i18n.translateResource( "cms:frontendeditor.save.unknown.error" ), sticky : true } );
				}
			};

			commonAlwaysHandler = function( xhr ){
				clearNotifications();
				disableEditForm( false );
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

			$versioningLink.presideBootboxModal( { onShow : setupVersionTableUi } );
		} );
	};

	$editors.presideFrontEndEditor();

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
			$( this ).data( "presideeditor" ).attr( "tabindex", nextTabIndex+i );
		} );

		$body.append( '<div class="frontend-editor-modal-sheen"></div>' );
	}

	if ( typeof $.cookie( "_presideEditMode" ) !== "undefined" ) {
		var mode      = $.cookie( "_presideEditMode" )
		  , $checkbox = $( "#edit-mode-options" )
		  , editMode  = mode == "true";

		$checkbox.prop( "checked", editMode );
		setEditMode( editMode );
	}


} )( presideJQuery );
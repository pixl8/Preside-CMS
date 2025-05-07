/**
 * I need to be able to:
 *
 * * Drag item types into form workspace
 * * Reorder items
 * * Edit items
 *
 */
( function( $ ){

	var $itemTypePicker      = $( ".formbuilder-item-type-picker" )
	  , $itemTypes           = $( ".formbuilder-item-type-picker .item-type" )
	  , $itemsContainer      = $( ".form-items" )
	  , $instructions        = $( ".instructions" )
	  , formId               = cfrequest.formbuilderFormId
	  , saveNewItemEndpoint  = cfrequest.formbuilderSaveNewItemEndpoint
	  , saveItemEndpoint     = cfrequest.formbuilderSaveItemEndpoint
	  , deleteItemEndpoint   = cfrequest.formbuilderDeleteItemEndpoint
	  , setSortOrderEndpoint = cfrequest.formbuilderSetSortOrderEndpoint
	  , setupDragAndDropBehaviour
	  , setupClickBehaviours
	  , addItemFromDropZone
	  , addItemDirectlyFromList
	  , processNewItem
	  , saveNewItem
	  , saveItem
	  , launchConfiguration
	  , editItem
	  , cloneItem
	  , deleteItem
	  , saveSortOrder;

	setupDragAndDropBehaviour = function() {
		$itemTypes.draggable({
			  helper            : "clone"
			, connectToSortable : $itemsContainer
		});

		$instructions.droppable({
			  accept : $itemTypes
			, drop   : addItemFromDropZone
		});

		$itemsContainer.sortable( {
			  placeholder : "sortable-placeholder item-type"
			, handle      : ".sort-link"
			, helper      : function( event, ui ) {
				var $group;

				if ( ui.is( '[data-item-type="page"]' ) ) {
					$group = ui.nextUntil( ".item-type-page" ).addBack();
				} else {
					$group = ui;
				}

				var $helper = $( "<div class='sortable-helper'></div>" );

				$group.each( function() {
					$helper.append( $( this ).clone().css( {
						  width      : $( this ).outerWidth()
						, background : "#f8f9fa"
						, padding    : "5px"
					} ) );
				} );

				ui.data( "group", $group );

				return $helper;
			  }
			, start       : function( event, ui ) {
				var $group = ui.item.data("group");

				if ( $group && $group.length > 1 ) {
					$group.not( ui.item ).addClass( "hidden-item" ).slideUp( 200 );
				}
			  }
			, update      : function( event, ui ) {
				var $group = ui.item.data( "group" );
				var $next  = ui.item.next();
				var $prev  = ui.item.prev();
				var $item  = ui.item;

				var isPage     = $item.is( '[data-item-type="page"]' );
				var hasAnyPage = $( ".form-items .form-item[data-item-type='page']" ).length > 0;

				if ( $group && $group.length > 1 ) {
					if ( $next.length && !$next.is( '[data-item-type="page"]' ) ) {
						$( this ).sortable( "cancel" );
						$group.removeClass( "hidden-item" ).slideDown( 200 );
						return;
					}

					$( ".sortable-placeholder" ).remove();

					$group.detach();

					if ( $next.length ) {
						$group.insertBefore( $next );
					} else {
						$( ".form-items" ).append( $group );
					}

					$group.removeClass( "hidden-item" ).slideDown( 200 );
				}

				if ( !isPage && $prev.length === 0 ) {
					if ( hasAnyPage ) {
						$( this ).sortable( "cancel" );
						return;
					}
				}

				if ( !isPage && !hasAnyPage ) {
					$item.detach();

					if ( $next.length ) {
						$item.insertBefore( $next );
					} else if ( $prev.length === 0 ) {
						$( ".form-items" ).prepend( $item );
					} else {
						$( ".form-items" ).append( $item );
					}
				}
			  }
			, stop        : function( event, ui ) {
				var $group = ui.item.data( "group" )
				  , item   = ui.item
				  , data   = item.data();

				if ( $group && $group.length > 1 ) {
					$( ".sortable-placeholder" ).remove();
					$group.removeClass( "hidden-item" ).slideDown( 200 );
				}

				if ( data.itemTemplate ) {
					processNewItem( item );
					item.data( "itemTemplate", false );
				} else {
					saveSortOrder();
				}
			}
			, change      : function( event, ui ) {
				var $item        = ui.item;
				var $placeholder = $( ".sortable-placeholder" );
				var $firstItem   = $( ".form-items .form-item" ).first();
				var hasAnyPage   = $( ".form-items .form-item[data-item-type='page']" ).length > 0;

				if ( !$item.is( '[data-item-type="page"]' ) ) {
					if ( $placeholder.index() === 0 && hasAnyPage ) {
						$placeholder.hide();
					} else {
						$placeholder.show();
					}
				} else {
					$placeholder.show();
				}
			}
		} );
	};

	setupAccordionForItemTypes = function() {
		$itemTypePicker.accordion( {
			  collapsible : true
			, heightStyle : "content"
			, animate     : 250
			, header      : ".accordion-header"
		} );
	};

	setupClickBehaviours = function(){
		$itemsContainer.on( "click", ".edit-link", editItem );
		$itemsContainer.on( "click", ".clone-link", cloneItem );
		$itemsContainer.on( "click", ".delete-link", deleteItem );
	};

	addItemFromDropZone = function( event, ui ){
		var $item = ui.draggable.clone();

		$item.appendTo( $itemsContainer );
		$instructions.removeClass( "empty" );

		processNewItem( $item );
	};

	processNewItem = function( $newItem ) {
		var itemTypeConfig = $newItem.data();
		if ( !itemTypeConfig.requiresConfiguration ) {
			saveNewItem( itemTypeConfig.itemType, {}, $newItem );
		} else {
			launchConfiguration( $newItem );
		}
	};

	saveNewItem = function( itemType, configuration, $item ){
		var data = $.extend( {}, { formId: formId, itemType: itemType }, configuration )
		  , postSave;

		postSave = function( data ){
			var $newItem = $( data.itemView );

			$item.after( $newItem );
			if( typeof $item.enableCloneItem === "undefined" ) {
				$item.remove();
			}
			saveSortOrder();
		};

		$.ajax( saveNewItemEndpoint, {
			  method  : "POST"
			, data    : data
			, cache   : false
			, success : postSave
		} )
	};

	saveItem = function( configuration, $item ){
		var data = $.extend( {}, { id : $item.data( "id" ) }, configuration )
		  , postSave;

		postSave = function( data ){
			var $newItem = $( data.itemView );

			$item.after( $newItem );
			$item.remove();
		};

		$.ajax( saveItemEndpoint, {
			  method  : "POST"
			, data    : data
			, cache   : false
			, success : postSave
		} )
	};

	launchConfiguration = function( $item ){
		var itemData       = $item.data()
		  , configEndpoint = typeof $item.enableCloneItem === "undefined" ? itemData.configEndpoint : itemData.configClone
		  , itemDataId     = typeof $item.enableCloneItem === "undefined" ? itemData.id             : ""
		  , onCancelDialog
		  , onIFrameLoad
		  , onDialogOk
		  , modal
		  , modalIframe;

		onDialogOk = function(){
			var config = modalIframe.getFormBuilderItemConfig();

			if ( itemData.itemType=="content" ) {
				if ( typeof itemDataId === "undefined" || typeof $item.enableCloneItem !== "undefined" ) {
					saveNewItem( "content", config, $item );
				} else {
					saveItem( config, $item );
				}
				modal.close();
				return false;
			}

			modalIframe.validateFormBuilderItemConfig( formId, itemDataId || "", function( valid ){
				if ( valid ) {
					if ( typeof itemDataId === "undefined" || typeof $item.enableCloneItem !== "undefined" ) {
						saveNewItem( itemData.itemType, config, $item );
					} else {
						saveItem( config, $item );
					}

					modal.close();
				}
			} );

			return false;
		};

		onCancelDialog = function(){
			var itemData = $item.data();

			if ( typeof itemDataId === "undefined" ) {
				$item.remove();
			}
		};

		onIFrameLoad = function( iframe ){
			modalIframe = iframe;
		};

		modal = new PresideIframeModal( configEndpoint, "100%", "100%", {
			  onLoad   : onIFrameLoad
			, onok     : onDialogOk
			, oncancel : onCancelDialog
		}, {
			  title      : itemData.configTitle
			, className  : "full-screen-dialog"
			, buttonList : [ "ok", "cancel" ]
		} );

		modal.open();
		$( 'button[class="bootbox-close-button close"]' ).on( "click", function( e ){
			var itemData = $item.data();
			if ( typeof itemDataId === "undefined" ) {
				$item.remove();
			}
		});
	};

	editItem = function( e ) {
		var $link  = $( this )
		  , $item  = $link.closest( ".form-item" );

		e.preventDefault();

		launchConfiguration( $item );
	};

	cloneItem = function( e ) {
		var $link             = $( this )
		  , $item             = $link.closest( ".form-item" );
		$item.enableCloneItem = true;
		e.preventDefault();

		launchConfiguration( $item );
	};

	deleteItem = function( e ) {
		var $link    = $( this )
		  , $item    = $link.closest( ".form-item" )
		  , title    = $link.data( "title" ) || $link.attr( "title" )
		  , prompt   = i18n.translateResource( "cms:confirmation.prompt", { data:[ ( title.charAt(0).toLowerCase() + title.slice(1) ) ] } )
		  , $message = $( "<div class=\"form-group\"><label>" + prompt + "</label></div>" )
		  , $input   = $( "<input class=\"bootbox-input form-control\" autocomplete=\"off\" type=\"text\" />" )
		  , match    = "delete"
		  , isPage   = $item.is( '[data-item-type="page"]' )
		  , items    = [ $item ];

		e.preventDefault();

		if ( isPage ) {
			var $nextItem = $item.next();
			while ( $nextItem.length && !$nextItem.is( '[data-item-type="page"]' ) ) {
				items.push( $nextItem );

				$nextItem = $nextItem.next();
			}

			if ( items.length > 1 ) {
				$message
					.find( "label" )
					.text( prompt + " " + i18n.translateResource( "cms:formbuilder.delete.fields.title" ) )
					.parent()
					.append( "<p class=\"help-block\">" + i18n.translateResource( "cms:confirmation.prompt.please.type.message", { data:[ "<code>" + match + "</code>" ] } ) + "</p>" )
					.append( $input )
				;
			}
		}

		var confirmationDialog = presideBootbox.dialog( {
			  title   : i18n.translateResource( "cms:confirmation.title" )
			, message :$message
			, buttons : {
				  cancel  : {
					  label: i18n.translateResource( "cms:confirmation.prompt.cancel.button" )
				  }
				, confirm : {
					  label: i18n.translateResource( "cms:confirmation.prompt.confirm.button" )
					, callback: function() {
						var confirmed = false;

						if ( isPage && items.length > 1 && match.length ) {
							if( $input.val() === match ) {
								confirmed = true;
								$message.removeClass( "has-error" );
							}
							else {
								$message.addClass( "has-error" );
							}
						}
						else {
							confirmed = true;
						}

						if ( confirmed ) {
							$.each( items, function( _, item ) {
								$.ajax( deleteItemEndpoint, {
									  method : "POST"
									, data   : { id : $( item ).data( "id" ) }
									, cache  : false
									, success : function( result ){
										if ( result ) {
											$( item ).remove();
										}
									}
								} );
							} );

							confirmationDialog.modal('hide');
						}

						return false;
					  }
				}
			}
		} );
	};

	saveSortOrder = function(){
		var itemIds = $itemsContainer.sortable( "toArray", { attribute : "data-id" } ).join();

		if ( itemIds.length ) {
			$.ajax( setSortOrderEndpoint, {
				  method : "POST"
				, data   : { itemIds : itemIds }
				, cache  : false
			} );
		}

	};

	setupDragAndDropBehaviour();
	setupAccordionForItemTypes();
	setupClickBehaviours();

} )( presideJQuery );
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
	  , sortableStop
	  , addItemDirectlyFromList
	  , processNewItem
	  , saveNewItem
	  , saveItem
	  , launchConfiguration
	  , editItem
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
			  stop        : sortableStop
			, placeholder : "item-type sortable-placeholder"
			, handle      : ".sort-link"
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

		$itemsContainer.on( "click", ".delete-link", deleteItem );
	};

	addItemFromDropZone = function( event, ui ){
		var $item = ui.draggable.clone();

		$item.appendTo( $itemsContainer );
		$instructions.removeClass( "empty" );

		processNewItem( $item );
	};

	sortableStop = function( event, ui ){
		var item = ui.item
		  , data = item.data();

		if ( data.itemTemplate ) {
			processNewItem( item );
			item.data( "itemTemplate", false );
		} else {
			saveSortOrder();
		}
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
			$item.remove();
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
		var itemData = $item.data()
		  , onCancelDialog
		  , onIFrameLoad
		  , onDialogOk
		  , modal
		  , modalIframe;

		onDialogOk = function(){
			modalIframe.validateFormBuilderItemConfig( formId, itemData.id || "", function( valid ){
				if ( valid ) {
					var config = modalIframe.getFormBuilderItemConfig();

					if ( typeof itemData.id === "undefined" ) {
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

			if ( typeof itemData.id === "undefined" ) {
				$item.remove();
			}
		};

		onIFrameLoad = function( iframe ){
			modalIframe = iframe;
		};

		modal = new PresideIframeModal( itemData.configEndpoint, "100%", "100%", {
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
			if ( typeof itemData.id === "undefined" ) {
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

	deleteItem = function( e ){
		var $link  = $( this )
		  , $item  = $link.closest( ".form-item" )
		  , title  = $link.data( "title" ) || $link.attr( "title" )
		  , prompt = i18n.translateResource( "cms:confirmation.prompt", { data:[ ( title.charAt(0).toLowerCase() + title.slice(1) ) ] } );

		e.preventDefault();

		presideBootbox.confirm( prompt, function( confirmed ) {
			if ( confirmed ) {
				$.ajax( deleteItemEndpoint, {
					  method : "POST"
					, data   : { id : $item.data( "id" ) }
					, cache  : false
					, success : function( result ){
						if ( result ) {
							$item.remove();
						}
					}
				} );

			}
		});
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
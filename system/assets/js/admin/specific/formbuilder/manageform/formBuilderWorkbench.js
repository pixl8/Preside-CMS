/**
 * I need to be able to:
 *
 * * Drag item types into form workspace
 * * Reorder items
 * * Edit items
 *
 */
( function( $ ){

	var $itemTypes          = $( ".formbuilder-item-type-picker .item-type" )
	  , $itemsContainer     = $( ".form-items" )
	  , $instructions       = $( ".instructions" )
	  , formId              = cfrequest.formbuilderFormId
	  , saveNewItemEndpoint = cfrequest.formbuilderSaveNewItemEndpoint
	  , setupDragAndDropBehaviour
	  , addItemFromDropZone
	  , sortableStop
	  , addItemDirectlyFromList
	  , processNewItem
	  , saveNewItem
	  , launchConfiguration;

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
		} );
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
		}
	};

	processNewItem = function( $newItem ) {
		var itemTypeConfig = $newItem.data();
		if ( !itemTypeConfig.requiresConfiguration ) {
			saveNewItem( itemTypeConfig.itemType, {}, function( itemId ){
				$newItem.data( "id", itemId );

				// todo, render item post save
				// todo, save order of all items
			} );
		} else {
			launchConfiguration( $newItem );
		}
	};

	saveNewItem = function( itemType, configuration, callback ){
		var data = $.extend( {}, { formId: formId, itemType: itemType }, configuration );

		$.ajax( saveNewItemEndpoint, {
			  method  : "POST"
			, data    : data
			, cache   : false
			, success : callback
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
						saveNewItem( itemData.itemType, config, function( itemId ){
							$item.data( "id", itemId );

							// todo, render item post save
							// todo, save order of all items
						} );
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
	};

	setupDragAndDropBehaviour();


} )( presideJQuery );
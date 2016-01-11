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
	  , setupClickBehaviours
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

	setupClickBehaviours = function(){
		$itemsContainer.on( "click", ".edit-link", function( e ){
			e.preventDefault();
			alert( 'edit clicked' );
		} );

		$itemsContainer.on( "click", ".delete-link", function( e ){
			e.preventDefault();
			alert( 'delete clicked' );
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
			// todo, save order of all items
		};

		$.ajax( saveNewItemEndpoint, {
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
	setupClickBehaviours();

} )( presideJQuery );
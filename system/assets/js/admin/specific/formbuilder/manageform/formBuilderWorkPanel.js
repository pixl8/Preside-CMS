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
	  , itemConfigEndpoint  = cfrequest.formbuilderItemConfigEndpoint
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
		var launchModal
		  , onCancelDialog
		  , onDialogOk
		  , modal
		  , itemData = $item.data();

		launchModal = function( data ) {
			var modalConfig = {
				  title     : data.title
				, message   : data.body
				, className : ""
				, buttons   : {}
				, show      : true
			};

			modalConfig.buttons.cancel = {
				label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" ),
				className : "btn-default",
				callback  : onCancelDialog
			};
			modalConfig.buttons.ok = {
				label     : '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:ok.btn" ),
				className : "btn-primary",
				callback  : onDialogOk
			};

			modal = presideBootbox.dialog( modalConfig );
		};

		onDialogOk = function(){ alert( "onDialogOk" ); };

		onCancelDialog = function(){
			var itemData = $item.data();

			if ( typeof itemData.id === "undefined" ) {
				$item.remove();
			}
		};

		$.ajax( itemConfigEndpoint, {
			  method  : "POST"
			, cache   : false
			, success : launchModal
			, data    : {
				  itemType : itemData.itemType
				, id       : ( itemData.id || "" )
			}
		} );

	};

	setupDragAndDropBehaviour();


} )( presideJQuery );
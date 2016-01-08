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
	  , setupDragAndDropBehaviour, addItemFromDropZone, sortingStopped, addItemDirectlyFromList, processNewItem, saveNewItem;


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
			  stop        : sortingStopped
			, receive     : addItemDirectlyFromList
			, placeholder : "item-type sortable-placeholder"
		} );
	};

	addItemFromDropZone = function( event, ui ){
		var $item = ui.draggable.clone();

		$item.appendTo( $itemsContainer );
		$instructions.removeClass( "empty" );

		processNewItem( $item );
	};

	addItemDirectlyFromList = function( event, ui ){
		processNewItem( ui.helper );
	};

	sortingStopped = function( event, ui ){

	};

	processNewItem = function( $newItem ) {
		var itemTypeConfig = $newItem.data();

		if ( !itemTypeConfig.requiresConfiguration ) {
			saveNewItem( itemTypeConfig.id, {}, function( itemId ){
				console.log( itemId );
			} );
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


	setupDragAndDropBehaviour();


} )( presideJQuery );
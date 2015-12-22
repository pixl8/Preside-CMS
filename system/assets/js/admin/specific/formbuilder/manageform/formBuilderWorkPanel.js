/**
 * I need to be able to:
 *
 * * Drag item types into form workspace
 * * Reorder items
 * * Edit items
 *
 */
( function( $ ){

	var $itemTypes      = $( ".formbuilder-item-type-picker .item-type" )
	  , $itemsContainer = $( ".form-items" )
	  , $instructions   = $( ".instructions" )
	  , setupDragAndDropBehaviour, addItemFromDropZone;


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
			  stop        : function( event, ui ) {}
			, receive     : function( event, ui ) {}
			, placeholder : "item-type sortable-placeholder"
		} );
	};

	addItemFromDropZone = function( event, ui ){
		ui.draggable.clone().appendTo( $itemsContainer );
		$instructions.removeClass( "empty" );
	};

	setupDragAndDropBehaviour();


} )( presideJQuery );
( function( $ ){
	var $mutliSelectPanel     = $( '.multi-select-panel' )
	  , updateSelectedValues;

	updateSelectedValues = function( selectId ) {
		var selectedValues = [];

		$( '#' + selectId + '_to option' ).each(function() {
			selectedValues.push( $(this).val() );
		});

		$( 'input[type=hidden]#' + selectId ).val( selectedValues.toString() );
	};

	$mutliSelectPanel.each( function(event) {
		var curPanelId     = $(this).attr('id')
		  , selectAllBtn   = $(this).find( '#select-all-btn' )
		  , selectBtn      = $(this).find( '#select-btn' )
		  , deselectAllBtn = $(this).find( '#deselect-all-btn' )
		  , deselectBtn    = $(this).find( '#deselect-btn' )
		  , sortUpBtn      = $(this).find( 'a#sort-up' )
		  , sortDownBtn    = $(this).find( 'a#sort-down' );

		// SORTING ACTIONS
		sortUpBtn.on( 'click', function(event) {
			var moveUpSelected = $( '#' + curPanelId + '_to option:selected' );
			var optionAtTop    = moveUpSelected.first().prev();

			if ( optionAtTop.length > 0 ) {
				moveUpSelected.detach().insertBefore( optionAtTop );
			}

			updateSelectedValues( curPanelId );
		});
		sortDownBtn.on( 'click', function(event) {
			var moveDownSelected = $( '#' + curPanelId + '_to option:selected' );
			var optionAtBottom   = moveDownSelected.last().next();

			if ( optionAtBottom.length > 0 ) {
				moveDownSelected.detach().insertAfter( optionAtBottom );
			}

			updateSelectedValues( curPanelId );
		});

		// SELECT ALL ACTION
		selectAllBtn.on( 'click', function(event) {
			event.preventDefault();

			$( '#' + curPanelId + '_from option' ).remove().appendTo( '#' + curPanelId + '_to' );
			updateSelectedValues( curPanelId );
		});

		// SELECT ACTION
		selectBtn.on( 'click', function(event) {
			event.preventDefault();

			$( '#' + curPanelId + '_from option:selected' ).remove().appendTo( '#' + curPanelId + '_to' );
			updateSelectedValues( curPanelId );
		});

		// DESELECT ALL ACTION
		deselectAllBtn.on( 'click', function(event) {
			event.preventDefault();

			$( '#' + curPanelId + '_to option' ).remove().appendTo( '#' + curPanelId + '_from' );
			updateSelectedValues( curPanelId );
		});

		// DESELECT ACTION
		deselectBtn.on( 'click', function(event) {
			event.preventDefault();

			$( '#' + curPanelId + '_to option:selected' ).remove().appendTo( '#' + curPanelId + '_from' );
			updateSelectedValues( curPanelId );
		});
	});
} )( presideJQuery );
( function( $ ){
	var $mutliSelectPanel            = $( '.multi-select-panel' )
	  , $noNestedOptionAvailableHtml = $( 'option.multi-select-panel-no-nested-option-available' ).html()
	  , $noNestedOptionSelectedHtml  = $( 'option.multi-select-panel-no-nested-option-selected' ).html()
	  , updateSelectedValues, updateNestedOptionsEmptyMessages, processSelectionAction;

	updateSelectedValues = function( selectId ) {
		var selectedValues = [];

		$( '#' + selectId + '_to option:not(:disabled)' ).each(function() {
			selectedValues.push( $(this).val() );
		});

		$( 'input[type=hidden]#' + selectId ).val( selectedValues.toString() );
	};

	processSelectionAction = function( panelId, origin, target ) {
		$( '#' + panelId + origin ).each(function() {
			var thisValField = $(this).val().split(".");

			if ( !$(this).is(":disabled") ) {
				if ( thisValField.length > 1 ) {
					$(this).remove().appendTo( '#' + panelId + target + ' optgroup#' + thisValField[0] );
				} else {
					$(this).remove().appendTo( '#' + panelId + target );
				}
			}
		} );

		updateNestedOptionsEmptyMessages( panelId );
	};

	updateNestedOptionsEmptyMessages = function( panelId ) {
		$( '#' + panelId + '_from optgroup' ).each(function() {
			if ( $(this).find( 'option:not(:disabled)' ).length == 0 ) {
				if ( $(this).find( 'option:is(:disabled)' ).length == 0 ) {
					$(this).append( '<option disabled>' + $noNestedOptionAvailableHtml + '</option>' );
				}
			} else {
				$(this).find( 'option:is(:disabled)' ).detach();
			}
		} );

		$( '#' + panelId + '_to optgroup' ).each(function() {
			if ( $(this).find( 'option:not(:disabled)' ).length == 0 ) {
				if ( $(this).find( 'option:is(:disabled)' ).length == 0 ) {
					$(this).append( '<option disabled>' + $noNestedOptionSelectedHtml + '</option>' );
				}
			} else {
				$(this).find( 'option:is(:disabled)' ).detach();
			}
		} );
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

			processSelectionAction( curPanelId, "_from option", "_to" );
			updateSelectedValues( curPanelId );
		});

		// SELECT ACTION
		selectBtn.on( 'click', function(event) {
			event.preventDefault();

			processSelectionAction( curPanelId, "_from option:selected", "_to" );
			updateSelectedValues( curPanelId );
		});

		// DESELECT ALL ACTION
		deselectAllBtn.on( 'click', function(event) {
			event.preventDefault();

			processSelectionAction( curPanelId, "_to option", "_from" );
			updateSelectedValues( curPanelId );
		});

		// DESELECT ACTION
		deselectBtn.on( 'click', function(event) {
			event.preventDefault();

			processSelectionAction( curPanelId, "_to option:selected", "_from" );
			updateSelectedValues( curPanelId );
		});

		updateNestedOptionsEmptyMessages( curPanelId );
	});
} )( presideJQuery );
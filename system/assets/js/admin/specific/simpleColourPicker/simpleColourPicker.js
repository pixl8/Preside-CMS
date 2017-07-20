( function( $ ){
	var $selectedColourSwatches = $( '.selected-colour-swatch' );

	$( '.simple-colour-picker' ).each( function(){
		var   $colourPicker   = $( this )
			, $selectedColour = $colourPicker.find( '.selected-colour-swatch' )
			, $formInput      = $colourPicker.find( '.selected-colour-input' )
			, colourFormat    = $colourPicker.data( 'colourFormat' )
			, rawValues       = $colourPicker.data( 'rawValues' )
			, popoverContent  = $colourPicker.find( '.available-colours' ).html();

		$colourPicker.on( 'click', '.available-colour', function(){
			var newColour = $( this ).data( 'value' );
			var cssColour = rawValues ? ( colourFormat=='hex' ? '#' + newColour : 'rgb( ' + newColour + ' )' ) : newColour;

			$formInput.val( newColour );
			$selectedColour.removeClass( 'unselected' ).css( {
				backgroundColor : cssColour
			} ).popover( 'hide' );
			$( '.popover.fade', $colourPicker ).remove();
			$colourPicker.closest( '.form-group' ).addClass( 'has-info' );
		} )
		.on( 'click', '.clear-selected-colour', function( e ){
			e.preventDefault();
			$formInput.val( '' );
			$selectedColour.addClass( 'unselected' ).css( {
				backgroundColor : '#f5f5f5'
			} ).popover( 'hide' );
			$( '.popover.fade', $colourPicker ).remove();
			$colourPicker.closest( '.form-group' ).removeClass( 'has-info' );
		} );

		$selectedColour.popover( {
			  container : $colourPicker
			, content   : popoverContent
			, html      : true
			, title     : ''
		} );
	});

	$( 'body' ).on( 'click', function( e ) {
		$selectedColourSwatches.each( function() {
			var $swatch = $( this );
			if ( !$swatch.is( e.target ) && $swatch.has( e.target ).length === 0 && $( '.popover' ).has( e.target ).length === 0 ) {
				$swatch.popover( 'hide' );
				$( '.popover.fade', $swatch.closest( '.simple-colour-picker' ) ).remove();
			}
		});
	});

} )( presideJQuery );
( function( $ ) {
	$.fn.dataComparisonPicker = function() {
		return this.each( function() {
			var $formControl = $( this )
			  , $form        = $formControl.closest( "form" )
			  , namePrefix   = $formControl.attr( "name" ).split( "_" )[ 0 ] + "_";
			;

			$form.on( "click change dp.change", function() {
				var data = {};

				$form.find( "[name^='" + namePrefix + "']" ).each( function() {
					if ( this !== $formControl[ 0 ] ) {
						data[ $(this).attr( "name" ).substring( namePrefix.length ) ] = $( this ).val();
					}
				});

				$formControl.val( JSON.stringify( data ) );
			} );
		} );
	};

	$( ".form-control-data-comparison-picker" ).dataComparisonPicker();
} )( presideJQuery );
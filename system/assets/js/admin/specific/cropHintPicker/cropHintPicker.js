( function( $ ){
	$( ".crop-hint-picker" ).each( function(){
		var $chPicker    = $( this )
		  , $formInput   = $chPicker.find( ".crop-hint-input" )
		  , $chImage     = $chPicker.find( ".crop-hint-image" )
		  , $clearButton = $chPicker.find( ".crop-hint-clear" )
		  , jcrop_api;

		$chImage.Jcrop( {
			  onSelect    : selectCrop
			, onRelease   : clearCrop
		}, function() {
			jcrop_api = this;
			loadSelection();
		} );

		$clearButton.on( "click", function() {
			jcrop_api.release();
		} );

		function loadSelection() {
			var cropHint = $formInput.val();

			if ( !cropHint.length ) {
				$clearButton.attr( "disabled", "disabled" );
				return;
			}

			var savedCoords = cropHint.split( "," )
			  , imageWidth  = $chImage.width()
			  , imageHeight = $chImage.height()
			  , coords      = []
			  , selectionSize, i;

			coords.push( Math.round( parseFloat( savedCoords[ 0 ] ) * imageWidth  ) );
			coords.push( Math.round( parseFloat( savedCoords[ 1 ] ) * imageHeight ) );
			coords.push( coords[ 0 ] + Math.round( parseFloat( savedCoords[ 2 ] ) * imageWidth ) );
			coords.push( coords[ 1 ] + Math.round( parseFloat( savedCoords[ 3 ] ) * imageHeight ) );

			jcrop_api.setSelect( coords );
		}

		function clearCrop() {
			$clearButton.attr( "disabled", "disabled" );
			$formInput.val( "" );
		}

		function selectCrop( c ) {
			var coords      = []
			  , imageWidth  = $chImage.width()
			  , imageHeight = $chImage.height();

			coords.push( ( c.x / imageWidth  ).toFixed( 3 ) );
			coords.push( ( c.y / imageHeight ).toFixed( 3 ) );
			coords.push( ( c.w / imageWidth  ).toFixed( 3 ) );
			coords.push( ( c.h / imageHeight ).toFixed( 3 ) );

			$formInput.val( coords.join() );
			$clearButton.removeAttr( "disabled" );
		}
	} );
} )( presideJQuery );
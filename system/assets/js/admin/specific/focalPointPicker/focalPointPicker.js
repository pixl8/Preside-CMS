( function( $ ){
	$( ".focal-point-picker" ).each( function(){
		var $fpPicker    = $( this )
		  , $formInput   = $fpPicker.find( ".focal-point-input" )
		  , $fpImage     = $fpPicker.find( ".focal-point-image" )
		  , $clearButton = $fpPicker.find( ".focal-point-clear" )
		  , $crosshair   = $fpPicker.find( ".focal-point-crosshair" );

		var init = function() {
			var $fpImageClone = $fpImage.clone().removeAttr( "id" ).css( { position: "absolute", left: "-999em", visibility: "hidden" } ).appendTo( "body" );

			if ( $fpImageClone.show().height() ) {
				placeCrosshair( $fpImageClone );
			} else {
				setTimeout( init, 100 );
			}

			$fpImageClone.remove();
		}

		var placeCrosshair = function( $image ) {
			var focalPoint = $formInput.val()
			  , posX
			  , posY;

			if ( !focalPoint.length ) {
				$crosshair.hide();
				$clearButton.attr( "disabled", "disabled" );
				return;
			}

			focalPoint = focalPoint.split( "," );
			posX       = parseFloat( focalPoint[ 0 ] ) * $image.width();
			posY       = parseFloat( focalPoint[ 1 ] ) * $image.height();
			$crosshair.css( { left:posX, top:posY } ).show();
			$clearButton.removeAttr( "disabled" );
		}


		$fpPicker.on( "click", ".focal-point-image", function( e ){
			var posX       = e.pageX - $fpImage.offset().left
			  , posY       = e.pageY - $fpImage.offset().top
			  , focalPoint = [];

			focalPoint.push( ( posX / $fpImage.width()  ).toFixed( 3 ) );
			focalPoint.push( ( posY / $fpImage.height() ).toFixed( 3 ) );

			$formInput.val( focalPoint.join() );
			placeCrosshair( $fpImage );
		} ).on( "click", ".focal-point-clear", function() {
			$formInput.val( "" );
			placeCrosshair( $fpImage );
		} );

		setTimeout( init, 100 );
	});
} )( presideJQuery );
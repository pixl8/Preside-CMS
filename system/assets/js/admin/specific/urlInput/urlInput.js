( function( $ ) {

	$.fn.presideUrlInput = function() {
		return this.each( function() {
			var $hidden   = $( this )
			  , inputName = $hidden.attr( "name" )
			  , inputId   = $hidden.attr( "id" )
			;

			$( '[name="' + inputName + '_protocol"],#' + inputId + "_address").on( "change", function( e ) {
				var $protocol = $( '[name="' + inputName + '_protocol"]' )
				  , $address  = $( "#" + inputId + "_address" )
				;

				if ( $address.val().length > 0 ) {
					var matches     = $address.val().match(/^(https?:\/\/)/i)
					  , protocol    = matches ? matches[0].toLowerCase() : $protocol.val()
					  , $uberSelect = $protocol.data( "uberSelect" )
					;

					if ( $protocol.val().length == 0 && protocol.length == 0 ) {
						protocol = "https://";
					}

					if ( typeof $uberSelect !== "undefined" ) {
						$uberSelect.select( protocol );
					} else {
						$protocol.val( protocol );
					}

					$address.val( $address.val().replace( /^(https?:\/\/)/i, "" ) );

					$hidden.val( $protocol.val() + $address.val() );
				} else {
					$hidden.val( "" );
				}
			} );
		} );
	};

	$( ".url-input-hidden" ).presideUrlInput();

} )( jQuery || presideJQuery );
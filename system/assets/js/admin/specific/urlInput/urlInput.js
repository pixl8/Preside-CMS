( function( $ ) {

	$.fn.presideUrlInput = function() {
		return this.each( function() {
			var $hidden   = $( this )
			  , inputName = $hidden.attr( "name" )
			  , inputId   = $hidden.attr( "id" )
			;

			$( '[name="' + inputName + '_protocol"],#' + inputId + "_domain_path").on( "change", function( e ) {
				var $protocol   = $( '[name="' + inputName + '_protocol"]' )
				  , $domainPath = $( "#" + inputId + "_domain_path" )
				;

				if ( $domainPath.val().length > 0 ) {
					if ( $protocol.val().length == 0 ) {
						var matches     = $domainPath.val().match( /^(.*:\/\/)/g )
						  , protocol    = matches ? matches[ 0 ] : ""
						  , $uberSelect = $protocol.data( "uberSelect" )
						;

						if ( typeof $uberSelect !== "undefined" ) {
							$uberSelect.select( protocol );
						} else {
							$protocol.val( protocol );
						}
					}

					$domainPath.val( $domainPath.val().replace( /^https?:\/\//, "" ) );

					$hidden.val( $protocol.val() + $domainPath.val() );
				} else {
					$hidden.val( "" );
				}
			} );
		} );
	};

	$( ".url-input-hidden" ).presideUrlInput();

} )( jQuery || presideJQuery );
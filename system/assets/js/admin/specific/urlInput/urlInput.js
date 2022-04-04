( function( $ ) {

	$.fn.presideUrlInput = function() {
		return this.each( function() {
			$( this ).on( "change", function( e ) {
				var $hidden     = $( this ).closest( ".row" ).next( 'input[type="hidden"]' )
				  , inputId     = $hidden.attr( "id" )
				  , $protocol   = $( "#" + inputId + "_protocol" )
				  , $domainPath = $( "#" + inputId + "_domain_path" )
				;

				if ( $protocol.val().length > 0 && $domainPath.val().length > 0 ) {
					var matches = $domainPath.val().match( /^(.*:\/\/)/g );

					$protocol.val( matches ? matches[ 0 ] : "https://" );

					$domainPath.val( $domainPath.val().replace( /^https?:\/\//, "" ) );

					$hidden.val( $protocol.val() + $domainPath.val() );
				} else {
					$hidden.val( "" );
				}
			} );
		} );
	};

	$( ".url-input-protocol,.url-input-domain-path" ).presideUrlInput();

} )( jQuery || presideJQuery );
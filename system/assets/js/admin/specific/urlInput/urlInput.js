( function( $ ) {

	$.fn.presideUrlInput = function() {
		return this.each( function() {
			var $input = $( this );

			$input.on( "change", function( e ) {
				var $this   = $( this )
				  , $hidden = $this.closest( ".row" ).next( 'input[type="hidden"]' )
				  , inputId = $hidden.attr( "id" )
				  , $protocol   = $( "#" + inputId + "_protocol" )
				  , $domainPath = $( "#" + inputId + "_domain_path" )
				;

				if ( $protocol.val().length > 0 && $domainPath.val().length > 0 ) {
					$hidden.val( $protocol.val() + $domainPath.val() );
				} else {
					$hidden.val( "" );
				}
			} );
		} );
	};

	$( ".url-input-protocol,.url-input-domain-path" ).presideUrlInput();

} )( jQuery || presideJQuery );
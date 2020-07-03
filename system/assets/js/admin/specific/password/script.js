( function( $ ){

	$( "body" ).on( "click", ".toggle-password", function() {
		var $toggle = $( this )
		  , $input  = $( $toggle.data( "target" ) )
		  , type    = $input.attr( "type" );

		$toggle.toggleClass( "fa-eye fa-eye-slash" );
		$input.attr( "type", type=="password" ? "text" : "password" );
	});

} )( presideJQuery );
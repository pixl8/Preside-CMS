( function( $ ){

	$( "body" ).on( "click", ".load-in-place", function( e ) {
		e.preventDefault();

		var $link = $( this )
		  , $modalBody = $link.closest( ".bootbox-body" );

		$.ajax( {
			  method  : "GET"
			, url     : $link.attr( 'href' )
			, cache   : false
			, success : function( content ){
				$modalBody.html( content );
			  }
		} );
	} );

} )( presideJQuery );
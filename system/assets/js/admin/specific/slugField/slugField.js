( function( $ ){
	$( '#pageSlug' ).html( $( '#slug' ).val() );

	$( '#slug' ).on( 'keyup', function() {
		$( '#pageSlug' ).html( $(this).val() );
	});

} )( presideJQuery );
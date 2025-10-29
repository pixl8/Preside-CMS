( function( $ ){

	$( '.presidecms [data-read-all="true"]' ).readall();
	$( "body" ).on( "onShowPresideBootboxModal", function( e, $modal ){
		$modal.on( "shown.bs.modal", function(){
			$modal.find( '[data-read-all="true"]' ).readall();
		} );
	} );

} )( presideJQuery );
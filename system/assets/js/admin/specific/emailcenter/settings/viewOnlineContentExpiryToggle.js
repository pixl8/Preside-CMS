( function( $ ){
	var $removeViewOnlineContentField = $( 'input[name="remove_view_online_content"]' )
	  , $viewOnlineExpiryFieldGroup   = $( 'input[name="view_online_content_expiry"' ).closest( ".form-group" );

	if ( $removeViewOnlineContentField.is( ":checked" ) ) {
		$viewOnlineExpiryFieldGroup.show();
	} else {
		$viewOnlineExpiryFieldGroup.hide();
	}

	$removeViewOnlineContentField.on( "change", function() {
		if ( $(this).is( ":checked" ) ) {
			$viewOnlineExpiryFieldGroup.show();
		} else {
			$viewOnlineExpiryFieldGroup.hide();
		}
	} );
} )( presideJQuery );
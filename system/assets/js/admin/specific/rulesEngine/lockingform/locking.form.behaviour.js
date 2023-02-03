( function( $ ){
	var $lockedInput = $( "[name=is_locked]" )
	  , $form        = $lockedInput.length ? $lockedInput.closest( "form" ) : [];

	if ( $form.length ) {
		var $lockedReasonContainer = $form.find( "#locked_reason" ).closest( ".form-group" )
		  , toggleReasonField;

		toggleReasonField = function(){
			if ( $lockedInput.is( ":checked" ) ) {
				$lockedReasonContainer.show();
			} else {
				$lockedReasonContainer.hide();
			}
		};

		$form.on( "click change", "[name=is_locked]", toggleReasonField );
		toggleReasonField();
	}

} )( presideJQuery );
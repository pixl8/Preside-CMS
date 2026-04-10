( function( $ ){

	var $tagToggleInput = $( "[name=segmentation_tag_enabled]" )
	  , $form           = $tagToggleInput.length ? $tagToggleInput.closest( "form" ) : [];

	if ( $form.length ) {
		var $tagToggleConfigFieldset = $form.find( "#fieldset-tag_config" )
		  , toggleConfigFieldSet;

		toggleConfigFieldSet = function(){
			if ( $tagToggleInput.is( ":checked" ) ) {
				$tagToggleConfigFieldset.show( "fast" );
			} else {
				$tagToggleConfigFieldset.hide( "fast" );
			}
		};

		$form.on( "click change", "[name=segmentation_tag_enabled]", toggleConfigFieldSet );
		toggleConfigFieldSet();
	}

} )( presideJQuery );
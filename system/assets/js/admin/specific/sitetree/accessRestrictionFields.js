( function( $ ){
	var $accessRestrictionField = $( "[name=access_restriction]" );

	if ( $accessRestrictionField.length ) {
		var $fieldsets = $( "#fieldset-rules" )
		  , toggleAdvancedFields;

		toggleAdvancedFields = function(){
			var restriction = $accessRestrictionField.val();

			switch( restriction ) {
				case "partial":
				case "full":
					$fieldsets.show();
				break;
				default:
					$fieldsets.hide();
			}
		};

		$( "form" ).on( "change", "[name=access_restriction]", toggleAdvancedFields );
		toggleAdvancedFields();
	}

} )( presideJQuery );
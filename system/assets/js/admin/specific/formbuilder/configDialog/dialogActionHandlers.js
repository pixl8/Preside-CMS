( function( $ ){

	var $configForm        = $( ".formbuilder-item-config-form" )
	  , validationEndpoint = cfrequest.formBuilderValidationEndpoint;

	window.validateFormBuilderItemConfig = function( formId, itemId, callback ){

		if ( !$configForm.valid() ) {
			callback( false );
		}

		var data = getFormBuilderItemConfig();
		data.formId = formId;
		data.itemId = itemId;

		$.ajax( validationEndpoint, {
			  method : "POST"
			, cache  : false
			, data   : data
			, success : function( data ) {
				if ( data === true ) {
					callback( true );
				} else {
					$configForm.validate().showErrors( data );
					callback( false );
				}
			}
		} );

		return $configForm.valid();
	};

	window.getFormBuilderItemConfig = function(){
		return $configForm.serializeObject();
	};

} )( presideJQuery );
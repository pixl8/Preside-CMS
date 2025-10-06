( function( $ ) {

	var fieldName      = cfrequest.instancePickerField         || 'instance'
	  , $instanceField = $( '[name="' + fieldName + '"]' )
	  , webflowField   = cfrequest.instancePickerWebflowField  || 'webflow'
	  , $webflowField  = $( '[name="' + webflowField + '"]' )
	  , typeField      = cfrequest.instancePickerTypeField     || 'type'
	  , $typeField     = $( '[name="' + typeField + '"]' )
	  , getOptionsUrl  = cfrequest.instancePickerGetOptionsUrl || ''
	  , updateInstanceOptions, getWebflowId, getSelectedType;

	getWebflowId = function() {
		return $webflowField.val();
	};

	getSelectedType = function() {
		return $( '[name="' + typeField + '"]:checked' ).val();
	};

	updateInstanceOptions = function( webflowId=getWebflowId(), selectedType=getSelectedType() ) {
		$.ajax({
			  url  : getOptionsUrl
			, type : "GET"
			, data : {
				  webflowId    : webflowId
				, selectedType : selectedType
			}
		})
		.done(function(options) {
			$instanceField.empty();

			$.each( options.values, function( index, val ) {
				$instanceField.append( $( "<option>", {
					  value : options.values[ index ]
					, text  : options.labels[ index ]
				} ) );
			} );

			$instanceField.val( $instanceField.data( "value" ) );
		});
	};

	if ( getOptionsUrl.length > 0 ) {
		$webflowField.on( "change", function( event ) {
			updateInstanceOptions();
		} );

		$typeField.on( "change", function( event ) {
			updateInstanceOptions();
		} );

		updateInstanceOptions();
	}

} )( jQuery || presideJQuery );
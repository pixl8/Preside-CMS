( function( $ ) {

	var fieldName                = cfrequest.instancePickerField         || 'instance'
	  , $instanceField           = $( '[name="' + fieldName + '"]' )
	  , webflowField             = cfrequest.instancePickerWebflowField  || 'webflow'
	  , $webflowField            = $( '[name="' + webflowField + '"]' )
	  , typeField                = cfrequest.instancePickerTypeField     || 'type'
	  , $typeField               = $( '[name="' + typeField + '"]' )
	  , getOptionsUrl            = cfrequest.instancePickerGetOptionsUrl || ''
	  , $currentStatusesField    = $( '[name="current_statuses"]' ).closest( ".form-group" )
	  , $historicalStatusesField = $( '[name="historical_statuses"]' ).closest( ".form-group" )
	  , updateInstanceOptions, updateTypeStatusFeild, getWebflowId, getSelectedType;

	getWebflowId = function() {
		return $webflowField.val();
	};

	getSelectedType = function() {
		return $( '[name="' + typeField + '"]:checked' ).val();
	};

	updateTypeStatusFeild = function( selectedType=getSelectedType() ) {
		if ( selectedType == "current" ) {
			$currentStatusesField.show();
			$historicalStatusesField.hide();
		} else if ( selectedType == "historical" ) {
			$currentStatusesField.hide();
			$historicalStatusesField.show();
		} else {
			$currentStatusesField.hide();
			$historicalStatusesField.hide();
		}
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

			if ( options.values.length > 0 ) {
				$instanceField.closest( ".form-group" ).show( "fast" );

				$.each( options.values, function( index, val ) {
					$instanceField.append( $( "<option>", {
						  value : options.values[ index ]
						, text  : options.labels[ index ]
					} ) );
				} );

				$instanceField.val( $instanceField.data( "value" ) );
			} else {
				$instanceField.closest( ".form-group" ).hide( "fast" );
			}
		});
	};

	if ( getOptionsUrl.length > 0 ) {
		$webflowField.on( "change", function( event ) {
			updateInstanceOptions();
		} );

		$typeField.on( "change", function( event ) {
			updateInstanceOptions();
			updateTypeStatusFeild()
		} );

		updateInstanceOptions();
		updateTypeStatusFeild();
	}

} )( jQuery || presideJQuery );
( function( $ ){
	window.assetUploader = {
		nextStep : function(){
			var $form = $( '.asset-picker-upload-form:first' )
			  , dz;

			if ( $form.length ) {
				dz = $form.data( 'dropzone' );

				if ( typeof dz !== "undefined" ) {
					if ( dz.getAcceptedFiles().length ) {
						$( '.asset-picker-upload-form:first' ).submit();
					}
				}
			}

		},
		checkLastStep : function(){}
	};

} )( presideJQuery );
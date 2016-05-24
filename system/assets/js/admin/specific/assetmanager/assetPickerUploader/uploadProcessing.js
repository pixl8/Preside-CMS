( function( $ ){

	var $form = $( "#add-assets-form" );

	window.assetUploader = {
		getUploaded : function(){
			var uploader = $form.length && $form.data( "presdideUploader" );

			return uploader === "undefined" ? [] : uploader.getUploadedAssetIds();
		}
	};

	if ( $form.length ) {
		$form.on( "assetsUploaded", function(){
			if ( typeof uberAssetSelect !== "undefined" ) {
				var modal = uberAssetSelect.uploadIframeModal;
				$( modal.modal ).find( ".ok-button" ).prop( "disabled", false );
			}
		} );

		$form.on( "click", ".select-assets-link", function( e ){
			e.preventDefault();

			if ( typeof uberAssetSelect !== "undefined" ) {
				uberAssetSelect.processUploadOk();
			}
		} );
	}

} )( presideJQuery );
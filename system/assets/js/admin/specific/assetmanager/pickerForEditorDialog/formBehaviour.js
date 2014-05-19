( function( $ ){

	var $form
	  , $assetPicker
	  , $titleInput
	  , $dimensions
	  , originalAssetValue
	  , isImageForm
	  , checkAndProcessChangedAsset
	  , populateAssetDetails
	  , setupForm
	  , assetDetailsUrl;

	setupForm = function(){
		$form       = $( "#image-config-form" );
		isImageForm = $form.length;

		if ( isImageForm ) {
			$titleInput     = $form.find( "input[name='alt_text']" );
			$dimensions     = $form.find( "input[name='dimensions']" );
			assetDetailsUrl = buildAjaxLink( "assetmanager.getImageDetailsForCKEditorImageDialog" );

		} else {
			$form           = $( "#attachment-config-form" );
			$titleInput     = $form.find( "input[name='link_text']" );
			assetDetailsUrl = buildAjaxLink( "assetmanager.getAttachmentDetailsForCKEditorDialog" );
		}

		if ( $form.length ) {
			$assetPicker       = $form.find( "input[name='asset']" );
			originalAssetValue = $assetPicker.val();

			$form.on( 'click change blur focus', checkAndProcessChangedAsset );
		}
	};

	checkAndProcessChangedAsset = function(){
		if ( $assetPicker.val() !== originalAssetValue ) {
			originalAssetValue = $assetPicker.val();

			$( 'body' ).presideLoadingSheen( true );

			$.ajax({
				  url      : assetDetailsUrl
				, method   : "POST"
				, data     : { asset : originalAssetValue }
				, success  : populateAssetDetails
				, complete : function(){ $( 'body' ).presideLoadingSheen( false ); }
			});
		}
	};

	populateAssetDetails = function( data ){
		if ( isImageForm && data.width && data.height ) {
			$dimensions.data( "ImageDimensionPicker" ).reset( data.width, data.height );
		}

		if ( data.LABEL ) {
			$titleInput.val( data.LABEL );
		}
	};

	setupForm();

} )( presideJQuery );
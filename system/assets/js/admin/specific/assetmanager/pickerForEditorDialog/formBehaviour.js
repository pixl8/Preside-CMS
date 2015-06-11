( function( $ ){

	var $form
	  , $assetPicker
	  , $titleInput
	  , $dimensions
	  , originalAssetValue
	  , assetType
	  , checkAndProcessChangedAsset
	  , populateAssetDetails
	  , setupForm
	  , assetDetailsUrl;

	setupForm = function(){
		$form       = $( "#asset-config-form" );
		assetType   = $form.data( "assetType" ) || "image";

		if ( assetType === "image" ) {
			$titleInput     = $form.find( "input[name='alt_text']" );
			$dimensions     = $form.find( "input[name='dimensions']" );
			assetDetailsUrl = buildAjaxLink( "assetmanager.getImageDetailsForCKEditorImageDialog" );

		} else {
			$titleInput     = $form.find( "input[name='link_text']" );
			assetDetailsUrl = buildAjaxLink( "assetmanager.getAttachmentDetailsForCKEditorDialog" );
		}

		if ( $form.length ) {
			setTimeout( function() {
				$assetPicker       = $form.find( "input[name='asset']" );
				originalAssetValue = $assetPicker.val();

				$.ajax({
					  url      : assetDetailsUrl
					, method   : "POST"
					, data     : { asset : originalAssetValue }
					, success  : function( data ){
						$titleInput.attr( 'placeholder', data.LABEL || '' );
					}
				});

				$form.on( 'click change blur focus', checkAndProcessChangedAsset );
			}, 10 );
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
		if ( assetType === "image" && data.WIDTH && data.HEIGHT ) {
			$dimensions.data( "ImageDimensionPicker" ).reset( data.WIDTH, data.HEIGHT );
		}

		$titleInput.attr( 'placeholder', data.LABEL || '' );
	};

	setupForm();

} )( presideJQuery );
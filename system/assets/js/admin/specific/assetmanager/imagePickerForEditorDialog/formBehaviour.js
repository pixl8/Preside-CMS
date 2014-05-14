( function( $ ){

	var $form = $( "#image-config-form" )
	  , $assetPicker = $form.find( "input[name='asset']" )
	  , $altText     = $form.find( "input[name='alt_text']" )
	  , $dimensions  = $form.find( "input[name='dimensions']" )
	  , originalAssetValue = $assetPicker.val()
	  , checkAndProcessChangedAsset
	  , populateAssetDetails;

	checkAndProcessChangedAsset = function(){
		if ( $assetPicker.val() !== originalAssetValue ) {
			originalAssetValue = $assetPicker.val();

			$( 'body' ).presideLoadingSheen( true );

			$.ajax({
				  url      : buildAjaxLink( "assetmanager.getImageDetailsForCKEditorImageDialog", { asset : originalAssetValue } )
				, success  : populateAssetDetails
				, complete : function(){ $( 'body' ).presideLoadingSheen( false ); }
			});
		}
	};

	populateAssetDetails = function( data ){
		if ( data.width && data.height ) {
			$dimensions.data( "ImageDimensionPicker" ).reset( data.width, data.height );
		}

		if ( data.LABEL ) {
			$altText.val( data.LABEL );
		}
	};

	$form.on( 'click change blur focus', checkAndProcessChangedAsset );

} )( presideJQuery );
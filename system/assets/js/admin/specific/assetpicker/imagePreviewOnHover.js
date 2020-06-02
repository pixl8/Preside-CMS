( function( $ ){
	var $selectedAsset = $('.asset-picker span')
	  , xOffset        = 10
	  , yOffset        = 30
	  , showImagePreview
	  , destroyImagePreview
	  , adjustImagePreviewPosition;


	showImagePreview = function( e ){
		var $selected = $( this )
		  , imgSource  = $selected.data( 'image' );

		if ( imgSource && imgSource.length ) {

			$( "body" ).append("<div id='asset-thumbnail'><img src='"+ imgSource +"' alt='' /></div>" );
			$( "#asset-thumbnail" )
			    .css( "top" , ( e.pageY - xOffset ) + "px" )
			    .css( "left", ( e.pageX + yOffset ) + "px" )
			    .fadeIn( "fast" );
		}
	};

	destroyImagePreview = function( e ){
		var $thumbnail = $( "#asset-thumbnail" );
		if ( $thumbnail.length ) {
			$thumbnail.remove();
		}
	};

	adjustImagePreviewPosition = function( e ){
		$("#asset-thumbnail")
			.css( "top" , ( e.pageY - xOffset ) + "px" )
			.css( "left", ( e.pageX + yOffset ) + "px" );
	};

	$selectedAsset.on( "mouseenter", ".icon-container", showImagePreview    );
	$selectedAsset.on( "mouseleave", ".icon-container", destroyImagePreview );
	$selectedAsset.on( "mousemove", ".icon-container", adjustImagePreviewPosition );

})( presideJQuery );

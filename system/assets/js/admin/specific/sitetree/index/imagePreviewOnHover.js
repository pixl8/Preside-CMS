( function( $ ){
	var $treeTable = $( ".tree-table" )
	  , xOffset    = 10
	  , yOffset    = 30
	  , showImagePreview
	  , destroyImagePreview
	  , adjustImagePreviewPosition;


	showImagePreview = function( e ){
		var $pageTitle = $( this )
		  , imgSource  = $pageTitle.data( 'image' );

		if ( imgSource && imgSource.length ) {

			$( "body" ).append("<p id='page-thumbnail'><img src='"+ imgSource +"' alt='' /></p>" );
			$( "#page-thumbnail" )
			    .css( "top" , ( e.pageY - xOffset ) + "px" )
			    .css( "left", ( e.pageX + yOffset ) + "px" )
			    .fadeIn( "fast" );
		}
	};

	destroyImagePreview = function( e ){
		var $thumbnail = $( "#page-thumbnail" );
		if ( $thumbnail.length ) {
			$thumbnail.remove();
		}
	};

	adjustImagePreviewPosition = function( e ){
		$("#page-thumbnail")
			.css( "top" , ( e.pageY - xOffset ) + "px" )
			.css( "left", ( e.pageX + yOffset ) + "px" );
	};

	$treeTable.on( "mouseenter", ".page-title", showImagePreview    );
	$treeTable.on( "mouseleave", ".page-title", destroyImagePreview );
	$treeTable.on( "mousemove", ".page-title", adjustImagePreviewPosition );

})( presideJQuery );

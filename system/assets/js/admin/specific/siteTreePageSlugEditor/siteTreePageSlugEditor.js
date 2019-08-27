( function( $ ){
	$( '.slug-editor' ).each( function(){
		var $editor        = $( this )
		  , $slugPreview   = $editor.siblings( ".page-url-preview" ).find( ".page-slug" )
		  , $parentPreview = $editor.siblings( ".page-url-preview" ).find( ".parent-slug" )
		  , $parentInput   = $editor.parents( "form" ).find( "input[name='parent_page']" )
		  , parentFetchUrl = $editor.siblings( "input[name='parent_slug_ajax']" ).val();

		$slugPreview.html( $editor.val() );

		$editor.on( "keyup", function(){
			$slugPreview.html( $editor.val() );
		} );

		if ( $parentInput.length ) {
			$parentInput.on( "change", function() {
				$.ajax({
					  url     : parentFetchUrl
					, method  : "GET"
					, data    : "parent_page=" + $parentInput.val()
					, success : function( data ){ $parentPreview.html( data ); }
				});
			} );
		}
	});
} )( presideJQuery );
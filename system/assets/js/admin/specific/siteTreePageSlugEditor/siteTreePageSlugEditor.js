( function( $ ){
	$( '.slug-editor' ).each( function(){
		var $editor        = $( this )
		  , $slugPreview   = $editor.siblings( ".page-url-preview" ).find( ".page-slug" )
		  , $parentPreview = $editor.siblings( ".page-url-preview" ).find( ".parent-slug" )
		  , $parentInput   = $editor.parents( "form" ).find( "input[name='parent_page']" )
		  , parentFetchUrl = $editor.siblings( "input[name='parent_slug_ajax']" ).val();

		$slugPreview.text( $editor.val() );

		$editor.on( "keyup", function(){
			$slugPreview.text( $editor.val() );
		} );

		if ( $parentInput.length ) {
			$parentInput.on( "change", function() {
				$.ajax({
					  url     : parentFetchUrl
					, method  : "GET"
					, data    : { parent_page: $parentInput.val(), _sid: cfrequest._sid }
					, success : function( data ){ $parentPreview.text( data ); }
				});
			} );
		}
	});
} )( presideJQuery );
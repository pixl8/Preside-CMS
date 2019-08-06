( function( $ ){
	$( '.slug-editor' ).each( function(){
		var slugEditorId = $(this).attr( 'id' );
		$( "#slug-editor-"+slugEditorId ).html( $(this).val() );
	});

	$( '.slug-editor' ).on( 'keyup', function() {
		var slugEditorId = $(this).attr( 'id' );
		$( "#slug-editor-"+slugEditorId ).html( $(this).val() );
	});

	$( "input[name='parent_page']" ).on( 'change', function() {
		$.ajax({
			  url     : $( "input[name='parent_slug_ajax']" ).val()
			, method  : "GET"
			, data    : "parent_page=" + $(this).val()
			, success : function( data ){
				$( '.parent-slug' ).html( data );
			}
		});
	});

} )( presideJQuery );
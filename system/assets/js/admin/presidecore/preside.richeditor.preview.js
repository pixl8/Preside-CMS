( function( $ ){

	var previewEndpoint = buildAdminLink( "dataHelpers", "richeditorPreview" );

	$.fn.richeditorPreview = function(){
		return this.each( function(){
			var $container = $( this )
			  , content    = $container.find( ".admin-richeditor-preview-content" ).html();

			$container.addClass( "loading" );

			$.post( previewEndpoint, { "content":content }, function( result ){
				var $iframe = $( '<iframe frameborder="0" class="admin-richeditor-preview-iframe"></iframe>' )
				  , iframe  = $iframe.get( 0 );

				$container.append( $iframe );

				iframe.contentWindow.document.open( 'text/html' );
				iframe.contentWindow.document.write( result );
				iframe.contentWindow.document.close();

				$iframe.height( $( iframe.contentWindow.document ).height() + "px" );
			} );
		} );
	};

	$( ".admin-richeditor-preview-container" ).richeditorPreview();

} )( presideJQuery );
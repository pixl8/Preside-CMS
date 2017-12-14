( function( $ ){

	$( "body" )
	.on( "click", ".load-in-place", function( e ) {
		e.preventDefault();

		var $link = $( this )
		  , $modalBody = $link.closest( ".bootbox-body" );

		$.ajax( {
			  method  : "GET"
			, url     : $link.attr( 'href' )
			, cache   : false
			, success : function( content ){
				$modalBody.html( content );
			  }
		} );
	} )
	.on( "shown.bs.tab", ".load-html-preview", function( e ) {
		var $tab    = $( this )
		  , $iframe = $( $tab.attr( "href" ) ).find( ".html-message-iframe" )
		  , $src    = $( "#" + $iframe.data( "src" ) )
		  , iframe  = $iframe.get( 0 );
		
		if ( $tab.data( "previewLoaded" ) ) {
			return;
		}

		iframe.contentWindow.document.open( 'text/html' );
		iframe.contentWindow.document.write( $src.html() );
		iframe.contentWindow.document.close();

		$iframe.height( $( iframe.contentWindow.document ).height() + 100 + "px" );
		$tab.data( "previewLoaded", true );
	} );

} )( presideJQuery );
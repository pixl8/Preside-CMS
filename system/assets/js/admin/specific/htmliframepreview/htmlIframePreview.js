;( function( $ ){
	$( "iframe[data-src]" ).each( function(){
		var   $iframe = $( this )
			, $src    = $( "#" + $iframe.data( "src" ) );

		this.contentWindow.document.open( 'text/html' );
		this.contentWindow.document.write( $src.html() );
		this.contentWindow.document.close();

		$iframe.height( $( this.contentWindow.document ).height() + 100 + "px" );
	});
})( presideJQuery );
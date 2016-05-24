( function( $ ){
	var linkWasClicked = function( eventTarget ){
		var $target = $( eventTarget );

		return $.inArray( eventTarget.nodeName, ['A','INPUT','BUTTON','TEXTAREA','SELECT'] ) >= 0
		    || $target.parents( 'a:first,input:first,button:first,textarea:first,select:first' ).length
		    || $target.data( 'toggle' )
		    || ( $target.hasClass( 'lbl' ) && $target.prev( 'input' ).length )
	};

	$( "body" ).on( "click", "tr.clickable", function( e ){
		if ( !linkWasClicked( e.target ) ) {
			var $firstLink = $( this ).find( 'a:first' );

			if ( $firstLink.length ) {
				e.preventDefault();
				$firstLink.get(0).click();
			}
		}
	} )
} )( presideJQuery );
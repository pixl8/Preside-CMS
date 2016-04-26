( function( $ ){
	var linkWasClicked = function( eventTarget ){
		return $.inArray( eventTarget.nodeName, ['A','INPUT','BUTTON','TEXTAREA','SELECT'] ) >= 0
		    || $( eventTarget ).parents( 'a:first,input:first,button:first,textarea:first,select:first' ).length
		    || $( eventTarget ).data( 'toggle' );
	};

	$( "body" ).on( "click", "tr.clickable", function( e ){
		var checkBoxOrNot = e.target.previousElementSibling != null && typeof e.target.previousElementSibling.type !== "undefined" && e.target.previousElementSibling.type == 'checkbox';

		if ( !linkWasClicked( e.target ) && !checkBoxOrNot ) {
			var $firstLink = $( this ).find( 'a:first' );

			if ( $firstLink.length ) {
				e.preventDefault();
				$firstLink.get(0).click();
			}
		}
	} )
} )( presideJQuery );
( function( $ ){
	var linkWasClicked = function( eventTarget ){
		var $target = $( eventTarget );

		return $.inArray( eventTarget.nodeName, ['A','INPUT','BUTTON','TEXTAREA','SELECT'] ) >= 0
		    || $target.parents( 'a:first,input:first,button:first,textarea:first,select:first' ).length
		    || $target.data( 'toggle' )
		    || ( $target.hasClass( 'lbl' ) && $target.prev( 'input' ).length )
	};

	var getSelected = function () {
		if (window.getSelection) {
			return window.getSelection().toString();
		} else if (document.getSelection) {
			return document.getSelection().toString();
		} else {
			var selection = document.selection && document.selection.createRange();
			if (selection.text) {
				return selection.text.toString();
			}
		}
		return "";
	}

	$( "body" ).on( "click", "tr.clickable", function( e ){
		if ( !linkWasClicked( e.target ) ) {
			var anyBoxesTicked = $( this ).closest( 'table' ).find( 'tr > td:first-child input:checkbox:checked' ).length;

			if ( anyBoxesTicked ) {
				var $rowCheckbox = $( this ).find( '> td:first-child input:checkbox' );
				if ( $rowCheckbox.length ) {
					e.preventDefault();
					$rowCheckbox.click();
					return;
				}
			}

			var sel = getSelected();
			if (sel !== "") {
				return;
			}

			var $firstLink = $( this ).find( 'a.row-link:first' );

			if ( !$firstLink.length ) {
				$firstLink = $( this ).find( 'a:first' );
			}

			if ( !$firstLink.length ) {
				$firstLink = $( this ).find( 'input:first' );
			}

			if ( $firstLink.length ) {
				e.preventDefault();
				$firstLink.get(0).click();
			}
		}
	} )
} )( presideJQuery );
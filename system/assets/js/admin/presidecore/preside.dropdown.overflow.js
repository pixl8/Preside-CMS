( function( $ ) {
	"use strict";

	function fixVerticalOverflow( $menu ) {
		if ( !$menu.length ) return;

		$menu.css( { maxHeight: "", overflowY: "" } );

		var rect = $menu[ 0 ].getBoundingClientRect();
		var vh   = window.innerHeight;

		if ( rect.bottom > vh ) {
			$menu.css( {
				  maxHeight : Math.max( vh - rect.top - 10, 100 ) + "px"
				, overflowY : "auto"
			} );
		}
	}

	function fixSubmenuPosition( $item ) {
		var $submenu = $item.find( "> .dropdown-menu" );
		if ( !$submenu.length || !$submenu.is( ":visible" ) ) return;

		var rect = $submenu[ 0 ].getBoundingClientRect();
		var vw   = window.innerWidth;
		var vh   = window.innerHeight;

		if ( rect.right > vw ) {
			$submenu.css( { left: "auto", right: "100%" } );
			rect = $submenu[ 0 ].getBoundingClientRect();
		} else if ( rect.left < 0 ) {
			$submenu.css( { left: "100%", right: "auto" } );
			rect = $submenu[ 0 ].getBoundingClientRect();
		}

		if ( rect.bottom > vh ) {
			$submenu.css( {
				  maxHeight : Math.max( vh - rect.top - 10, 100 ) + "px"
				, overflowY : "auto"
			} );
		}
	}

	$( document ).on( "shown.bs.dropdown", function( e ) {
		var $menu = $( e.target ).find( "> .dropdown-menu" ).first();
		if ( $menu.length ) {
			fixVerticalOverflow( $menu );
		}
	} );

	$( document ).on( "mouseenter", ".dropdown-menu .dropdown-hover", function() {
		var $item    = $( this );
		var $submenu = $item.find( "> .dropdown-menu" );
		if ( !$submenu.length ) return;

		$submenu.css( { left: "", right: "", maxHeight: "", overflowY: "" } );

		window.requestAnimationFrame( function() {
			fixSubmenuPosition( $item );
		} );
	} );

} )( presideJQuery );
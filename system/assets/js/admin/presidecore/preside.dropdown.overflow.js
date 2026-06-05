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

	function fixHorizontalOverflow( $menu ) {
		if ( !$menu.length ) return;

		$menu.css( { left: "", right: "" } );

		var rect = $menu[ 0 ].getBoundingClientRect();
		var vw   = window.innerWidth;

		if ( rect.right > vw ) {
			$menu.css( { left: "auto", right: "0" } );
		} else if ( rect.left < 0 ) {
			$menu.css( { left: "0", right: "auto" } );
		}
	}

	function fixSubmenuPosition( $item ) {
		var $submenu    = $item.find( "> .dropdown-menu" );
		var $parentMenu = $item.closest( ".dropdown-menu" );
		if ( !$submenu.length || !$submenu.is( ":visible" ) ) return;

		var vw = window.innerWidth;
		var vh = window.innerHeight;

		if ( $parentMenu.css( "overflow-y" ) === "auto" ) {
			var itemRect  = $item[ 0 ].getBoundingClientRect();
			var submenuW  = $submenu.outerWidth();
			var submenuH  = $submenu.outerHeight();
			var leftPos   = itemRect.right;

			if ( leftPos + submenuW > vw ) {
				leftPos = itemRect.left - submenuW;
			}

			var topPos = itemRect.top - 5;
			if ( topPos + submenuH > vh ) {
				topPos = Math.max( vh - submenuH - 10, 0 );
			}

			$submenu.css( { position: "fixed", left: leftPos + "px", top: topPos + "px", right: "auto" } );
			return;
		}

		var rect = $submenu[ 0 ].getBoundingClientRect();

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
			fixHorizontalOverflow( $menu );
		}
	} );

	$( document ).on( "mouseenter", ".dropdown-menu .dropdown-hover", function() {
		var $item    = $( this );
		var $submenu = $item.find( "> .dropdown-menu" );
		if ( !$submenu.length ) return;

		$submenu.css( { position: "", left: "", right: "", top: "", maxHeight: "", overflowY: "" } );

		window.requestAnimationFrame( function() {
			fixSubmenuPosition( $item );
		} );
	} );

	$( document ).on( "mouseleave", ".dropdown-menu .dropdown-hover", function() {
		$( this ).find( "> .dropdown-menu" ).css( { position: "", left: "", right: "", top: "" } );
	} );

} )( presideJQuery );
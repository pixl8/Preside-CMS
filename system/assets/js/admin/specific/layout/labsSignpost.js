( function( $ ){

	var storageKey = "presideLabsSignpostShown";
	var edgeMargin = 20;
	var $anchor    = $( ".labs-signpost-anchor" );

	var keepSignpostInView = function() {
		var popover      = $anchor.data( "bs.popover" );
		var $tip         = popover ? popover.tip() : $();
		var pageEdge     = document.documentElement.clientWidth - edgeMargin;
		var overflow     = 0;
		var anchorCenter = 0;

		if ( !$tip.length ) {
			return;
		}

		overflow = $tip.offset().left + $tip.outerWidth() - pageEdge;

		if ( overflow > 0 ) {
			$tip.css( "left", Math.max( edgeMargin, $tip.position().left - overflow ) );
		}

		anchorCenter = ( $anchor.offset().left + ( $anchor.outerWidth() / 2 ) ) - $tip.offset().left;
		$tip.find( ".arrow" ).css( "left", anchorCenter );
	};

	var signpostTitle = function() {
		return $( "<span>" ).text( $anchor.attr( "data-signpost-title" ) ).prepend( '<i class="fa fa-fw fa-flask"></i>' );
	};

	var showSignpost = function() {
		if ( window.sessionStorage && window.sessionStorage.getItem( storageKey ) ) {
			return;
		}

		$anchor.popover( {
			  html      : true
			, trigger   : "manual"
			, placement : "bottom"
			, container : "body"
			, template  : '<div class="popover labs-signpost-popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
			, title     : signpostTitle
			, content   : function() {
				return $( "#labs-signpost-content" ).html();
			}
		} );

		$anchor.on( "shown.bs.popover", keepSignpostInView );
		$anchor.popover( "show" );

		if ( window.sessionStorage ) {
			window.sessionStorage.setItem( storageKey, "1" );
		}
	};

	var hideSignpost = function() {
		if ( $anchor.data( "bs.popover" ) ) {
			$anchor.popover( "hide" );
		}
	};

	if ( !$anchor.length ) {
		return;
	}

	if ( !( window.sessionStorage && window.sessionStorage.getItem( storageKey ) ) ) {
		window.setTimeout( showSignpost, 2000 );
	}

	$anchor.on( "click", ".dropdown-toggle", hideSignpost );

	$( document ).on( "click", function( event ) {
		if ( $( event.target ).closest( ".labs-signpost-anchor, .labs-signpost-popover" ).length ) {
			return;
		}

		hideSignpost();
	} );

	$( document ).on( "click", ".labs-signpost-dismiss", function( event ) {
		event.preventDefault();

		$.post( $anchor.attr( "data-dismiss-url" ), {
			csrfToken : $anchor.attr( "data-csrf-token" )
		} );

		if ( window.sessionStorage ) {
			window.sessionStorage.setItem( storageKey, "1" );
		}

		hideSignpost();
	} );

} )( presideJQuery );

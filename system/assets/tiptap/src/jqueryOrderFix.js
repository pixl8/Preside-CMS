/**
 * Workaround for a broken jQuery build shipped by some Preside versions
 * ("2.2.5-jqnext"): `$.fn.after()` and `$.fn.prepend()` insert multi-node HTML
 * strings in REVERSE order (a fixed-reference `insertBefore( node, ref )` loop
 * instead of a document fragment - each subsequent node lands closest to the
 * anchor). `before()` and `append()` are unaffected (their fixed refs happen
 * to be order-preserving).
 *
 * Why we care: core frontendEditors.js re-renders an edited region with
 * `$( startComment ).after( data.rendered )` after EVERY save - on an affected
 * build the whole region comes back in reverse block order (in Classic and
 * Modern alike; the editor itself looked fine because it renders from the
 * textarea, so the page only revealed the scrambling once editing closed).
 *
 * The fix is deliberately surgical and FEATURE-DETECTED per method, so a
 * healthy build is left completely untouched:
 *   - probe the actual behaviour with a 2-node insert at patch time;
 *   - when broken, wrap the method and PRE-REVERSE string content that parses
 *     to 2+ top-level nodes, then delegate to the ORIGINAL - its reversing
 *     loop re-reverses into the correct order, and jQuery's own internal
 *     machinery (script evaluation, multi-target cloning) still runs. Node /
 *     jQuery-object / function content is passed through untouched.
 *
 * This heals core's Classic save path too, not just Modern. The real fix
 * belongs upstream in the jQuery build - this shim self-disables the moment
 * that happens (probe comes back healthy).
 */

function parseToNodes( $, content ) {
	try { return $.parseHTML( String( content ), document, true ) || []; }
	catch ( e ) { return []; }
}

// Reversed insertion is only observable with 2+ nodes.
function probeBroken( $, method ) {
	try {
		var host = document.createElement( "div" );
		if ( method === "after" ) {
			var anchor = document.createComment( "probe" );
			host.appendChild( anchor );
			$( anchor ).after( "<i>1</i><i>2</i>" );
		} else {
			$( host )[ method ]( "<i>1</i><i>2</i>" );
		}
		return host.textContent === "21";
	} catch ( e ) { return false; }
}

function wrap( $, method ) {
	var orig = $.fn[ method ];
	$.fn[ method ] = function() {
		var args = Array.prototype.slice.call( arguments );
		for ( var i = 0; i < args.length; i++ ) {
			if ( typeof args[ i ] === "string" ) {
				var nodes = parseToNodes( $, args[ i ] );
				if ( nodes.length > 1 ) { args[ i ] = nodes.reverse(); }
			}
		}
		return orig.apply( this, args );
	};
}

export function fixJqueryInsertOrder() {
	var $ = window.presideJQuery || window.jQuery;
	if ( !$ || !$.fn || $.fn.__ttOrderFixed ) { return; }
	$.fn.__ttOrderFixed = true;

	[ "after", "prepend" ].forEach( function( method ) {
		if ( typeof $.fn[ method ] === "function" && probeBroken( $, method ) ) {
			wrap( $, method );
		}
	} );
}

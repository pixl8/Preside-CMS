/**
 * Frontend (in-page) editor fit.
 *
 * Core opens a frontend editor as `position:fixed; top:100px; z-index:100` with a
 * z-index:99 sheen (system/assets/css/admin/frontend/frontendEditor.less), numbers
 * that predate sticky site headers. A theme header above that band paints over the
 * editor, and because it is anchored to the top of the viewport it lands exactly on
 * the editor's toolbar - the toolbar is simply not there any more.
 *
 * Two remedies, in order:
 *
 * 1. WIN THE STACK. The site's own fixed/sticky chrome is measured and `--tt-z-base`
 *    is raised above the highest of it, which lifts every z-index we own in one move
 *    (tiptap.css expresses them all against that var - sheen, editor, maximized,
 *    picker and anchor overlays keep their relative order). Painting over the header
 *    is the right answer, not a compromise: the editor is modal, the sheen already
 *    dims the page behind it, and nothing is given up to make room.
 * 2. PUSH DOWN whatever still covers the editor's top edge - an element with a z we
 *    refused to out-bid, or one that only appears later. Tested with
 *    `document.elementsFromPoint()` at the editor's own top edge rather than more
 *    z-index arithmetic: it answers the question that actually matters ("is
 *    something drawn on top of us HERE?") in real paint order, so nested stacking
 *    contexts, opacity and transform layers all resolve correctly and for free.
 *
 * Both are frontend-only. In the admin nothing is measured and no var is set, so
 * the ladder keeps its literal default values.
 *
 * The push is published as `--tt-frontend-offset` on the container so the editable's
 * max-height (tiptap.css) gives back exactly the space the push consumed - core's
 * save bar is fixed to the bottom and must not end up underneath the editor.
 */

// Core's own geometry - mirrored, not read: the container is display:none until
// `edit-active`, and we reset `top` before measuring, so there is nothing to read.
var BASE_TOP  = 100;
var GAP       = 8;   // breathing room between the header and the toolbar
var MAX_RATIO = 0.5; // never give more than half the viewport away to chrome
var PASSES    = 3;   // one push can reveal a second, shorter, header behind it

// The ladder's floor (matches the `--tt-z-base` fallback in tiptap.css) and its
// ceiling: the top rung is base+1060, so stop well short of the 2147483647 limit -
// a browser that clamps a rung would silently collapse the ordering between them.
var Z_FLOOR   = 1040;
var Z_CEILING = 2000000000;

var OURS = ".content-editor,.content-editor-editor-container,.frontend-editor-modal-sheen"
         + ",.tiptap-editor-container,.preside-picker-overlay,.preside-anchor-overlay,.tiptap-slash-menu"
         + ",.tiptap-selection-bubble";

/**
 * The highest z-index among the page's own fixed/sticky chrome - the things that
 * can cover a fixed editor. Ours are skipped, or we would ratchet against
 * ourselves every time an editor opens.
 *
 * A full getComputedStyle sweep is affordable here because it runs once per editor
 * open, not per frame, and only on the front end.
 */
function siteChromeZ() {
	var max  = 0;
	var all  = document.body ? document.body.querySelectorAll( "*" ) : [];
	for ( var i = 0; i < all.length; i++ ) {
		var el = all[ i ];
		// Note `.content-editor-editor-container` and the sheen are listed in their
		// own right: frontendEditors.js re-parents both to <body>, so neither is
		// inside `.content-editor` by the time an editor is built.
		if ( el.closest( OURS ) ) { continue; }

		var cs = window.getComputedStyle( el );
		if ( cs.position !== "fixed" && cs.position !== "sticky" ) { continue; }

		var z = parseInt( cs.zIndex, 10 );
		if ( z > max && z < Z_CEILING ) { max = z; }
	}
	return max;
}

/**
 * How far down the viewport the editor's top edge is covered, or 0 if it is clear.
 * Probed at three x positions because a header is often only partially wide (a
 * logo bar, a floating "back to top", a cookie banner pinned to one side).
 */
function coveredTo( host ) {
	var rect = host.getBoundingClientRect();
	if ( rect.top < 0 || rect.top > window.innerHeight || rect.width < 1 ) { return 0; }

	var y  = rect.top + 2;
	var xs = [ rect.left + 4, rect.left + rect.width / 2, rect.right - 4 ];
	var bottom = 0;

	for ( var i = 0; i < xs.length; i++ ) {
		var x = xs[ i ];
		if ( x < 0 || x > window.innerWidth ) { continue; }

		var stack = document.elementsFromPoint( x, y ) || [];
		for ( var j = 0; j < stack.length; j++ ) {
			var node = stack[ j ];
			// Everything before us in the stack is painted on top. Our own subtree
			// ends the walk; ancestors (html/body/the sheen's parent) are not
			// "covering" us in any meaningful sense, so they are skipped.
			if ( node === host || host.contains( node ) ) { break; }
			if ( node.contains( host ) ) { continue; }

			var r = node.getBoundingClientRect();
			if ( r.bottom > bottom ) { bottom = r.bottom; }
		}
	}
	return bottom;
}

/**
 * Step 1 on its own - lift the whole `--tt-z-base` ladder above the site's own
 * fixed chrome. Exported for Modern inline mode, whose editor is in normal page
 * flow (nothing to push down) but whose body-portalled chrome - selection
 * bubble, slash menu, picker overlays - still needs to out-bid a sticky site
 * header. Measured once per call: the page's chrome does not change while
 * editing is active, and the sweep is the expensive half of this module.
 * Returns a teardown; last-writer-wins is fine because modal and inline are
 * never active at once and each enter recomputes.
 */
export function liftChromeZ() {
	var root = document.documentElement;
	var base = Math.max( Z_FLOOR, Math.min( siteChromeZ() + 1, Z_CEILING ) );
	root.style.setProperty( "--tt-z-base", String( base ) );
	return function() {
		root.style.removeProperty( "--tt-z-base" );
	};
}

/**
 * Called with OUR container; no-ops (returning null) unless it is inside a core
 * frontend editor wrapper, so admin-side editors pay nothing for this.
 * Returns a teardown to run on destroy - frontend editors are created and
 * destroyed on every edit-mode toggle.
 */
export function fitFrontendEditor( container ) {
	var host = container.closest && container.closest( ".content-editor-editor-container" );
	if ( !host ) { return null; }

	// Step 1 - lift the whole ladder above the site's own fixed chrome.
	var dropZ = liftChromeZ();

	function apply() {
		// A fixed element has no offsetParent even when visible, so "is it laid out"
		// is the client-rect test, not offsetParent.
		if ( !host.isConnected || !host.getClientRects().length ) { return; }

		// Reset first: the covering element may have gone away (a header that
		// un-sticks, a dismissed banner), and the offset must shrink again.
		host.style.top = BASE_TOP + "px";

		// Step 2 - anything still on top of us pushes the editor below it.
		var top = BASE_TOP;
		var max = Math.round( window.innerHeight * MAX_RATIO );
		for ( var pass = 0; pass < PASSES; pass++ ) {
			var bottom = coveredTo( host );
			if ( !bottom || bottom + GAP <= top ) { break; }
			top = Math.min( Math.round( bottom + GAP ), max );
			host.style.top = top + "px";
			if ( top === max ) { break; }
		}

		host.style.setProperty( "--tt-frontend-offset", ( top - BASE_TOP ) + "px" );
	}

	var frame = null;
	function schedule() {
		if ( frame ) { return; }
		frame = window.requestAnimationFrame( function() { frame = null; apply(); } );
	}

	apply();
	// Core scrolls the page to the edited region right after instanceReady, and a
	// header that only sticks once scrolled appears at that point - so measure
	// again after the layout has settled.
	schedule();
	window.addEventListener( "resize", schedule );
	window.addEventListener( "scroll", schedule, true );

	return function() {
		window.removeEventListener( "resize", schedule );
		window.removeEventListener( "scroll", schedule, true );
		if ( frame ) { window.cancelAnimationFrame( frame ); }
		host.style.top = "";
		host.style.removeProperty( "--tt-frontend-offset" );
		dropZ();
	};
}

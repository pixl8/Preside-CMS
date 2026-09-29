/**
 * The editing IFRAME — the isolation boundary.
 *
 * WHY AN IFRAME, AND WHY NOT CSS OR SHADOW DOM.
 *
 * CKEditor 4 edited inside an iframe, and that is what gave it three separate
 * things at once. We tried to reproduce them with CSS (an `all:revert` wall, a
 * `body`->editable selector mapping and rem->px rebasing) and each one is a
 * losing position:
 *
 *   1. ISOLATION. A CSS reset is a specificity contest: at (0,2,0) it is beaten
 *      by any admin/theme rule at (0,2,1) or above, and by ANY `!important` -
 *      both of which real admin stylesheets contain. There is no ordering that
 *      wins that argument. A shadow root would have fixed this much (outer rules
 *      cannot match inside one), but not 2 or 3.
 *   2. `rem`. Always resolves against the DOCUMENT ROOT - spec, no exceptions,
 *      and a shadow root is not a new root. The admin is `html{font-size:10px}`
 *      (Ace/bootstrap), so every rem in a site's content CSS came out at 62.5%
 *      of its intended size. An iframe HAS its own root element, so rem is
 *      simply correct.
 *   3. `vw` / `vh` / MEDIA QUERIES. Resolve against the viewport, which for an
 *      iframe is the iframe's own box - roughly the width the content will be
 *      rendered at. In the page they resolved against the whole admin viewport,
 *      so a `clamp(1.125rem, 0.9375rem + 0.5vw, 1.375rem)` font-size (a real
 *      site's base size) was computed for a 1600px viewport inside a 800px
 *      editor.
 *
 * So the editable moves back into an iframe and the three CSS transforms are
 * DELETED. Content stylesheets are injected UNMODIFIED - no scoping, no
 * rebasing - which is both the fidelity fix and a large reduction in moving
 * parts. An unstyled field is therefore exactly browser defaults, as CKEditor's
 * was.
 *
 * WHAT LIVES WHERE. The iframe holds the editable and the chrome that is glued
 * to the content (embeds/image tools, the drag gutter, the table bubble) - those
 * measure in iframe coordinates and need no translation, and their drag/drop and
 * clipping behave against the visible editor box, which is what you want. The
 * PARENT holds the toolbar, footer, outline rail, pickers and the slash menu;
 * anything there that measures content geometry translates through pageRect().
 *
 * MODERN INLINE MODE GETS NO IFRAME. There the editable IS the site page: it
 * must inherit the theme, and `rem`/`vw` already resolve against the site's own
 * root and viewport. It is correct by construction, so createFrame() is simply
 * not called for it.
 *
 * SYNCHRONOUS BY CONTRACT. Core's frontendEditors.js reads `.editor` straight
 * off the constructor, so the frame is appended, its document written and the
 * editor built in ONE stack. open()/write()/close() into a freshly appended
 * about:blank is synchronous, and the document is not replaced afterwards
 * (verified in chromium, webkit and firefox).
 */

// Our own stylesheet goes INTO the frame - the editable's functional CSS, the
// embed/node-view chrome and the `--tt-*` variables all have to be in there.
// Shared with the dialog shell's shadow root (src/ownStyle.js), which needs the
// same trick for the same reason: a stylesheet in the page cannot reach either.
import { injectOwnStyle } from "./ownStyle.js";

/**
 * Create the editing frame inside `container`.
 *
 * Returns { frame, mount, doc, win, setHeights, syncTheme, refit, destroy },
 * where `mount` is the element to hand to `new Editor({ element })`.
 */
export function createFrame( container, opts ) {
	opts = opts || {};

	const frame = document.createElement( "iframe" );
	frame.className = "tiptap-editor-frame";
	frame.setAttribute( "title", opts.title || "" );
	// No src: a freshly appended frame is about:blank, same-origin, and writable
	// synchronously. `frameborder` is dead but harmless; the CSS owns the border.
	frame.setAttribute( "frameborder", "0" );
	container.appendChild( frame );

	const doc = frame.contentDocument;
	if ( !doc ) { throw new Error( "tiptap: iframe document unavailable" ); }

	doc.open();
	doc.write(
		  '<!doctype html><html class="tiptap-editor-doc"><head><meta charset="utf-8">'
		// The frame's own reset. Deliberately tiny: this is the ONLY author CSS in
		// here besides our editor sheet and the site's content CSS, so there is
		// nothing to wall out. body margin goes because the mount owns the padding.
		+ '<style>html,body{margin:0;padding:0;background:transparent}'
		// `position:relative` on body makes it the containing block for the block
		// drag rail (dragHandle.js appends it here so a drag begins and ends in ONE
		// document). Without it the rail resolves against the frame's viewport and
		// sticks in place while the content scrolls under it.
		+ 'body{position:relative}'
		+ 'html{overflow-x:hidden}</style>'
		+ '</head><body></body></html>'
	);
	doc.close();

	// Our editor CSS, synchronously (see src/ownStyle.js for why it is cssText and
	// not a <link>).
	injectOwnStyle( doc.head, doc );

	const mount = doc.createElement( "div" );
	mount.className = "tiptap-editor-mount";
	doc.body.appendChild( mount );

	// ---- Height ------------------------------------------------------------
	// The frame is a replaced element: it does not grow with its content, so the
	// height is measured and applied. minHeight/maxHeight keep their meaning from
	// the field config - below the max the frame grows with the content, at the
	// max it stops and the frame's own document scrolls (which is exactly what
	// CKEditor did).
	let minH = 0, maxH = 0, fitted = 0;

	function contentHeight() {
		// scrollHeight of the frame's root, not the mount: the mount's margins and
		// the last block's collapsed margin both belong in the total.
		const de = doc.documentElement;
		return Math.max( de ? de.scrollHeight : 0, mount.scrollHeight || 0 );
	}

	// Re-entrancy guard. Setting the frame's height relayouts its document, which
	// changes scrollHeight, which fires the ResizeObserver again - WebKit reports
	// that as "ResizeObserver loop completed with undelivered notifications".
	// Sub-pixel churn is also ignored (the 1px band below) so a fractional content
	// height cannot oscillate.
	let fitting = false;

	function refit() {
		// Maximized: the flex layout owns the HEIGHT (maximize.js), but the frame is
		// then a fixed tall box whose content can overflow it, so whether it scrolls
		// still has to be kept in step.
		if ( frame.__ttFlex ) { syncOverflow(); return; }
		if ( fitting ) { return; }
		let h = contentHeight();
		if ( minH > 0 && h < minH ) { h = minH; }
		if ( maxH > 0 && h > maxH ) { h = maxH; }
		if ( minH <= 0 && h < 60 )  { h = 60; }
		h = Math.ceil( h );
		if ( Math.abs( h - fitted ) >= 1 ) {
			fitting = true;
			fitted = h;
			frame.style.height = h + "px";
			fitting = false;
		}
		syncOverflow();
	}

	// Whether the frame's document scrolls is derived from what the frame ACTUALLY
	// ended up being, not from the configured maxHeight - because a CSS cap can
	// clamp it too. The front end does exactly that: `.content-editor-editor-container
	// .tiptap-editor-frame` gets a viewport-relative max-height so core's fixed save
	// bar stays clear, and a frame capped that way with overflow hidden would clip
	// its content with no way to reach it.
	//
	// Scrolling is otherwise switched OFF, and that matters: on an auto-growing
	// frame the scrollbar is pointless AND a feedback loop - appearing changes the
	// content width, which rewraps the text, which changes the height, which toggles
	// the scrollbar again.
	function syncOverflow() {
		const de = doc.documentElement;
		if ( !de ) { return; }
		const needed = ( frame.clientHeight || 0 ) + 1 < contentHeight();
		const want   = needed ? "auto" : "hidden";
		if ( de.style.overflowY !== want ) { de.style.overflowY = want; }
	}

	function setHeights( min, max ) {
		minH = min > 0 ? min : 0;
		maxH = max > 0 ? max : 0;
		refit();
	}

	// maximize.js takes the height over while the container is a flex column, and
	// needs to hand it back on exit - it only has the element, so the fitter is
	// published on it (paired with the __ttFlex flag refit() checks).
	frame.__ttRefit = refit;

	// Content edits, image loads and late stylesheets all change the height.
	// ResizeObserver on the frame's body catches every one of them without a
	// polling loop; the editor also calls refit() on update.
	// Observe the BODY only, never documentElement. The root's box IS the height we
	// set, so observing it feeds our own write straight back in as a change - the
	// loop WebKit reports as "ResizeObserver loop completed with undelivered
	// notifications". The body's height is content-driven, which is the signal we
	// actually want.
	let ro = null;
	if ( window.ResizeObserver ) {
		ro = new window.ResizeObserver( refit );
		ro.observe( doc.body );
	}

	// ---- Theme -------------------------------------------------------------
	// The `--tt-*` variables and the dark overrides are keyed off classes that
	// live on the container, which is in the OTHER document - so the frame's root
	// carries its own copy of the dark flag.
	function syncTheme() {
		const dark = container.classList.contains( "tiptap-dark" );
		doc.documentElement.classList.toggle( "tiptap-dark", dark );
	}
	syncTheme();

	function destroy() {
		if ( ro ) { try { ro.disconnect(); } catch ( e ) {} ro = null; }
		if ( frame.parentNode ) { frame.parentNode.removeChild( frame ); }
	}

	return {
		  frame      : frame
		, mount      : mount
		, doc        : doc
		, win        : frame.contentWindow
		, setHeights : setHeights
		, refit      : refit
		, syncTheme  : syncTheme
		, destroy    : destroy
	};
}

/**
 * Translate a rect measured INSIDE the frame into host-page coordinates.
 *
 * Everything the parent draws over the content (the outline rail's heading
 * positions, the slash menu's caret anchor) measures in the frame's coordinate
 * space, where 0,0 is the top-left of the frame's own viewport. Adding the
 * frame's own box in the host page converts it. Frame content coordinates are
 * already scroll-relative, so the frame's scroll offset must NOT be added.
 */
export function pageRect( frame, rect ) {
	if ( !frame || !rect ) { return rect; }
	const f = frame.getBoundingClientRect();
	return {
		  top    : rect.top + f.top
		, bottom : rect.bottom + f.top
		, left   : rect.left + f.left
		, right  : rect.right + f.left
		, width  : rect.width
		, height : rect.height
	};
}

/**
 * One shape for "the editing surface", so the chrome that lives in the HOST
 * document (outline rail, table bubble, slash menu) works the same whether the
 * editable is in a frame or - in Modern inline mode - in the page.
 *
 * `el` is what the facade passes as the old `mount` argument: the FRAME for a
 * boxed editor, the mount div inline.
 *
 *   box()        the visible editor box in HOST coordinates. For a frame that is
 *                the frame's own rect, which is exactly right: the frame IS the
 *                viewport its content is clipped to. Inline it is the mount.
 *   toHost(rect) content geometry -> host coordinates.
 *   onScroll(fn) whatever actually scrolls the content. A frame scrolls its own
 *                document, so the listener belongs on its window, not on the
 *                element - `iframe.addEventListener("scroll")` never fires.
 *   scrollBy / canScroll  used by click-to-scroll and drag auto-scroll.
 */
export function surfaceOf( el ) {
	const isFrame = !!( el && el.tagName === "IFRAME" );
	const win     = isFrame ? el.contentWindow : null;
	const doc     = isFrame ? el.contentDocument : null;

	return {
		  frame    : isFrame ? el : null
		, isFrame  : isFrame
		, doc      : doc || document
		, win      : win || window
		, box      : function() { return el ? el.getBoundingClientRect() : null; }
		, toHost   : function( rect ) { return isFrame ? pageRect( el, rect ) : rect; }
		, viewportHeight : function() { return isFrame ? win.innerHeight : ( window.innerHeight || 0 ); }
		, canScroll: function() {
			if ( isFrame ) {
				const de = doc.documentElement;
				return !!de && ( de.scrollHeight - de.clientHeight > 4 );
			}
			return !!el && ( el.scrollHeight - el.clientHeight > 4 );
		}
		, scrollTop: function() {
			if ( isFrame ) { return ( doc.documentElement && doc.documentElement.scrollTop ) || doc.body.scrollTop || 0; }
			return el ? el.scrollTop : 0;
		}
		, scrollTo : function( top, smooth ) {
			if ( isFrame ) {
				if ( typeof win.scrollTo === "function" ) {
					try { win.scrollTo( { top: top, behavior: smooth ? "smooth" : "auto" } ); return; }
					catch ( e ) { win.scrollTo( 0, top ); return; }
				}
				doc.documentElement.scrollTop = top;
				return;
			}
			if ( typeof el.scrollTo === "function" ) { el.scrollTo( { top: top, behavior: smooth ? "smooth" : "auto" } ); }
			else { el.scrollTop = top; }
		}
		, onScroll : function( fn ) {
			const target = isFrame ? win : el;
			target.addEventListener( "scroll", fn, { passive: true } );
			return function() { target.removeEventListener( "scroll", fn ); };
		}
	};
}

/**
 * The `.tiptap-editor-container` an element belongs to, ACROSS the frame boundary.
 *
 * `el.closest()` stops at the root of `el`'s OWN document, so for anything inside
 * the editing frame - i.e. `editor.view.dom` for every boxed editor - it returns
 * null: the container is in the host page. Every caller that reaches for the
 * container from the editable must go through here.
 *
 * This is not theoretical: it is what silently broke the toolbar's Maximize button
 * (it toggled a null container, so nothing happened) and the slash menu's
 * light/dark sync when the editable moved into the frame.
 */
export function containerOf( el ) {
	if ( !el ) { return null; }
	if ( el.closest ) {
		const own = el.closest( ".tiptap-editor-container" );
		if ( own ) { return own; }
	}
	const frame = frameOf( el );
	return ( frame && frame.closest && frame.closest( ".tiptap-editor-container" ) ) || null;
}

/** The frame an element lives in, or null when it is in the host document. */
export function frameOf( el ) {
	try {
		const win = el && el.ownerDocument && el.ownerDocument.defaultView;
		return ( win && win !== window && win.frameElement ) || null;
	} catch ( e ) { return null; }
}

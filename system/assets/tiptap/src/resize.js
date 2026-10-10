/**
 * Manual resize grip — CKEditor's `resize` plugin.
 *
 * The grip sits in the bottom-right corner of the bottom bar (our footer status
 * bar) and drags the editor to a size the author chooses. Faithful to the plugin
 * (it is inlined in ckeditor.js; the skin draws `.cke_resizer` as a 10px CSS
 * triangle, `cursor:se-resize`, floated right with a -4px margin):
 *
 *  - **`resize_dir` defaults to `"vertical"`**, so out of the box this drags HEIGHT
 *    only, and the cursor says so (`ns-resize`). `"horizontal"` / `"both"` are
 *    honoured, with `ew-resize` / `se-resize` accordingly.
 *  - An axis is only draggable when its min and max differ - CKEditor's own test -
 *    so `resize_minHeight === resize_maxHeight` disables vertical dragging, and a
 *    field with neither axis left gets NO grip at all.
 *  - CKEditor's defaults: min 750x250, max 3000x3000, `resize_enabled` true.
 *  - **The minimum is lowered to the current size on mousedown if the editor is
 *    already smaller than it.** That is CKEditor's own line
 *    (`resize_minWidth > c.width && ( resize_minWidth = c.width )`) and it matters
 *    much more here than there: Preside's default `maxHeight` is 300, so a stock
 *    field is well under the 250 minimum once the chrome is subtracted, and without
 *    this the first pixel of drag would JUMP the editor taller.
 *  - Clamping is against the WHOLE editor box, as CKEditor's is (`getResizable()`
 *    returns the outer container), not against the editable alone.
 *  - Hidden while maximized (CKEditor hides it on the `maximize` event; ours is a
 *    CSS rule on `.is-maximized`, since maximize is a class on the container).
 *  - Nothing is persisted: it is a per-session size, exactly as CKEditor's was.
 *
 * WHAT IT ACTUALLY DOES TO US: a dragged height is applied as
 * `frameApi.setHeights( h, h )` - min and max pinned to the same value. That is
 * the whole implementation, because everything else already follows from it: the
 * frame stops auto-growing (which is what "I chose this height" means, and what
 * CKEditor's explicit height did), and `syncOverflow()` derives on its own that
 * taller content must now scroll inside the frame. No second height path.
 *
 * Modern inline mode gets no grip: there the editable IS the page, in the site's
 * own flow, with no box to resize (CKEditor's inline mode had no bottom bar and no
 * resizer either).
 */
import { t } from "./i18n.js";

// CKEditor's own defaults (CKEDITOR.config.resize_*).
const DEF_DIR        = "vertical";
const DEF_MIN_WIDTH  = 750;
const DEF_MAX_WIDTH  = 3000;
const DEF_MIN_HEIGHT = 250;
const DEF_MAX_HEIGHT = 3000;

function num( v, fallback ) {
	const n = parseInt( v, 10 );
	return isNaN( n ) ? fallback : n;
}

export function resizeEnabled( cfg ) {
	const dc = ( cfg && cfg.defaultConfigs ) || {};
	return dc.resize_enabled !== false && dc.resize_enabled !== "false";
}

/**
 * Build the grip for a boxed editor. Returns the element to append (the facade puts
 * it in the footer, or on the container itself when a field has no footer), or null
 * when the config leaves no axis to drag.
 */
export function createResizer( container, frameApi, cfg ) {
	const dc  = ( cfg && cfg.defaultConfigs ) || {};
	const dir = String( dc.resize_dir || DEF_DIR ).toLowerCase();

	let minW = num( dc.resize_minWidth , DEF_MIN_WIDTH  );
	let maxW = num( dc.resize_maxWidth , DEF_MAX_WIDTH  );
	let minH = num( dc.resize_minHeight, DEF_MIN_HEIGHT );
	let maxH = num( dc.resize_maxHeight, DEF_MAX_HEIGHT );

	// CKEditor's own gating: an axis needs to be in `resize_dir` AND have room to
	// move between its own min and max.
	const horizontal = ( dir === "both" || dir === "horizontal" ) && minW !== maxW;
	const vertical   = ( dir === "both" || dir === "vertical"   ) && minH !== maxH;
	if ( !horizontal && !vertical ) { return null; }

	const el = document.createElement( "span" );
	el.className = "tiptap-resizer"
		+ ( horizontal && vertical ? " is-both" : horizontal ? " is-horizontal" : " is-vertical" );
	el.setAttribute( "role", "separator" );
	el.setAttribute( "aria-orientation", vertical ? "horizontal" : "vertical" );
	el.setAttribute( "tabindex", "0" );
	el.title = t( "resize.tooltip" );
	el.setAttribute( "aria-label", t( "resize.tooltip" ) );

	let startX = 0, startY = 0, startTotal = 0, startFrame = 0, startWidth = 0, dragging = false;

	function frameHeight() {
		return frameApi && frameApi.frame ? frameApi.frame.offsetHeight : 0;
	}

	function apply( width, totalHeight ) {
		if ( horizontal ) { container.style.width = Math.round( width ) + "px"; }
		if ( vertical ) {
			// The chrome (toolbar + footer + borders) is whatever the container has
			// beyond the frame, so the TOTAL lands where the pointer is - which is what
			// makes the grip feel attached to the corner it is dragging.
			const chrome = Math.max( 0, startTotal - startFrame );
			const h      = Math.max( 20, Math.round( totalHeight - chrome ) );
			frameApi.setHeights( h, h );   // pin: min === max, so it stops auto-growing
		}
	}

	function onDown( e ) {
		if ( !e.isPrimary || ( e.pointerType === "mouse" && e.button !== 0 ) ) { return; }
		e.preventDefault();
		e.stopPropagation();

		startX     = e.clientX;
		startY     = e.clientY;
		startWidth = container.offsetWidth || 0;
		startTotal = container.offsetHeight || 0;
		startFrame = frameHeight();

		// CKEditor lowers its own minimum rather than snapping a small editor up to it.
		if ( minW > startWidth ) { minW = startWidth; }
		if ( minH > startTotal ) { minH = startTotal; }

		dragging = true;
		try { el.setPointerCapture( e.pointerId ); } catch ( err ) {}
	}

	function onMove( e ) {
		if ( !dragging ) { return; }
		const w = Math.max( minW, Math.min( startWidth + ( e.clientX - startX ), maxW ) );
		const h = Math.max( minH, Math.min( startTotal + ( e.clientY - startY ), maxH ) );
		apply( w, h );
	}

	function onUp( e ) {
		if ( !dragging ) { return; }
		dragging = false;
		try { if ( el.hasPointerCapture( e.pointerId ) ) { el.releasePointerCapture( e.pointerId ); } } catch ( err ) {}
	}

	// Keyboard resizing: the grip is focusable, so arrows move it in 20px steps.
	// CKEditor's was mouse-only; a control that can be tabbed to should do something.
	function onKey( e ) {
		const step = 20;
		let dw = 0, dh = 0;
		if ( e.key === "ArrowUp"    ) { dh = -step; }
		else if ( e.key === "ArrowDown"  ) { dh = step; }
		else if ( e.key === "ArrowLeft"  ) { dw = -step; }
		else if ( e.key === "ArrowRight" ) { dw = step; }
		else { return; }
		e.preventDefault();

		startWidth = container.offsetWidth || 0;
		startTotal = container.offsetHeight || 0;
		startFrame = frameHeight();
		if ( minW > startWidth ) { minW = startWidth; }
		if ( minH > startTotal ) { minH = startTotal; }

		apply(
			  Math.max( minW, Math.min( startWidth + dw, maxW ) )
			, Math.max( minH, Math.min( startTotal + dh, maxH ) )
		);
	}

	el.addEventListener( "pointerdown", onDown );
	el.addEventListener( "pointermove", onMove );
	el.addEventListener( "pointerup", onUp );
	el.addEventListener( "pointercancel", onUp );
	el.addEventListener( "keydown", onKey );

	return el;
}

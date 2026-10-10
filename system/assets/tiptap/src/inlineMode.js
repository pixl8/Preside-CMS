/**
 * Modern inline editing mode (frontend only).
 *
 * Core's frontend editing opens a region's editor in a fixed, modal-style
 * container (frontendEditors.js). Modern mode instead makes the page's single
 * rich-editor region IMMEDIATELY editable in place: the rendered content is
 * swapped for a chrome-less inline Tiptap editor sitting exactly where the
 * content was, gutentap-style. No persistent toolbar - the selection bubble
 * (src/selectionBubble.js) plus the existing slash menu / drag handle / image /
 * table bubbles are the whole UI.
 *
 * THE LOAD-BEARING DESIGN: we reuse core's own flow end-to-end, so the save /
 * draft / publish / version-history behaviour cannot drift from Classic:
 *
 *   1. enter() marks the region's textarea `data-tiptap-inline=<containerId>`
 *      and triggers core's own overlay click -> core's toggleEditMode(true) ->
 *      setupCkEditor() -> `new PresideRichEditor( textarea )` (our facade).
 *   2. The facade sees the marker at construction time (facade.js) and calls
 *      resolveInlineMount() here: the rendered nodes between the region's
 *      comment delimiters (`<!-- container: _x -->...<!-- !container: _x -->`)
 *      are DETACHED into storage and the `.tiptap-editor-container.tiptap-inline`
 *      is inserted in their place. Detached rather than display:none so core's
 *      1s geometry interval measures the live editor, and so bare text nodes
 *      are handled.
 *   3. Save / Publish / Cancel / Esc / ctrl+Enter stay core's untouched
 *      closures, wired to the (CSS-hidden-except-buttons) modal container.
 *   4. SAVE-vs-CANCEL DISCRIMINATOR: instance._cleanups run at the TOP of
 *      destroy(). On the cancel path our inline container is still connected
 *      between the comments -> remove it and re-insert the stored originals
 *      (byte-identical page restore; core never re-rendered). On the save path
 *      core's setContent( data.rendered ) already replaced everything between
 *      the comments - our container is detached -> the fresh render is in
 *      place, keep it.
 *
 * Mode policy (editModeSwitch.js drives it via the onExit callback):
 * cancel/Esc AND save/publish all land on Off - for a save, the page
 * re-rendering with the saved content is the visible "it saved" confirmation.
 *
 * This module never imports the facade (no cycle): the facade imports
 * resolveInlineMount and everything else happens through core's DOM events.
 */
import { liftChromeZ } from "./frontendFit.js";

var BODY_CLASS = "frontend-editing-modern";

var state = null; // the single active inline session (Modern is one region by definition)

function jq() { return window.presideJQuery || window.jQuery; }

/**
 * Modern is offered only when the page has EXACTLY one rich-editor region.
 * Core appends the decoded `.content-editor` divs to <body> at script-execute
 * time, so by DOMContentLoaded this is reliable.
 */
export function pageQualifies() {
	return document.querySelectorAll( ".content-editor.richeditor" ).length === 1;
}

export function isActive() { return !!state; }

/**
 * Unsaved edits? Compared against the facade instance's own initialdata (set at
 * construction from the raw stored value, same normalisation as getData) - core's
 * isDirty() is hard-coded `true` and unusable for this.
 */
export function isDirty() {
	if ( !state ) { return false; }
	try {
		var inst = jq()( state.ta ).data( "ckeditorinstance" );
		return !!inst && inst.getData() !== inst.initialdata;
	} catch ( e ) { return false; }
}

/**
 * Save the draft through core's own button - the exact flow the author would
 * have clicked. The exit continues via the teardown's "save" path.
 *
 * `opts.after` rides on THIS session and is handed back to onExit( reason,
 * after ) - deliberately not module state in the caller: a deferred onExit
 * callback from a PREVIOUS session (they dispatch via setTimeout) must not be
 * able to consume or clobber it.
 */
export function saveDraft( opts ) {
	if ( !state ) { return false; }
	var btn = state.host.querySelector( ".editor-btn-save" );
	if ( !btn ) { return false; }
	state.afterSave = ( opts && opts.after ) || null;
	jq()( btn ).trigger( "click" );
	return true;
}

/**
 * Enter Modern mode. `opts.onExit( reason )` is called (async) after teardown
 * with "cancel" (user cancelled/Esc'd), "save" (core re-rendered the region)
 * or "switch" (a programmatic exit() - the caller already knows).
 * Returns false when the page does not qualify or core's editor could not be
 * built - callers fall back to Classic rendering.
 */
export function enter( opts ) {
	if ( state ) { return true; }
	if ( !pageQualifies() ) { return false; }

	var $        = jq();
	var editorEl = document.querySelector( ".content-editor.richeditor" );

	// The region's editor form was re-parented to <body> by core, so it is
	// found by content, not containment: Modern requires exactly one rich
	// region, so exactly one container holds a frontend richeditor textarea.
	var host = null;
	document.querySelectorAll( ".content-editor-editor-container" ).forEach( function( c ) {
		if ( !host && c.querySelector( "textarea.richeditor.frontend-container" ) ) { host = c; }
	} );
	var ta = host && host.querySelector( "textarea.richeditor.frontend-container" );
	if ( !editorEl || !ta ) { return false; }

	// Only one core editor can sensibly be open; close any Classic edit in
	// progress (its cancel path restores that region untouched).
	document.querySelectorAll( ".content-editor-editor-container.edit-active .editor-btn-cancel" ).forEach( function( btn ) {
		try { btn.click(); } catch ( e ) {}
	} );

	state = {
		  editorEl : editorEl
		, host     : host
		, ta       : ta
		, onExit   : ( opts && opts.onExit ) || null
		, originals: null
		, start    : null
		, container: null
		, exiting  : false
	};

	// Hide the overlays/labels/sheen and collapse the modal container to its
	// buttons bar (css, under this class) BEFORE core opens the editor, so
	// nothing flashes.
	document.body.classList.add( BODY_CLASS );

	// The facade reads this at construction time and mounts inline.
	ta.setAttribute( "data-tiptap-inline", editorEl.id );

	// The editor is in normal page flow (nothing to push down), but our
	// body-portalled chrome - selection bubble, slash menu, picker overlays -
	// still has to out-bid a sticky site header.
	state.dropZ = liftChromeZ();

	// Core's own flow: toggleEditMode(true) -> setupCkEditor() -> our facade.
	// jQuery trigger works on CSS-hidden elements.
	$( editorEl ).find( ".content-editor-overlay" ).first().trigger( "click" );

	// Construction is synchronous (the facade sets .editor before returning).
	// If the mount never happened - core JS absent, decode failure - revert
	// everything rather than leaving the page half-entered.
	if ( !state || !state.container ) {
		var s = state;
		state = null;
		if ( s ) {
			s.ta.removeAttribute( "data-tiptap-inline" );
			document.body.classList.remove( BODY_CLASS );
			if ( s.dropZ ) { s.dropZ(); }
		}
		return false;
	}

	// Core's instanceReady handler scrolls the region to ~20px from the viewport
	// top ($editor.offset().top - 20) - fine for the Classic modal (fixed at
	// top:100px), but inline that parks the first lines UNDER the fixed admin
	// toolbar. Our handler registers after core's, so it runs after the scroll
	// and gives the toolbar's height back. Registered on the facade instance
	// (set synchronously) and rAF-deferred so the browser has applied core's
	// scrollTop before we measure.
	var container = state.container;
	var inst      = jq()( ta ).data( "ckeditorinstance" );
	if ( inst && inst.on ) {
		inst.on( "instanceReady", function() {
			window.requestAnimationFrame( function() {
				if ( !container.isConnected ) { return; }
				var bar = document.querySelector( ".preside-admin-toolbar" );
				var barBottom = 0;
				try { barBottom = bar ? Math.max( 0, bar.getBoundingClientRect().bottom ) : 0; } catch ( e ) {}
				var top  = container.getBoundingClientRect().top;
				var want = barBottom + 16;
				if ( top < want ) { window.scrollBy( 0, top - want ); }
			} );
		} );
	}
	return true;
}

/**
 * Programmatic exit (mode switch to Off/Classic). Routed through core's own
 * cancel button so there is exactly ONE teardown path: core restores the raw
 * textarea value and destroys the editor; our cleanup (registered on
 * instance._cleanups) restores the original page content.
 */
export function exit() {
	if ( !state ) { return; }
	state.exiting = true;
	var btn = state.host.querySelector( ".editor-btn-cancel" );
	if ( btn ) { jq()( btn ).trigger( "click" ); }
	// If core's handler was somehow not wired the cleanup never ran - do not
	// leave the page stuck in a half-torn state.
	if ( state ) { teardown(); }
}

/**
 * Called by the facade during init() when the textarea carries the inline
 * marker. Detaches the rendered nodes between the region's comment delimiters
 * and hands back the insertion anchor + the cleanup for instance._cleanups.
 * Returns null when anything is off (facade then mounts normally - fail safe).
 */
export function resolveInlineMount( containerId, container ) {
	if ( !state || state.editorEl.id !== containerId || state.container ) { return null; }

	// Core remembers the region's original parent on the editor element
	// ($editor.data( "parent" )) - the same reference its own setContent uses.
	var parent = jq()( state.editorEl ).data( "parent" );
	parent = ( parent && parent.length !== undefined ) ? parent[ 0 ] : parent;
	if ( !parent ) { return null; }

	var start = null, end = null;
	var startText = "container: " + containerId;
	var endText   = "!container: " + containerId;
	for ( var n = parent.firstChild; n; n = n.nextSibling ) {
		if ( n.nodeType === 8 ) {
			var txt = String( n.nodeValue || "" ).trim();
			if ( txt === startText ) { start = n; }
			else if ( txt === endText ) { end = n; break; }
		}
	}
	if ( !start || !end ) { return null; }

	// Detach (not hide) everything between the comments - see the header note.
	var originals = [];
	var node = start.nextSibling;
	while ( node && node !== end ) {
		var next = node.nextSibling;
		originals.push( node );
		node.parentNode.removeChild( node );
		node = next;
	}

	state.originals = originals;
	state.start     = start;
	state.container = container;

	return { anchor: start, cleanup: teardown };
}

// Runs from instance._cleanups at the top of destroy() - or directly from
// exit()'s safety net. Idempotent: state is nulled first.
function teardown() {
	if ( !state ) { return; }
	var s = state;
	state = null;

	// The discriminator: still connected between the comments = nobody
	// re-rendered the region = cancel; detached = core's setContent already
	// replaced the region with the fresh render = save.
	var cancelled = !!( s.container && s.container.isConnected );

	if ( cancelled ) {
		if ( s.container.parentNode ) { s.container.parentNode.removeChild( s.container ); }
		var ref = s.start;
		if ( ref && ref.parentNode && s.originals ) {
			s.originals.forEach( function( node ) {
				ref.parentNode.insertBefore( node, ref.nextSibling );
				ref = node;
			} );
		}
	}
	s.originals = null;

	s.ta.removeAttribute( "data-tiptap-inline" );
	document.body.classList.remove( BODY_CLASS );
	if ( s.dropZ ) { s.dropZ(); }

	if ( s.onExit ) {
		var reason = s.exiting ? "switch" : ( cancelled ? "cancel" : "save" );
		// Async: destroy() is still unwinding (core's tearDownCkEditor is midway
		// through its own bookkeeping); re-entering or flipping the checkbox
		// synchronously from inside it would interleave two flows.
		setTimeout( function() { s.onExit( reason, s.afterSave || null ); }, 0 );
	}
}

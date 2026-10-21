/**
 * Maximize (full-viewport) toggle for an editor container.
 *
 * IT DOES NOT MOVE THE CONTAINER, AND MUST NOT. It used to portal it to <body>;
 * the editable now lives in an <iframe> (src/editorFrame.js), and RE-PARENTING AN
 * IFRAME RE-INITIALISES ITS DOCUMENT - chromium, webkit and firefox all replace
 * it with a fresh about:blank. Maximizing therefore wiped the editable out of the
 * DOM. It looked survivable from the outside (ProseMirror's state is JS-side, so
 * getData() and even insertContent() still worked against a detached view) which
 * is exactly what makes it worth this comment: the editor was blank on screen.
 *
 * So the container is made `position:fixed; inset:0` WHERE IT IS, and the
 * ancestor constraints that would otherwise defeat that are neutralised for the
 * duration and restored on exit (see hoistAncestors).
 *
 * `position:fixed` alone is not enough: on the FRONT END the editor is rendered
 * inside `.content-editor-editor-container` (see Preside's
 * views/admin/frontendEditing/_editorTemplate.cfm + frontend/frontendEditor.less),
 * which is itself `position:fixed; max-width:810px; z-index:100`. That ancestor
 * creates a stacking context, so no z-index we set can lift the maximized editor
 * above the admin toolbar (z-index 103) - it renders *under* the bar. And the
 * frontend control is rendered with `width=800`, which the facade applies as an
 * INLINE width on the container, beating `inset:0` - so it grew in height only.
 *
 * So maximizing PORTALS the container to <body> (escaping any ancestor stacking
 * context / containing block) and neutralises the inline width + max-height for
 * the duration, restoring everything - including the exact DOM position - on exit.
 */

// Class put on <html> while any editor is maximized (kills page scrolling behind
// the editor, as CKEditor's maximize plugin did).
const HOST_CLASS = "tiptap-maximized-host";
const MAX_CLASS  = "is-maximized";

export function isMaximized( container ) {
	return !!( container && container.classList.contains( MAX_CLASS ) );
}

// What carries the height: the editing FRAME for a boxed editor, or the mount
// itself in Modern inline mode (which has no frame - the editable is the page).
// `container.querySelector(".tiptap-editor-mount")` no longer finds a framed
// editor's mount at all: it is in the frame's document.
function heightBoxOf( container ) {
	return container.querySelector( "iframe.tiptap-editor-frame" )
	    || container.querySelector( ".tiptap-editor-mount" );
}

// Suspend the ancestor constraints that would clip or shrink a fixed, full-viewport
// container, and hand back a restore function. Deliberately narrow: only the
// properties that can defeat `inset:0` are touched, only on the ancestors between
// the container and <body>, and every original inline value is put back verbatim.
function hoistAncestors( container ) {
	var touched = [];
	var el = container.parentElement;
	while ( el && el !== document.body && el !== document.documentElement ) {
		var cs = window.getComputedStyle( el );
		var needs = ( cs.overflow !== "visible" ) || ( cs.maxWidth !== "none" ) || ( cs.maxHeight !== "none" );
		if ( needs ) {
			touched.push( { el: el, overflow: el.style.overflow, maxWidth: el.style.maxWidth, maxHeight: el.style.maxHeight } );
			el.style.overflow  = "visible";
			el.style.maxWidth  = "none";
			el.style.maxHeight = "none";
		}
		el = el.parentElement;
	}
	return function() {
		touched.forEach( function( t ) {
			t.el.style.overflow  = t.overflow;
			t.el.style.maxWidth  = t.maxWidth;
			t.el.style.maxHeight = t.maxHeight;
		} );
	};
}

export function enterMaximize( container ) {
	if ( !container || isMaximized( container ) ) { return; }

	var box = heightBoxOf( container );

	container._ttMaximizeState = {
		  unhoist     : hoistAncestors( container )
		, width       : container.style.width
		, maxHeight   : box ? box.style.maxHeight : ""
		, overflowY   : box ? box.style.overflowY : ""
		, height      : box ? box.style.height : ""
		, scrollTop   : window.pageYOffset || document.documentElement.scrollTop || 0
	};

	// Inline width/max-height come from the field's width/maxHeight config and
	// would otherwise win over the maximized layout.
	container.style.width = "";
	if ( box ) {
		box.style.maxHeight = ""; box.style.overflowY = "auto";
		// The frame's auto-height fitter must stand down while the flex layout owns
		// the height, or it fights it back to the content height every edit.
		box.__ttFlex = true;
		box.style.height = "";
		// The frame is now a tall fixed box; its own document has to scroll.
		if ( typeof box.__ttRefit === "function" ) { box.__ttRefit(); }
	}

	container.classList.add( MAX_CLASS );
	document.documentElement.classList.add( HOST_CLASS );
}

export function exitMaximize( container ) {
	if ( !container ) { return; }

	var state = container._ttMaximizeState;
	container.classList.remove( MAX_CLASS );
	container._ttMaximizeState = null;

	if ( state ) {
		container.style.width = state.width;

		var box = heightBoxOf( container );
		if ( box ) {
			box.style.maxHeight = state.maxHeight;
			box.style.overflowY = state.overflowY;
			box.__ttFlex = false;
			box.style.height = state.height;
			// Re-measure: the content reflowed at full-viewport width while maximized.
			if ( typeof box.__ttRefit === "function" ) { box.__ttRefit(); }
		}

		if ( typeof state.unhoist === "function" ) { state.unhoist(); }
		window.scrollTo( 0, state.scrollTop );
	}

	// Only unlock the page once no editor is left maximized.
	if ( !document.querySelector( ".tiptap-editor-container." + MAX_CLASS ) ) {
		document.documentElement.classList.remove( HOST_CLASS );
	}
}

/**
 * Toggle, returning the new maximized state. `editor` (optional) is refocused
 * afterwards - re-parenting a contenteditable drops the selection.
 */
export function toggleMaximize( container, editor ) {
	if ( isMaximized( container ) ) {
		exitMaximize( container );
	} else {
		enterMaximize( container );
	}

	if ( editor ) {
		// view.focus(), not commands.focus() - see the note on CompatInstance.focus in
		// src/facade.js: the command dispatches a transaction built before its own
		// view.focus() ran, which WebKit turns into a mismatched transaction. The
		// try/catch here had been silently swallowing exactly that.
		try { editor.view.focus(); } catch ( e ) {}
	}
	return isMaximized( container );
}

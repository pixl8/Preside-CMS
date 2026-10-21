/**
 * Notion-style block drag handle: hovering a block shows a grip in the left
 * gutter; dragging it reorders the block, clicking it selects the block.
 *
 * HAND-ROLLED DELIBERATELY - do not "simplify" this to
 * @tiptap/extension-drag-handle. That package is MIT in v3, but it hard-imports
 * @tiptap/extension-collaboration + @tiptap/y-tiptap, so the build fails without
 * them and installing them drags real Yjs runtime code into the bundle:
 * measured at +139kb (+30% of the vendor bundle) for an editor that does zero
 * collaboration. Everything it would give us is already in what we ship -
 * nodeDOM for positioning, NodeSelection for the drag, prosemirror-dropcursor
 * (via StarterKit) for the drop indicator.
 *
 * CHROME ONLY - the handle lives on .tiptap-editor-container, never in the
 * editable, so getData() is unaffected by its existence. A drag is of course a
 * real edit, but it is an ordinary ProseMirror move: tokens survive byte-for-byte
 * and undo restores exactly (both covered in test-realworld.html).
 */
import { ICONS } from "./icons.js";
import { surfaceOf } from "./editorFrame.js";
import { t } from "./i18n.js";

// Opt out per site/field, matching the wordcount / outline / tableTools opt-outs.
export function dragHandleEnabled( cfg ) {
	return !( cfg && cfg.defaultConfigs && cfg.defaultConfigs.dragHandle === false );
}

/**
 * @param editor     the Tiptap editor
 * @param container  .tiptap-editor-container (positioning parent + gutter class)
 * @param mount      .tiptap-editor-mount (the scroller)
 * @param withInsert render the "+" (insert block below) alongside the grip. The
 *                   "+" works by typing a "/" for the author, so it is only
 *                   useful when the slash menu is on - the facade passes
 *                   slashMenuEnabled( cfg ), never a bare true.
 * @param opts       { fixed } - Modern inline mode. The container sits in the
 *                   SITE's page flow there, and a gutter carved out of it (or
 *                   hung off it with negative margin) is at the mercy of the
 *                   theme's layout: any overflow:hidden ancestor clips it and
 *                   the grip simply never appears. Fixed mode portals the rail
 *                   to <body> (position:fixed, viewport coords, on the
 *                   --tt-z-base ladder) - immune to clipping, and the content
 *                   column keeps exactly the geometry the rendered page had.
 */
export function createDragHandle( editor, container, mount, withInsert, opts ) {
	const fixed = !!( opts && opts.fixed );

	// `mount` is the editing FRAME for a boxed editor, the mount div inline.
	//
	// THE RAIL LIVES INSIDE THE FRAME, and that is not a style choice - a drag has
	// to begin and end in ONE document. With the grip in the host document and the
	// editable in the frame, `dragstart` fired in one and ProseMirror's
	// `dragover`/`drop` handling ran in the other: `view.dragging` was armed with
	// the right block and the drop then did nothing, so a dragged table vanished
	// instead of moving (T16 caught exactly that - the doc came back with no cells
	// in it at all).
	//
	// Living in the frame also means NO coordinate translation anywhere in this
	// module: the block rects, the pointer, the gutter and the scroller are all in
	// the frame's own space. `host` is what the rail is positioned against and what
	// mouse tracking is bound to - the frame's body/document, or the container in
	// Modern inline mode, which has no frame.
	const surface = surfaceOf( mount );
	const inFrame = surface.isFrame;
	const hostDoc = surface.doc;
	const hostWin = surface.win;
	// The rail's offset parent AND the box its coordinates are relative to. The
	// frame's <body> is made `position:relative` by the frame's own reset, so an
	// absolutely-positioned rail scrolls with the content instead of sticking to
	// the frame's viewport.
	const host    = inFrame ? hostDoc.body : container;
	// The element mouse tracking is bound to: hovering the gutter must not read as
	// leaving the block, and the gutter is inside the frame with the content.
	const tracker = inFrame ? hostDoc.documentElement : container;
	// The visible editor box, in the same space as everything else here. Inside a
	// frame that is the frame's viewport, whose origin is 0,0.
	const boxRect = function() {
		if ( !inFrame ) { return surface.box(); }
		return { top: 0, left: 0, bottom: hostWin.innerHeight, right: hostWin.innerWidth,
		         width: hostWin.innerWidth, height: hostWin.innerHeight };
	};
	const viewportH = function() { return inFrame ? hostWin.innerHeight : ( window.innerHeight || 0 ); };
	const viewportW = function() { return inFrame ? hostWin.innerWidth  : ( window.innerWidth || 0 ); };

	// The gutter only exists when this chrome does, so opting out leaves the
	// editable's padding exactly as it was. Its width depends on how many controls
	// are actually rendered - see the gutter classes in the css.
	//
	// Fixed (inline) mode prefers NO gutter - the rail floats in the page margin
	// and the content column keeps the rendered page's exact geometry. But a
	// full-width layout has no margin to float in (the rail would sit off-screen
	// left), so when the mount starts too close to the viewport edge we reserve
	// an interior gutter after all and draw the rail inside it.
	var GUTTER_NEED = 60; // rail width (~44) + breathing room
	var interiorGutter = false;
	if ( fixed ) {
		try { interiorGutter = mount.getBoundingClientRect().left < GUTTER_NEED; } catch ( e ) {}
	}
	if ( !fixed || interiorGutter ) {
		// The gutter is padding on the MOUNT, which for a framed editor is in the
		// frame's document - a class on the container cannot select it. Put the
		// classes on whichever root can: the frame's <html>, else the container.
		const gutterRoot = surface.isFrame ? surface.doc.documentElement : container;
		gutterRoot.classList.add( "tiptap-has-draghandle" );
		gutterRoot.classList.add( withInsert ? "tiptap-gutter-2" : "tiptap-gutter-1" );
	}

	// One wrapper for both controls so they move together and share the hover
	// bookkeeping - hovering either must not count as leaving the block.
	const rail = hostDoc.createElement( "span" );
	rail.className = "tiptap-block-gutter" + ( fixed ? " is-fixed" : "" );
	( fixed ? document.body : host ).appendChild( rail );

	// "+" first, matching the reference editor's order (and Notion's).
	let insertBtn = null;
	if ( withInsert ) {
		insertBtn = hostDoc.createElement( "button" );
		insertBtn.type = "button";
		insertBtn.className = "tiptap-block-insert";
		insertBtn.title = t( "draghandle.insert" );
		insertBtn.setAttribute( "aria-label", t( "draghandle.insert" ) );
		insertBtn.innerHTML = ICONS.Plus;
		insertBtn.addEventListener( "mousedown", e => e.preventDefault() );
		insertBtn.addEventListener( "click", function( e ) { e.preventDefault(); insertBelow(); } );
		rail.appendChild( insertBtn );
	}

	const handle = hostDoc.createElement( "button" );
	handle.type = "button";
	handle.className = "tiptap-drag-handle";
	handle.draggable = true;
	handle.title = t( "draghandle.tooltip" );
	handle.setAttribute( "aria-label", t( "draghandle.tooltip" ) );
	handle.innerHTML = ICONS.DragGrip;
	rail.appendChild( handle );

	/**
	 * "+" opens the slash menu DIRECTLY at a fresh block - the same popup, item
	 * list and filtering as typing "/" (slashMenu.js's openManual), so the two
	 * affordances cannot drift; the only difference is that no "/" character is
	 * ever written into the document. Typing "/" is a keyboard shortcut for the
	 * menu; a button that types the shortcut's trigger character into the
	 * author's content was backwards.
	 *
	 * An empty paragraph is reused rather than pushed down, so clicking "+" on a
	 * blank line doesn't stack blank lines.
	 */
	function insertBelow() {
		if ( !current ) { return; }
		const node   = current.node;
		const offset = current.offset;
		const reuse  = node.type.name === "paragraph" && node.content.size === 0;
		// offset is the position BEFORE the node (doc.forEach); a fresh paragraph
		// goes in after the whole node, and the caret lands just inside it.
		const insertPos = offset + node.nodeSize;
		const caretPos  = reuse ? offset + 1 : insertPos + 1;

		if ( !reuse ) {
			editor.chain().command( function( { tr, state, dispatch } ) {
				if ( !dispatch ) { return true; }
				tr.insert( insertPos, state.schema.nodes.paragraph.create() );
				return dispatch( tr );
			} ).run();
		}
		editor.commands.focus( caretPos );

		const storage = editor.storage && editor.storage.presideSlashMenu;
		if ( storage && storage.openManual ) { storage.openManual(); }
	}

	let current = null;   // { node, offset, dom, rect }
	let dragging = false;

	/**
	 * The top-level block whose DOM box contains this viewport Y.
	 *
	 * Deliberately iterating the doc's own children rather than using
	 * view.posAtCoords: we want the TOP-LEVEL block (the draggable unit), and
	 * posAtCoords returns the innermost position, so a paragraph inside a list
	 * item or a table cell would have to be climbed back up - fiddly, and it
	 * behaves differently for leaf nodes like our embeds. Every top-level block
	 * has DOM (verified), so the boxes are authoritative.
	 */
	function blockAtY( y ) {
		let found = null;
		editor.state.doc.forEach( function( node, offset ) {
			if ( found ) { return; }
			const dom = editor.view.nodeDOM( offset );
			if ( !dom || !dom.getBoundingClientRect ) { return; }
			const rect = dom.getBoundingClientRect();
			if ( y >= rect.top - 2 && y <= rect.bottom + 2 ) {
				found = { node: node, offset: offset, dom: dom, rect: rect };
			}
		} );
		return found;
	}

	function hide() {
		if ( dragging ) { return; }   // never yank the grip out from under a drag
		current = null;
		rail.classList.remove( "is-visible" );
	}

	function show( block ) {
		const cRect = host.getBoundingClientRect();
		const mRect = boxRect();

		// The VISIBLE part of the mount - its intersection with the viewport. In
		// the admin the capped mount is normally fully on screen (no change);
		// inline (Modern mode) the mount is page-height and the raw rect would
		// clamp the grip somewhere off screen.
		const vTop    = Math.max( mRect.top, 0 );
		const vBottom = Math.min( mRect.bottom, viewportH() );

		// Don't hover-show a block scrolled out of that visible band.
		if ( block.rect.bottom < vTop || block.rect.top > vBottom ) { hide(); return; }

		current = block;

		// Align to the block's first line rather than its centre: a tall block (a
		// list, a big image) with a centred grip reads as belonging to nothing.
		const size = rail.offsetHeight || 20;

		if ( fixed ) {
			// Viewport coordinates: the rail is a position:fixed body child, drawn
			// just left of the content column - or, on a full-width layout, inside
			// the interior gutter reserved at creation (mRect.left is the mount's
			// border box, so left+4 lands on the padding band, not the text).
			let fTop = block.rect.top + 2;
			if ( fTop < vTop ) { fTop = vTop; }
			if ( fTop > vBottom - size ) { fTop = vBottom - size; }
			let fLeft = interiorGutter
				? mRect.left + 4
				: mRect.left - ( rail.offsetWidth || 44 ) - 6;
			if ( fLeft < 4 ) { fLeft = 4; }
			rail.style.top  = Math.round( fTop ) + "px";
			rail.style.left = Math.round( fLeft ) + "px";
			rail.classList.add( "is-visible" );
			return;
		}

		let top = block.rect.top - cRect.top + 2;
		// Keep it within the visible band, so a half-scrolled block's grip does
		// not float over the toolbar (admin) or off the screen (inline).
		const minTop = vTop - cRect.top;
		const maxTop = vBottom - cRect.top - size;
		if ( top < minTop ) { top = minTop; }
		if ( top > maxTop ) { top = maxTop; }

		rail.style.top = Math.round( top ) + "px";
		rail.classList.add( "is-visible" );
	}

	function onMove( e ) {
		if ( !editor.isEditable || dragging ) { return; }
		const block = blockAtY( e.clientY );
		if ( block ) { show( block ); } else { hide(); }
	}

	// Hovering the controls themselves must not count as leaving the block (they
	// sit in the gutter, outside the editable), so listen on the container and
	// only hide when the pointer leaves the whole thing. In fixed mode the rail
	// is NOT a container child, so "leaving the container onto the rail" needs
	// its own carve-out or the grip vanishes en route to being grabbed.
	function onLeave( e ) {
		if ( fixed && e.relatedTarget && rail.contains( e.relatedTarget ) ) { return; }
		hide();
	}
	function onRailLeave( e ) {
		if ( e.relatedTarget && ( tracker.contains( e.relatedTarget ) || rail.contains( e.relatedTarget ) ) ) { return; }
		hide();
	}
	// Fixed-position coordinates go stale the moment the page scrolls.
	function onWinScroll() { if ( fixed ) { hide(); } }

	tracker.addEventListener( "mousemove", onMove );
	tracker.addEventListener( "mouseleave", onLeave );
	// A frame scrolls its own document, so the listener goes through the surface.
	const offContentScroll = surface.onScroll( hide );
	if ( fixed ) {
		rail.addEventListener( "mouseleave", onRailLeave );
		window.addEventListener( "scroll", onWinScroll, { passive: true, capture: true } );
	}

	// Clicking the grip selects the whole block - which is also what makes the
	// image tools / table bubble appear for it, so the grip doubles as "select
	// this thing".
	handle.addEventListener( "click", function( e ) {
		e.preventDefault();
		selectCurrent();
	} );

	function selectCurrent() {
		if ( !current || !window.PresideTiptap || !window.PresideTiptap.NodeSelection ) { return false; }
		const NodeSelection = window.PresideTiptap.NodeSelection;
		try {
			const sel = NodeSelection.create( editor.state.doc, current.offset );
			editor.view.dispatch( editor.state.tr.setSelection( sel ) );
			editor.view.focus();
			return true;
		} catch ( err ) { return false; }
	}

	handle.addEventListener( "dragstart", function( e ) {
		if ( !current ) { e.preventDefault(); return; }

		// Select the node first: ProseMirror's own drop handling moves whatever
		// view.dragging says is being dragged, and a NodeSelection's content is
		// exactly the block.
		if ( !selectCurrent() ) { e.preventDefault(); return; }

		// ...and CHECK IT STUCK. A plugin can normalise a NodeSelection away -
		// prosemirror-tables does exactly that unless allowTableNodeSelection is on
		// - and then ProseMirror's move-on-drop deletes whatever the selection
		// became (a cell, say) instead of the block, silently DUPLICATING it. Since
		// dispatching cannot be trusted to have taken effect, refuse to start the
		// drag rather than risk duplicating content: a grip that does nothing is a
		// far better failure than one that copies.
		const sel = editor.view.state.selection;
		if ( !sel.node || sel.from !== current.offset ) { e.preventDefault(); return; }

		dragging = true;
		handle.classList.add( "is-dragging" );

		const slice = editor.view.state.selection.content();
		editor.view.dragging = { slice: slice, move: true };

		if ( e.dataTransfer ) {
			e.dataTransfer.effectAllowed = "move";
			// Some browsers cancel a drag with no data attached.
			try { e.dataTransfer.setData( "text/html", current.dom.outerHTML ); } catch ( err ) {}
			// Drag the block itself as the ghost, anchored to where the pointer
			// actually is relative to the block, so it does not visually jump
			// towards the grip on pick-up. The grip sits LEFT of the block, so the
			// x offset is clamped at 0 (negative setDragImage offsets are
			// unreliable across browsers) - the ghost's left edge rides the cursor.
			try {
				const gx = Math.max( 0, e.clientX - current.rect.left );
				const gy = Math.max( 0, Math.min( e.clientY - current.rect.top, current.rect.height ) );
				e.dataTransfer.setDragImage( current.dom, gx, gy );
			} catch ( err ) {}
		}
	} );

	handle.addEventListener( "dragend", function() {
		dragging = false;
		handle.classList.remove( "is-dragging" );
		editor.view.dragging = null;
		// dragend only fires at the drag SOURCE (the grip), which is outside the
		// editable - relay it so the dropcursor plugin clears its line on a
		// cancelled (Esc'd) drag, not just on a completed drop.
		try { editor.view.dom.dispatchEvent( new DragEvent( "dragend", { bubbles: true } ) ); } catch ( err ) {}
		hide();
	} );

	/**
	 * The grip lives in the gutter, OUTSIDE the ProseMirror editable - so a drag
	 * started there and moved straight up/down keeps the pointer over the gutter
	 * (or the rail's own buttons), where ProseMirror never sees the dragover: no
	 * drop indicator, no drop. Users had to drift right into the text for the
	 * line to appear. So while OUR drag is live, dragover/drop landing in a band
	 * just left of the editable are re-dispatched to the editable with the x
	 * clamped inside it - a vertical-only drag then behaves exactly like one
	 * over the text. Synthetic drag events are fine here: ProseMirror (and the
	 * dropcursor plugin) handle them regardless of isTrusted, which is also what
	 * T15 relies on.
	 *
	 * The same dragover pass drives EDGE AUTO-SCROLL: near the top/bottom of the
	 * visible band the scroller (the mount when it scrolls, the window
	 * otherwise/additionally - inline mode's scroller IS the page) is nudged
	 * proportionally, so a block can be dragged to an off-screen spot in one
	 * gesture instead of drop-scroll-drag again. dragover keeps firing while the
	 * pointer is stationary, which is what makes hover-at-the-edge scrolling
	 * work without any rAF loop of our own.
	 */
	const SCROLL_ZONE = 40;   // px from the visible edge that starts scrolling
	const SCROLL_MAX  = 28;   // px per dragover event at the very edge

	function scrollSpeed( dist ) {
		return Math.ceil( ( SCROLL_ZONE - Math.max( 0, dist ) ) / SCROLL_ZONE * SCROLL_MAX );
	}

	function autoScroll( x, y ) {
		const mRect = boxRect();
		// Ignore positions nowhere near the editor column - dragging sideways over
		// unrelated page chrome must not scroll anything.
		if ( x < mRect.left - 80 || x > mRect.right + 40 ) { return; }

		if ( surface.canScroll() ) {
			const vTop    = Math.max( mRect.top, 0 );
			const vBottom = Math.min( mRect.bottom, viewportH() );
			if ( y < vTop + SCROLL_ZONE )         { surface.scrollTo( surface.scrollTop() - scrollSpeed( y - vTop ) ); }
			else if ( y > vBottom - SCROLL_ZONE ) { surface.scrollTo( surface.scrollTop() + scrollSpeed( vBottom - y ) ); }
		}
		// The window scrolls too when the editor overflows the viewport (inline
		// mode, or a tall uncapped admin field).
		// Inside a frame it is the frame's own window that scrolls; inline it is the
		// page. Either way `hostWin` is the one whose viewport `y` is measured in.
		if ( y < SCROLL_ZONE )                       { hostWin.scrollBy( 0, -scrollSpeed( y ) ); }
		else if ( y > viewportH() - SCROLL_ZONE )    { hostWin.scrollBy( 0, scrollSpeed( viewportH() - y ) ); }
	}

	function forwardToEditable( e ) {
		const pmDom = editor.view.dom;
		if ( pmDom.contains( e.target ) ) { return; }   // ProseMirror already sees it

		const mRect = boxRect();
		const vTop    = Math.max( mRect.top, 0 );
		const vBottom = Math.min( mRect.bottom, viewportH() );
		// The forwarding band: the gutter / rail column left of the content
		// (fixed-mode rails float up to ~50px outside the mount), within the
		// visible part of the mount.
		if ( e.clientY < vTop || e.clientY > vBottom ) { return; }
		if ( e.clientX < mRect.left - 80 || e.clientX > mRect.right ) { return; }

		const pmRect = pmDom.getBoundingClientRect();
		const x = Math.max( e.clientX, pmRect.left + 2 );
		let clone;
		try {
			clone = new DragEvent( e.type, {
				bubbles      : true,
				cancelable   : true,
				clientX      : x,
				clientY      : e.clientY,
				dataTransfer : e.dataTransfer
			} );
		} catch ( err ) { return; }
		pmDom.dispatchEvent( clone );
		// preventDefault on the ORIGINAL dragover is what marks the gutter a valid
		// drop target; on drop it stops any native handling of the raw event.
		e.preventDefault();
		if ( e.type === "drop" ) { e.stopPropagation(); }
	}

	function onDocDragOver( e ) {
		if ( !dragging ) { return; }
		autoScroll( e.clientX, e.clientY );
		forwardToEditable( e );
	}
	function onDocDrop( e ) {
		if ( !dragging ) { return; }
		forwardToEditable( e );
	}

	hostDoc.addEventListener( "dragover", onDocDragOver, true );
	hostDoc.addEventListener( "drop", onDocDrop, true );

	editor.on( "destroy", function() {
		tracker.removeEventListener( "mousemove", onMove );
		tracker.removeEventListener( "mouseleave", onLeave );
		offContentScroll();
		hostDoc.removeEventListener( "dragover", onDocDragOver, true );
		hostDoc.removeEventListener( "drop", onDocDrop, true );
		if ( fixed ) {
			window.removeEventListener( "scroll", onWinScroll, { capture: true } );
			// Body-portalled - the facade's container removal cannot collect it.
			rail.remove();
		}
	} );

	return rail;
}

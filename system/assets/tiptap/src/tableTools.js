/**
 * Table chrome: a bubble toolbar over the table the caret is in.
 *
 * CHROME ONLY - like src/outline.js, this lives on .tiptap-editor-container and
 * never inside the editable, so getData() is byte-identical whether it is on or
 * off. Every button is a plain Tiptap table command; nothing here invents markup.
 *
 * Opt out per site/field with defaultConfigs.tableTools = false.
 *
 * Why a hand-rolled bubble rather than Tiptap's BubbleMenu: that ships as a
 * React/Vue component (@tiptap/react/menus), and this bundle is vanilla. The
 * positioning we need is also simpler than the generic case - anchor to the
 * table element's box, clamped to the editable - so there is nothing to gain
 * from the dependency.
 *
 * Placement note: the bubble is anchored to the table's TOP edge and drawn
 * ABOVE it, flipping below only when there is no room. That is the opposite of
 * the reference editor (which always sits below) and deliberate: a table's last
 * row is where you are usually typing when you reach for "add row", and a
 * bubble pinned under the table covers the row you just created.
 */
import { ICONS } from "./icons.js";
import { t } from "./i18n.js";
import { surfaceOf } from "./editorFrame.js";
import { focusEditable } from "./editorFocus.js";

// Opt out per site/field, matching the wordcount / outline / imageTools opt-outs.
export function tableToolsEnabled( cfg ) {
	return !( cfg && cfg.defaultConfigs && cfg.defaultConfigs.tableTools === false );
}

// [ i18n key, icon key, chain method, "can" method ]. Groups are separated by
// null. Order mirrors the reference editor's bubble (column ops, row ops, cell
// ops, destructive last) because that grouping reads well; the header toggles
// are ours - CKEditor's table dialog had them and Preside content commonly uses
// <th>, so losing them would be a regression against the editor we replace.
const BUTTONS = [
	  [ "table.column.before", "TableColBefore", "addColumnBefore", "addColumnBefore" ]
	, [ "table.column.after",  "TableColAfter",  "addColumnAfter",  "addColumnAfter"  ]
	, [ "table.column.delete", "TableColDelete", "deleteColumn",    "deleteColumn"    ]
	, null
	, [ "table.row.before",    "TableRowBefore", "addRowBefore",    "addRowBefore"    ]
	, [ "table.row.after",     "TableRowAfter",  "addRowAfter",     "addRowAfter"     ]
	, [ "table.row.delete",    "TableRowDelete", "deleteRow",       "deleteRow"       ]
	, null
	, [ "table.cells.merge",   "TableMerge",     "mergeCells",      "mergeCells"      ]
	, [ "table.cells.split",   "TableSplit",     "splitCell",       "splitCell"       ]
	, null
	, [ "table.headerrow",     "TableHeaderRow", "toggleHeaderRow",    "toggleHeaderRow"    ]
	, [ "table.headercolumn",  "TableHeaderCol", "toggleHeaderColumn", "toggleHeaderColumn" ]
	, null
	, [ "table.delete",        "TableDelete",    "deleteTable",     "deleteTable"     ]
];

/**
 * Mount the table bubble on one editor.
 *
 * container  .tiptap-editor-container (the bubble's positioning parent)
 * mount      .tiptap-editor-mount (the scroller - the bubble must move with it)
 *
 * Returns the bubble element (already appended to `container`).
 */
export function createTableTools( editor, container, mount ) {
	// `mount` is the editing FRAME for a boxed editor and the mount div in Modern
	// inline mode; surfaceOf() hides the difference. The bubble itself stays in the
	// HOST document on the container, so table geometry - measured inside the frame
	// - is translated with toHost().
	const surface = surfaceOf( mount );
	const bubble = document.createElement( "div" );
	bubble.className = "tiptap-table-bubble";
	bubble.setAttribute( "role", "toolbar" );
	bubble.setAttribute( "aria-label", t( "toolbar.table" ) );

	const updaters = [];

	BUTTONS.forEach( function( spec ) {
		if ( !spec ) {
			const sep = document.createElement( "span" );
			sep.className = "tiptap-toolbar-sep";
			bubble.appendChild( sep );
			return;
		}

		const label = t( spec[ 0 ] );
		const btn   = document.createElement( "button" );
		btn.type = "button";
		btn.className = "tiptap-btn";
		btn.title = label;
		btn.setAttribute( "aria-label", label );
		btn.innerHTML = ICONS[ spec[ 1 ] ];

		// mousedown-preventDefault keeps the cell selection: focusing the button
		// would collapse a CellSelection, and mergeCells/splitCell need it.
		btn.addEventListener( "mousedown", function( e ) { e.preventDefault(); } );
		btn.addEventListener( "click", function( e ) {
			e.preventDefault();
			const chain = focusEditable( editor ).chain().focus();
			if ( typeof chain[ spec[ 2 ] ] === "function" ) { chain[ spec[ 2 ] ]().run(); }
		} );

		bubble.appendChild( btn );

		// Grey out what ProseMirror cannot do in the current selection (merge with
		// one cell selected, delete the last column, ...) instead of offering a
		// button that silently no-ops.
		updaters.push( function() {
			let ok = false;
			try {
				const can = editor.can();
				ok = typeof can[ spec[ 3 ] ] === "function" ? !!can[ spec[ 3 ] ]() : false;
			} catch ( err ) { ok = false; }
			btn.disabled = !ok;
		} );
	} );

	container.appendChild( bubble );

	let visible = false;

	function tableEl() {
		// The <table> the caret sits in. ProseMirror gives us the cell DOM via
		// domAtPos; walk up to the table and make sure it is ours (a nested editor
		// on the page must not steal it).
		const sel = editor.state.selection;
		let dom;
		try { dom = editor.view.domAtPos( sel.from ).node; }
		catch ( err ) { return null; }
		if ( !dom ) { return null; }
		const el = ( dom.nodeType === 1 ? dom : dom.parentNode );
		if ( !el || !el.closest ) { return null; }
		const table = el.closest( "table" );
		return ( table && editor.view.dom.contains( table ) ) ? table : null;
	}

	function place( table ) {
		const cRect = container.getBoundingClientRect();
		const tRect = surface.toHost( table.getBoundingClientRect() );
		const mRect = surface.box();

		// Clamp against the VISIBLE part of the mount - its intersection with the
		// viewport. In the admin the capped-height mount is normally fully on
		// screen, so this is the mount rect unchanged; inline (Modern mode) the
		// mount is page-height and the raw rect would park the bubble somewhere
		// far off screen.
		const vTop    = Math.max( mRect.top, 0 );
		const vBottom = Math.min( mRect.bottom, window.innerHeight );
		const vLeft   = Math.max( mRect.left, 0 );
		const vRight  = Math.min( mRect.right, window.innerWidth );

		// Hide when the table has scrolled out of that visible band - otherwise
		// the bubble floats over unrelated content.
		if ( tRect.bottom < vTop - 4 || tRect.top > vBottom + 4 ) { return false; }

		const bw = bubble.offsetWidth;
		const bh = bubble.offsetHeight;

		// Above the table by preference (see the header note on why not below).
		let top = tRect.top - cRect.top - bh - 6;
		if ( tRect.top - vTop < bh + 8 ) { top = tRect.bottom - cRect.top + 6; }

		// Keep it inside the visible band vertically, so it never overlaps the
		// toolbar (admin) or leaves the screen (inline).
		const minTop = vTop - cRect.top + 2;
		const maxTop = vBottom - cRect.top - bh - 2;
		if ( top < minTop ) { top = minTop; }
		if ( top > maxTop ) { top = maxTop; }

		// Left-anchored to the table, then clamped into the visible band -
		// centring it clips the end buttons off a narrow or right-hand table (the
		// same lesson as imageTools' placeBubble).
		let left = tRect.left - cRect.left;
		const maxLeft = vRight - cRect.left - bw - 4;
		const minLeft = vLeft - cRect.left + 4;
		if ( left > maxLeft ) { left = maxLeft; }
		if ( left < minLeft ) { left = minLeft; }

		bubble.style.top  = Math.round( top ) + "px";
		bubble.style.left = Math.round( left ) + "px";
		return true;
	}

	function refresh() {
		const table = editor.isEditable ? tableEl() : null;
		if ( !table ) {
			if ( visible ) { bubble.classList.remove( "is-open" ); visible = false; }
			return;
		}
		updaters.forEach( function( u ) { u(); } );
		// Measure only once it can be measured: offsetWidth is 0 while display:none.
		bubble.classList.add( "is-open" );
		visible = true;
		if ( !place( table ) ) { bubble.classList.remove( "is-open" ); visible = false; }
	}

	// rAF-throttled, matching outline.js: selectionUpdate + transaction fire in
	// bursts and each one would otherwise force a layout read.
	let queued = false;
	function schedule() {
		if ( queued ) { return; }
		queued = true;
		requestAnimationFrame( function() { queued = false; refresh(); } );
	}

	editor.on( "selectionUpdate", schedule );
	editor.on( "transaction",     schedule );
	editor.on( "focus",           schedule );
	editor.on( "blur",            schedule );
	// A frame scrolls its own DOCUMENT - `iframe.addEventListener("scroll")` never
	// fires - so the listener goes through the surface.
	const offScroll = surface.onScroll( schedule );
	window.addEventListener( "scroll", schedule, { passive: true } );
	window.addEventListener( "resize", schedule );

	editor.on( "destroy", function() {
		offScroll();
		window.removeEventListener( "scroll", schedule );
		window.removeEventListener( "resize", schedule );
	} );

	schedule();
	return bubble;
}

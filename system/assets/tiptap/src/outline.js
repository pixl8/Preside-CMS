/**
 * Document outline navigator.
 *
 * A collapsed RAIL of short horizontal lines pinned to the right edge of the
 * editor - one line per heading, its width derived from the heading level - that
 * expands on hover (or focus, or a click/tap to pin) into a panel listing the
 * heading text. Clicking either a rail line or a panel entry puts the caret in
 * that heading and scrolls it into view; the current heading highlights as you
 * scroll past it.
 *
 * Design notes:
 *  - The outline is CHROME, appended to `.tiptap-editor-container` (not into the
 *    editable), so it never touches the document: getData() is unaffected and the
 *    rail does not scroll away with the content (the scroll container is
 *    `.tiptap-editor-mount`, one level in).
 *  - The rail column is `pointer-events:none`; only the rows themselves take
 *    pointer events, so the right-hand edge of the editable stays clickable
 *    everywhere the rail is not physically drawn.
 *  - The rail stays vertically CENTRED on the editable however long the heading
 *    list gets. Two things are load-bearing for that: the panel is out of flow
 *    (a hidden-but-laid-out flex sibling would make the wrapper as tall as the
 *    heading list and push the top-aligned rail upwards), and `place()` sets the
 *    wrapper's `top` from the editable's own box rather than the container's.
 *  - The outline ADAPTS to how much room it has (see railPlan): it shows the
 *    deepest heading level that fits, dropping a level at a time, and if even
 *    top-level headings outnumber the room available it samples every Nth.
 *  - The rail and the panel show the SAME set: the panel is the label list FOR
 *    the markers, so it can never list a heading the rail does not mark. The
 *    panel's rows are ~3x a rail row, so the panel is what caps the plan -
 *    which is also what keeps either of them from outgrowing the editor.
 *  - Rebuilt on every doc change (headings are few; the DOM is tiny) and on
 *    resize - the plan depends on the editor's height.
 *  - Opt out per site/field with `defaultConfigs.outline = false`.
 */
import { t } from "./i18n.js";
import { surfaceOf } from "./editorFrame.js";
import { focusEditable } from "./editorFocus.js";

const MAX_LEVEL = 6;

// Rail row height in px - MUST match .tiptap-outline-row in src/tiptap.css; the
// rail's capacity (how many markers fit) is derived from it.
const ROW_HEIGHT = 8;

// Breathing room kept clear at the top and bottom of the rail's band.
const RAIL_MARGIN = 24;

// A panel entry's height (12px/1.5 line + 3px padding top and bottom) and the
// panel's own vertical padding + border - MUST track .tiptap-outline-item /
// .tiptap-outline-panel in src/tiptap.css. Used to work out how many entries fit.
const PANEL_ROW_HEIGHT = 24;
const PANEL_PADDING    = 20;

// How far below the top of the viewport a heading counts as "the one you are on"
// while scrolling.
const ACTIVE_OFFSET = 28;

// Rail line widths (px) by heading level: h1 widest, h6 narrowest.
function railWidth( level ) {
	return Math.max( 8, 22 - ( ( Math.min( level, MAX_LEVEL ) - 1 ) * 3 ) );
}

// Opt out with defaultConfigs.outline = false (nothing rendered).
export function outlineEnabled( cfg ) {
	return !cfg || !cfg.defaultConfigs || cfg.defaultConfigs.outline !== false;
}

function collectHeadings( tiptap ) {
	const items = [];
	tiptap.state.doc.descendants( function( node, pos ) {
		if ( node.type.name === "heading" ) {
			items.push( {
				  level: Math.min( Math.max( parseInt( node.attrs.level, 10 ) || 1, 1 ), MAX_LEVEL )
				, text : String( node.textContent || "" ).trim()
				, pos  : pos
			} );
			return false; // headings hold inline content only - no need to descend
		}
		return true;
	} );
	return items;
}

/**
 * Decide what the rail shows, given how many rows fit in it.
 *
 * Detail is traded for legibility, in that order:
 *   1. the deepest heading level whose headings all fit (h1-h6, then h1-h5, ...);
 *   2. failing that (e.g. 100 h1s in a rail with room for 10), every Nth heading
 *      of the shallowest level present.
 *
 * `levels` is capped at the SHALLOWEST level actually present, so a document that
 * starts at h2 (very common) still gets a rail rather than an empty one.
 *
 * Returns { entries, level, stride }, where each entry is
 * { item, index } - index being the heading's position in the full list, which is
 * what the active-highlight maps through.
 */
export function railPlan( items, capacity ) {
	capacity = Math.max( 1, capacity );

	let shallowest = null;
	for ( let level = MAX_LEVEL; level >= 1; level-- ) {
		const entries = [];
		items.forEach( function( item, index ) {
			if ( item.level <= level ) { entries.push( { item: item, index: index } ); }
		} );

		if ( !entries.length ) { break; } // gone shallower than the document goes
		shallowest = { entries: entries, level: level, stride: 1 };
		if ( entries.length <= capacity ) { return shallowest; }
	}

	if ( !shallowest ) { return { entries: [], level: 1, stride: 1 }; }

	// Still too many at the shallowest level - sample evenly across them.
	const stride = Math.ceil( shallowest.entries.length / capacity );
	return {
		  entries: shallowest.entries.filter( function( e, i ) { return i % stride === 0; } )
		, level  : shallowest.level
		, stride : stride
	};
}

// The rendered element for a heading at `pos` (pos is directly BEFORE the node).
function headingDom( tiptap, pos ) {
	try {
		const dom = tiptap.view.nodeDOM( pos );
		if ( dom && dom.nodeType === 1 ) { return dom; }
	} catch ( e ) {}
	try {
		let node = tiptap.view.domAtPos( pos + 1 ).node;
		if ( node && node.nodeType === 3 ) { node = node.parentNode; }
		return ( node && node.nodeType === 1 ) ? node : null;
	} catch ( e ) {}
	return null;
}

/**
 * "You landed here" highlight, as a ProseMirror node decoration.
 *
 * It has to be a decoration rather than a class on the rendered heading: the
 * next DOM sync rewrites the node's attributes from the schema, wiping any class
 * we set ourselves. Decorations are view-only, so the document (and getData())
 * is untouched and no `update` fires - the form does not become dirty.
 *
 * Returns a `flash( pos )` function, or null when the PM primitives are absent
 * (older vendor bundle) - the outline then simply has no highlight.
 */
function createFlash( tiptap ) {
	const PM = window.PresideTiptap || {};
	if ( !PM.Plugin || !PM.PluginKey || !PM.Decoration || !PM.DecorationSet ) { return null; }

	const key = new PM.PluginKey( "presideOutlineFlash" );
	tiptap.registerPlugin( new PM.Plugin( {
		  key  : key
		, state: {
			  init : function() { return PM.DecorationSet.empty; }
			, apply: function( tr, set ) {
				const action = tr.getMeta( key );
				if ( action && action.clear ) { return PM.DecorationSet.empty; }
				if ( action && action.pos != null ) {
					const node = tr.doc.nodeAt( action.pos );
					if ( !node ) { return PM.DecorationSet.empty; }
					return PM.DecorationSet.create( tr.doc, [
						PM.Decoration.node( action.pos, action.pos + node.nodeSize, { "class": "tiptap-outline-target" } )
					] );
				}
				return set.map( tr.mapping, tr.doc );
			}
		}
		, props: {
			decorations: function( state ) { return key.getState( state ); }
		}
	} ) );

	let timer = null;
	function dispatch( meta ) {
		try { tiptap.view.dispatch( tiptap.state.tr.setMeta( key, meta ) ); } catch ( e ) {}
	}
	tiptap.on( "destroy", function() { window.clearTimeout( timer ); } );

	return function flash( pos ) {
		window.clearTimeout( timer );
		dispatch( { pos: pos } );
		timer = window.setTimeout( function() { dispatch( { clear: true } ); }, 1400 );
	};
}

/**
 * Build the outline for an editor. Returns the element to append to the
 * container (already wired to the editor).
 *
 * `opts.fixed` - Modern inline mode: the editable is the site page and the PAGE
 * is the scroller, so a rail centred on (and sized to) the editable would sit
 * mid-document, mostly off-screen. Fixed mode pins the rail to the right edge
 * of the VIEWPORT instead, with capacity measured from the viewport height -
 * the click-to-scroll and active-heading tracking already handle the
 * window-as-scroller case (tall uncapped admin fields exercise it too). Still
 * a container child (the --tt-* variables keep cascading to it), just
 * position:fixed.
 */
export function createOutline( tiptap, mount, opts ) {
	// `mount` is the editing FRAME for a boxed editor, the mount div in Modern
	// inline mode. The rail is HOST chrome on the container either way, so heading
	// geometry (measured inside the frame) is translated with toHost(), and the
	// scroller is the frame's own document rather than the element - an <iframe>
	// never fires a scroll event itself.
	const surface = surfaceOf( mount );
	const fixed = !!( opts && opts.fixed );

	const wrap = document.createElement( "div" );
	wrap.className = "tiptap-outline" + ( fixed ? " is-fixed" : "" );

	const rail = document.createElement( "div" );
	rail.className = "tiptap-outline-rail";
	rail.setAttribute( "aria-hidden", "true" );

	// No visible heading - the list speaks for itself. `outline.title` stays as the
	// accessible name for the landmark.
	const panel = document.createElement( "nav" );
	panel.className = "tiptap-outline-panel";
	panel.setAttribute( "aria-label", t( "outline.title" ) );

	const list = document.createElement( "div" );
	list.className = "tiptap-outline-list";
	panel.appendChild( list );

	wrap.appendChild( panel );
	wrap.appendChild( rail );

	const flash = createFlash( tiptap );

	let items   = [];   // every heading in the document, in order
	// The rail and the panel show the SAME set - whatever railPlan() decided fits
	// (see layout()). Each entry: { item, index (into `items`), row, btn }.
	let entries = [];
	let active  = -1;   // index into `items`

	function go( item ) {
		// Caret first, WITHOUT Tiptap's own scrollIntoView - we do the scrolling
		// ourselves so the same path runs whether the mount or the page scrolls.
		//
		// setTextSelection, NOT `focus( pos )`. Passing a position to Tiptap's focus
		// command skips its own `view.hasFocus()` early-return, so on Safari it runs
		// a SYNCHRONOUS `view.dom.focus()` mid-chain - prosemirror re-reads the
		// selection, dispatches a correction, and the chain's own transaction is then
		// applied to a state it was not built from ("Applying a mismatched
		// transaction"). The whole chain was lost, so clicking a rail entry silently
		// failed to move the caret in Safari - silently because of this try/catch.
		// See src/editorFocus.js. The DOM focus is taken first, outside the chain,
		// where it is free to dispatch whatever it likes.
		focusEditable( tiptap );
		try { tiptap.chain().setTextSelection( item.pos + 1 ).run(); } catch ( e ) {}
		if ( flash ) { flash( item.pos ); }

		const el = headingDom( tiptap, item.pos );
		if ( !el ) { return; }

		// A capped-height mount (data-max-height, or maximized) is the scroller:
		// scroll it directly rather than letting scrollIntoView() drag the
		// surrounding admin page around with it.
		if ( isMountScrollable() ) {
			// Both rects in the CONTENT's own space: inside a frame the heading and
			// the scrollport share it, so no translation is wanted here.
			const portTop = surface.isFrame
				? 0                                        // the frame's viewport origin
				: mount.getBoundingClientRect().top;
			const delta = el.getBoundingClientRect().top - portTop;
			surface.scrollTo( Math.max( 0, surface.scrollTop() + delta - 8 ), true );
			return;
		}

		// The whole document fits in the field, so there is nothing to scroll TO -
		// the caret and the highlight are the entire result. Do NOT fall back to
		// scrollIntoView() here: with no scroller of our own the browser satisfies
		// it by scrolling the admin PAGE, which yanks the form around under a
		// heading that was already on screen.
		if ( isVisibleInViewport( el ) ) { return; }

		// Only when the heading really is off-screen (a tall, uncapped field can be
		// longer than the viewport) is moving the page justified - and then by the
		// least amount that reveals it, not a jump to the top.
		if ( typeof el.scrollIntoView === "function" ) {
			el.scrollIntoView( { behavior: "smooth", block: "nearest" } );
		}
	}

	// "On screen" means on the USER's screen, so a heading inside a frame is judged
	// by where the frame puts it in the host viewport.
	function isVisibleInViewport( el ) {
		const box    = surface.toHost( el.getBoundingClientRect() );
		const height = window.innerHeight || document.documentElement.clientHeight || 0;
		return box.top >= 0 && box.bottom <= height;
	}

	function isMountScrollable() {
		return surface.canScroll();
	}

	// How many headings the outline can show, measured off the EDITABLE (the band
	// the rail sits against) rather than the container, so it never runs into the
	// toolbar or footer. Measured, not read from the stylesheet: the computed value
	// of a percentage `max-height` stays a percentage, so the CSS cap is not
	// readable in px.
	//
	// The PANEL is the tighter of the two constraints (its rows are ~3x a rail
	// row), and it has to hold the same set as the rail - so it is what caps the
	// plan. Both then fit the editor with nothing scrolling or clipped.
	function capacity() {
		const box = fixed
			? Math.max( 0, ( window.innerHeight || 0 ) - 140 ) // clear of the admin toolbar + margins
			: ( ( surface.box() && surface.box().height ) || ( wrap.parentNode && wrap.parentNode.clientHeight ) || 0 );
		if ( !box ) { return items.length || 1; }
		return Math.max( 1, Math.min(
			  Math.floor( ( box - RAIL_MARGIN ) / ROW_HEIGHT )
			, Math.floor( ( box - PANEL_PADDING ) / PANEL_ROW_HEIGHT )
		) );
	}

	// Centre the rail on the EDITABLE, not the container: with a two-row toolbar
	// (common in the admin, where a configured toolbar wraps) the container's
	// centre sits well below the editable's and the rail would look low. The
	// panel's px cap is a belt: the plan already fits it, but a long single entry
	// or a different font metric should scroll inside the editor, never past it.
	function place() {
		if ( fixed ) {
			// The stylesheet's top:50% + translateY(-50%) centres it in the
			// viewport; only the panel's cap needs a measured value.
			wrap.style.top = "";
			panel.style.maxHeight = Math.max( 120, ( window.innerHeight || 600 ) - 160 ) + "px";
			return;
		}
		// offsetTop/clientHeight of the FRAME - it is a normal element in the host
		// document, so the rail still centres on the editable's box exactly as it did
		// when the mount was one.
		if ( !mount || !mount.offsetHeight ) { return; }
		wrap.style.top = ( mount.offsetTop + ( mount.offsetHeight / 2 ) ) + "px";
		panel.style.maxHeight = Math.max( 120, mount.offsetHeight - 8 ) + "px";
	}

	/**
	 * (Re)build both lists from one shared plan. Safe to call on resize as well as
	 * on a doc change - the plan depends on the editor's height.
	 */
	function layout() {
		place();

		entries = [];
		rail.innerHTML = "";
		list.innerHTML = "";

		if ( !items.length ) {
			const empty = document.createElement( "div" );
			empty.className = "tiptap-outline-empty";
			empty.textContent = t( "outline.empty" );
			list.appendChild( empty );
			return;
		}

		const plan = railPlan( items, capacity() );
		// The outline is showing less than the document holds (a heading level
		// dropped, and/or every Nth) - a hook for tests and future affordances.
		rail.classList.toggle( "is-sampled", plan.stride > 1 );
		rail.classList.toggle( "is-partial", plan.entries.length < items.length );

		plan.entries.forEach( function( entry ) {
			const row = document.createElement( "div" );
			row.className = "tiptap-outline-row";
			const line = document.createElement( "span" );
			line.className = "tiptap-outline-line";
			line.style.width = railWidth( entry.item.level ) + "px";
			row.appendChild( line );
			row.addEventListener( "click", function( ev ) {
				ev.preventDefault();
				go( entry.item );
			} );
			rail.appendChild( row );

			const btn = document.createElement( "button" );
			btn.type = "button";
			btn.className = "tiptap-outline-item";
			btn.setAttribute( "data-level", String( entry.item.level ) );
			btn.style.paddingLeft = ( 10 + ( entry.item.level - 1 ) * 12 ) + "px";
			btn.textContent = entry.item.text || t( "outline.untitled" );
			btn.title = btn.textContent;
			btn.addEventListener( "click", function( ev ) {
				ev.preventDefault();
				go( entry.item );
			} );
			list.appendChild( btn );

			entries.push( { item: entry.item, index: entry.index, row: row, btn: btn } );
		} );

		paintActive();
	}

	function render() {
		items = collectHeadings( tiptap );
		wrap.classList.toggle( "is-empty", !items.length );
		layout();
		syncActive();
	}

	// ---- Active heading ---------------------------------------------------
	// Driven by scroll position when there is something to scroll (the heading
	// last passed), and by the caret otherwise.
	function activeFromScroll() {
		// The comparison line and the headings must be in the SAME space. Inside a
		// frame both are already frame-relative, so the scrollport origin is 0.
		const port = ( !isMountScrollable() || surface.isFrame ) ? 0 : mount.getBoundingClientRect().top;
		const line = port + ACTIVE_OFFSET;
		let found = -1;
		for ( let i = 0; i < items.length; i++ ) {
			const el = headingDom( tiptap, items[ i ].pos );
			if ( !el ) { continue; }
			if ( el.getBoundingClientRect().top - line <= 1 ) { found = i; } else { break; }
		}
		// Above the first heading (its top margin alone is enough to put it below
		// the line at scrollTop 0): treat the first section as the current one
		// rather than dropping the highlight entirely.
		return found === -1 ? 0 : found;
	}

	function activeFromCaret() {
		const from = tiptap.state.selection.from;
		let found = -1;
		for ( let i = 0; i < items.length; i++ ) {
			if ( items[ i ].pos <= from ) { found = i; } else { break; }
		}
		return found;
	}

	function paintActive() {
		// The outline can be a subset of the headings, so highlight the entry AT or
		// ABOVE the active heading - i.e. the section you are in.
		let current = -1;
		entries.forEach( function( e, i ) {
			if ( e.index <= active ) { current = i; }
			e.row.classList.remove( "is-active" );
			e.btn.classList.remove( "is-active" );
		} );
		if ( current > -1 ) {
			entries[ current ].row.classList.add( "is-active" );
			entries[ current ].btn.classList.add( "is-active" );
		}

		// Keep the highlighted entry in view in the (scrollable) panel. Done by
		// hand rather than scrollIntoView(), which would also scroll the panel's
		// ancestors - i.e. the admin page.
		const btn = current > -1 ? entries[ current ].btn : null;
		if ( btn ) {
			const panelBox = panel.getBoundingClientRect();
			const btnBox   = btn.getBoundingClientRect();
			if ( btnBox.top < panelBox.top ) {
				panel.scrollTop += btnBox.top - panelBox.top;
			} else if ( btnBox.bottom > panelBox.bottom ) {
				panel.scrollTop += btnBox.bottom - panelBox.bottom;
			}
		}
	}

	function syncActive( fromScroll ) {
		if ( !items.length ) { active = -1; return; }

		const next = fromScroll ? activeFromScroll() : activeFromCaret();
		if ( next === active ) { return; }
		active = next;
		paintActive();
	}

	// Scroll tracking: the mount when it scrolls, the window when the page does
	// (a short field grows with its content and the admin page is the scroller).
	let queued = false;
	function onScroll() {
		if ( queued ) { return; }
		queued = true;
		window.requestAnimationFrame( function() {
			queued = false;
			syncActive( true );
		} );
	}
	// The content's own scroller (the frame's document, or a capped mount inline)
	// AND the host window - a short field grows with its content, so the admin page
	// is what moves it past the reader.
	const offContentScroll = surface.onScroll( onScroll );
	window.addEventListener( "scroll", onScroll, { passive: true } );

	// ---- Open / close -----------------------------------------------------
	// Tap/click on the rail pins the panel open (touch devices have no hover);
	// clicking a row still navigates - the row handler above runs first. The
	// dismiss listener is only attached while pinned so a destroyed editor
	// (frontend editors, quick-add modals) leaves nothing behind on `document`.
	function unpin() {
		wrap.classList.remove( "is-pinned" );
		document.removeEventListener( "mousedown", onDocDown, true );
	}
	function onDocDown( ev ) { if ( !wrap.contains( ev.target ) ) { unpin(); } }
	rail.addEventListener( "click", function() {
		if ( wrap.classList.contains( "is-pinned" ) ) { return; }
		wrap.classList.add( "is-pinned" );
		document.addEventListener( "mousedown", onDocDown, true );
	} );

	tiptap.on( "transaction", function( args ) {
		if ( !args || !args.transaction || args.transaction.docChanged ) { render(); }
		else { syncActive(); }
	} );

	tiptap.on( "destroy", function() {
		unpin();
		offContentScroll();
		window.removeEventListener( "scroll", onScroll );
	} );

	render();
	// The rail's capacity is unmeasurable until the wrapper is in the document
	// (the facade appends it right after this returns), so lay it out again next
	// frame - and whenever the editor is resized (maximize, window resize).
	if ( window.requestAnimationFrame ) { window.requestAnimationFrame( layout ); }
	if ( window.ResizeObserver && mount ) {
		// Deferred through rAF: laying out from inside the callback writes styles that
		// can need another delivery cycle, which WebKit reports as "ResizeObserver
		// loop completed with undelivered notifications" - harmless, but it shows up
		// as a page error and would mask a real one.
		let roQueued = false;
		const ro = new window.ResizeObserver( function() {
			if ( roQueued ) { return; }
			roQueued = true;
			( window.requestAnimationFrame || window.setTimeout )( function() {
				roQueued = false;
				layout();
			}, 16 );
		} );
		ro.observe( mount );
		tiptap.on( "destroy", function() { ro.disconnect(); } );
	}
	// Fixed mode's capacity comes from the viewport, which the mount observer
	// cannot see change.
	if ( fixed ) {
		const onResize = function() { layout(); };
		window.addEventListener( "resize", onResize );
		tiptap.on( "destroy", function() { window.removeEventListener( "resize", onResize ); } );
	}

	return wrap;
}

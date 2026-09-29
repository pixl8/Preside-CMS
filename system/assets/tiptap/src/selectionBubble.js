/**
 * Selection bubble toolbar (Modern inline mode).
 *
 * Modern mode has no persistent toolbar: a bubble appears over a non-empty
 * TEXT selection, offering the field's configured toolbar buttons FILTERED to
 * what applies to the current block (a heading gets no list buttons, a code
 * block almost nothing, Outdent/Indent only inside a list...). Everything
 * else keeps its own owner: NodeSelections belong to imageTools, cell
 * selections and structure to the table bubble, insertion to the slash menu
 * and drag handle - so there is no caret bubble at all, Medium/gutentap-style.
 *
 * Buttons are built by toolbar.js's renderNames() - the SAME renderers as the
 * main toolbar (Format/Styles dropdowns, Justify* collapse), so the two can
 * never drift; this module only decides WHICH names show. The set is rebuilt
 * on every show (cheap: <= ~15 buttons).
 *
 * Body-portalled like the slash menu, for the same reasons: nothing can clip
 * it, and its z sits on the `--tt-z-base` ladder (declared on <html> by
 * liftChromeZ) so it out-bids sticky site headers. Being outside the
 * container also means its light/dark colours are its own,
 * via prefers-color-scheme.
 *
 * It renders before it positions (slash-menu lesson: an empty box measures
 * wrong), and a mousedown anywhere in it is preventDefault-ed so the editor
 * selection - which everything here operates on - is never lost to a click.
 */
import { renderNames, normaliseToolbar, styleItems } from "./toolbar.js";
import { t } from "./i18n.js";
import { pluginBubbleTests } from "./pluginHost.js";

// Never in the bubble: view/global commands and block-level INSERTION, which
// belong to the persistent chrome (admin) or the slash menu (inline). Table
// structure is the table bubble's job.
var EXCLUDE = [
	  "Maximize", "Source", "Undo", "Redo", "Theme", "DarkMode"
	, "HorizontalRule", "Table", "ImagePicker", "AttachmentPicker", "Widgets"
	// Find / Replace act on the whole DOCUMENT and open a modal over the page, so
	// they belong to the persistent chrome, not to a bubble that exists to act on
	// the selection it is pointing at. SpecialChar stays: it inserts at the caret,
	// which is exactly the bubble's own context.
	, "Find", "Replace"
];

var SHOW_DELAY = 150; // let a drag-selection settle before flashing chrome at it
var GAP        = 24;  // breathing room between the bubble and the text - it now
                      // lives through typing, so hugging the caret line felt in
                      // the way (was 8; user-tuned to ~3x)
var IDLE_MS    = 2500; // no click/keystroke for this long -> fade out (is-idle);
                       // any activity fades it back in. It stays technically
                       // open, just out of the author's face while they read.

// name -> does it apply to the CURRENT selection/block? Anything not listed
// shows whenever its command exists (renderNames drops unknown names anyway).
// Kept local to this module: COMMANDS is the "how to run" map and stays pure.
var APPLIES = {
	  Bold          : function( e ) { return e.can().toggleBold(); }
	, Italic        : function( e ) { return e.can().toggleItalic(); }
	, Underline     : function( e ) { return e.can().toggleUnderline(); }
	, Strike        : function( e ) { return e.can().toggleStrike(); }
	, Subscript     : function( e ) { return e.can().toggleSubscript(); }
	, Superscript   : function( e ) { return e.can().toggleSuperscript(); }
	, CodeSnippet   : function( e ) { return e.can().toggleCodeBlock(); }
	, Blockquote    : function( e ) { return e.can().toggleBlockquote(); }
	, BulletedList  : function( e ) { return e.can().toggleBulletList(); }
	, NumberedList  : function( e ) { return e.can().toggleOrderedList(); }
	// Only meaningful inside a list - as plain buttons they would sit greyed-out
	// dead weight in every bubble otherwise.
	, Outdent       : function( e ) { return e.isActive( "listItem" ); }
	, Indent        : function( e ) { return e.isActive( "listItem" ); }
	, JustifyLeft   : function( e ) { return e.can().setTextAlign( "left" ); }
	, JustifyCenter : function( e ) { return e.can().setTextAlign( "center" ); }
	, JustifyRight  : function( e ) { return e.can().setTextAlign( "right" ); }
	, JustifyBlock  : function( e ) { return e.can().setTextAlign( "justify" ); }
	// Always offered: it is the way OUT of the current block type as much as in
	// (can().setParagraph() is false when the block already is one, which would
	// hide the dropdown exactly where it is most wanted - a plain paragraph).
	, Format        : function() { return true; }
	, Styles        : function( e, cfg ) { return styleItems( cfg, e ).length > 0; }
	, PresideUnlink : function( e ) { return e.isActive( "presideLink" ); }
	// PresideLink / PresideAnchor / RemoveFormat: any text selection.
};

function flattenNames( parsedToolbar ) {
	var names = [];
	normaliseToolbar( parsedToolbar ).forEach( function( group ) {
		if ( group === "/" || !group.forEach ) { return; }
		group.forEach( function( n ) {
			if ( n !== "-" && EXCLUDE.indexOf( n ) === -1 && names.indexOf( n ) === -1 ) { names.push( n ); }
		} );
	} );
	return names;
}

/**
 * Attach to an (inline) editor. Returns a teardown for instance._cleanups -
 * the element lives on <body>, outside the container the facade removes.
 */
export function createSelectionBubble( editor, container, parsedToolbar, cfg ) {
	var el = document.createElement( "div" );
	el.className = "tiptap-selection-bubble";
	el.setAttribute( "role", "toolbar" );
	el.setAttribute( "aria-label", t( "bubble.title" ) );
	document.body.appendChild( el );

	// Keep the editor selection through ANY interaction with the bubble - every
	// command here operates on it. Capture phase so it covers the dropdowns too.
	el.addEventListener( "mousedown", function( e ) { e.preventDefault(); }, true );

	var allNames  = flattenNames( parsedToolbar );
	// A plugin's `bubble` map answers the same question for ITS command names.
	// Merged over ours rather than under it: the entries can only be for names
	// that plugin contributed, since a built-in already has its own answer here.
	var applies   = Object.assign( {}, APPLIES, pluginBubbleTests( cfg ) );
	var updaters  = [];
	var visible   = false;
	var showTimer = null;
	var frame     = null;

	// The bubble shows for ANY focused text context - a selection, a clicked
	// caret, or the caret you are typing at (the block having focus IS the
	// context; hiding it mid-typing read as the bubble randomly vanishing). It
	// follows the caret and only drops on blur or a non-text selection.
	function eligible() {
		var sel = editor.state.selection;
		// Text contexts only: NodeSelection has .node (imageTools' turf),
		// CellSelection has .$anchorCell (the table bubble's).
		if ( sel.node !== undefined || sel.$anchorCell !== undefined ) { return false; }
		if ( !sel.empty ) { return true; }
		return editor.isFocused && !!( sel.$from.parent && sel.$from.parent.isTextblock );
	}

	function rebuild() {
		el.innerHTML = "";
		updaters = [];
		var names = allNames.filter( function( n ) {
			var test = applies[ n ];
			if ( !test ) { return true; }
			try { return !!test( editor, cfg ); } catch ( e ) { return false; }
		} );
		// renderNames owns the group spans now (a Format/Styles combo has to sit
		// outside one), so it is handed the bubble itself as the row. The bubble is
		// one flat pill - the css zeroes the block chrome on both .tiptap-toolbar-group
		// and .tiptap-combo inside it.
		renderNames( el, names, editor, cfg, updaters, { skip: EXCLUDE } );
		updaters.forEach( function( u ) { try { u(); } catch ( e ) {} } );
		return el.childNodes.length > 0;
	}

	function place() {
		var sel = editor.state.selection;
		var a, b;
		try {
			a = editor.view.coordsAtPos( sel.from );
			b = editor.view.coordsAtPos( sel.to );
		} catch ( e ) { return; }

		var selTop    = Math.min( a.top, b.top );
		var selBottom = Math.max( a.bottom, b.bottom );

		var w = el.offsetWidth, h = el.offsetHeight;

		// Above the selection by preference; below when the fixed admin toolbar
		// (or the viewport edge) leaves no room. elementsFromPoint-style checks
		// are overkill here - the admin bar is the one fixed thing we KNOW about,
		// and liftChromeZ has already put us above the site's own chrome.
		var bar      = document.querySelector( ".preside-admin-toolbar" );
		var topLimit = 8 + ( bar && bar.getBoundingClientRect ? Math.max( 0, bar.getBoundingClientRect().bottom ) : 0 );

		var y = selTop - h - GAP;
		if ( y < topLimit ) { y = selBottom + GAP; }

		// LEFT-ALIGNED to the caret's block, not centred on / following the
		// caret: a bubble that slides across the page as you type reads as
		// chasing you. The block's left edge is constant while typing in it, so
		// the bubble only moves vertically.
		var x;
		try {
			var dp   = editor.view.domAtPos( sel.$from.start() );
			var host = dp.node.nodeType === 1 ? dp.node : dp.node.parentNode;
			x = host.getBoundingClientRect().left;
		} catch ( e ) { x = Math.min( a.left, b.left ); }
		x = Math.max( 8, Math.min( x, window.innerWidth - w - 8 ) );

		el.style.top  = Math.round( y ) + "px";
		el.style.left = Math.round( x ) + "px";
	}

	// The filtered button set depends on the BLOCK the caret is in (and whether
	// there is a selection), not on every keystroke - now that the bubble lives
	// through typing, rebuild only when that context changes and merely
	// refresh/reposition otherwise.
	var lastCtx = null;
	function contextKey() {
		var sel = editor.state.selection;
		var $from = sel.$from;
		return ( sel.empty ? "c" : "s" ) + ":" + $from.parent.type.name + ":" + ( $from.depth ? $from.before( $from.depth ) : 0 )
			+ ":" + ( editor.isActive( "listItem" ) ? "li" : "" ) + ( editor.isActive( "presideLink" ) ? "ln" : "" );
	}

	// Idle fade: reading/thinking should not have chrome hovering over the text.
	// Every click/keystroke re-arms the timer (and fades the bubble back in);
	// hovering the bubble itself pins it, since fading it out from under an
	// approaching pointer would be cruel.
	var idleTimer = null;
	function armIdle() {
		if ( idleTimer ) { clearTimeout( idleTimer ); }
		idleTimer = setTimeout( function() { idleTimer = null; if ( visible ) { el.classList.add( "is-idle" ); } }, IDLE_MS );
	}
	function disarmIdle() {
		if ( idleTimer ) { clearTimeout( idleTimer ); idleTimer = null; }
	}

	function show() {
		if ( !eligible() ) { return; }
		var ctx = contextKey();
		if ( !visible || ctx !== lastCtx ) {
			if ( !rebuild() ) { hide(); return; } // nothing applies - no empty pill
			lastCtx = ctx;
		} else {
			updaters.forEach( function( u ) { try { u(); } catch ( e ) {} } );
		}
		el.classList.add( "is-open" );        // render, THEN position
		el.classList.remove( "is-idle" );     // any activity wakes it
		visible = true;
		place();
		armIdle();
	}

	function hide() {
		if ( showTimer ) { clearTimeout( showTimer ); showTimer = null; }
		disarmIdle();
		el.classList.remove( "is-idle" );
		if ( !visible ) { return; }
		visible = false;
		el.classList.remove( "is-open" );
	}

	function onSelection() {
		if ( showTimer ) { clearTimeout( showTimer ); showTimer = null; }
		if ( eligible() ) {
			if ( visible ) { show(); } // already up: retarget instantly, no flicker
			else { showTimer = setTimeout( show, SHOW_DELAY ); }
		} else {
			hide();
		}
	}

	function onTransaction( args ) {
		if ( visible && args && args.transaction && args.transaction.docChanged ) { show(); }
	}

	function onBlur() {
		// Interactions with the bubble never blur (mousedown is prevented), so a
		// real blur means focus went elsewhere - drop the chrome.
		hide();
	}

	function onFocus() { onSelection(); }

	// mouseup rather than click: ProseMirror swallows/reshapes clicks, and the
	// selection is already settled by mouseup. Needed because a click that does
	// NOT move the caret produces no selectionUpdate at all.
	function onMouseUp() { onSelection(); }

	function schedule() {
		if ( !visible || frame ) { return; }
		frame = window.requestAnimationFrame( function() { frame = null; place(); } );
	}

	// Hovering the bubble pins it awake; leaving re-arms the idle fade.
	function onBubbleEnter() { disarmIdle(); el.classList.remove( "is-idle" ); }
	function onBubbleLeave() { if ( visible ) { armIdle(); } }

	var viewDom = editor.view.dom;
	editor.on( "selectionUpdate", onSelection );
	editor.on( "transaction", onTransaction );
	editor.on( "blur", onBlur );
	editor.on( "focus", onFocus );
	viewDom.addEventListener( "mouseup", onMouseUp );
	el.addEventListener( "mouseenter", onBubbleEnter );
	el.addEventListener( "mouseleave", onBubbleLeave );
	window.addEventListener( "scroll", schedule, true );
	window.addEventListener( "resize", schedule );

	return function() {
		editor.off( "selectionUpdate", onSelection );
		editor.off( "transaction", onTransaction );
		editor.off( "blur", onBlur );
		editor.off( "focus", onFocus );
		try { viewDom.removeEventListener( "mouseup", onMouseUp ); } catch ( e ) {}
		window.removeEventListener( "scroll", schedule, true );
		window.removeEventListener( "resize", schedule );
		if ( showTimer ) { clearTimeout( showTimer ); }
		disarmIdle();
		if ( frame ) { window.cancelAnimationFrame( frame ); }
		el.remove();
	};
}

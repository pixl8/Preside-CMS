/**
 * Modal dialog shell — the CKEditor-dialog-shaped chrome that Find/Replace
 * (src/findReplace.js) and Insert Special Character (src/specialChar.js) need.
 *
 * Both of those were CKEditor DIALOGS, not popovers: a titled, modal panel with
 * a tab strip and a button row. This is the one implementation of that shape.
 *
 * IT LIVES IN A SHADOW ROOT, AND THAT IS THE WHOLE POINT.
 *
 * A dialog has to be portalled to <body> (a capped-height field, or any
 * overflow:hidden ancestor, would clip it - the same reason the pickers, the slash
 * menu and the selection bubble live there). But <body> in the Preside admin is
 * bootstrap + Ace territory, and a panel built from a fieldset, a legend, labels,
 * inputs and buttons is precisely what an admin theme has the most opinions about:
 *
 *   - bootstrap's `legend` is 21px, full width, with a bottom border and a 20px
 *     margin - so "Find Options" drew a rule across the dialog and shoved the
 *     options down;
 *   - Ace re-skins `input[type=checkbox]` and re-borders text inputs;
 *   - `label` is pushed to inline-block with its own weight, so the three options
 *     ran together on one line;
 *   - and several of those arrive with `!important`.
 *
 * That is the SAME fight the editable lost before it moved into an iframe (see
 * src/editorFrame.js): a specificity contest against the admin's stylesheets
 * cannot be won, because `!important` and higher-specificity selectors are
 * ordinary content of a real admin theme. So the dialog gets a real boundary too -
 * a shadow root, where no rule from the page can reach it - and our own stylesheet
 * is injected inside (src/ownStyle.js). A shadow root, not an iframe: unlike the
 * editable, this chrome needs no `rem`/`vw` root of its own and hosts nothing
 * editable, so the cheap boundary is enough.
 *
 * Consequences worth knowing:
 *  - Inheritable properties (font, colour, direction) DO cross a shadow boundary,
 *    and form controls inherit no font at all, so `.tiptap-dialog` still states
 *    its own typography explicitly. See the type-scale note in src/tiptap.css.
 *  - The HOST element carries the geometry and the `--tt-z-base` rung INLINE:
 *    it is the one part still exposed to the page, and an inline style cannot be
 *    out-specified (only `!important` could touch it, and nothing in the admin
 *    targets a class it has never heard of).
 *  - Keyboard events are composed, so they still bubble out of the shadow root to
 *    the document - the Esc handler is unaffected. Reaching IN needs
 *    `host.shadowRoot`, which is what the harness tests do.
 *
 * Other rules:
 *  - ONE dialog at a time per page: opening another closes the one on screen,
 *    which is also how re-clicking Find while Find is open behaves.
 *  - It does NOT dim the page to black. The Find dialog's whole job is to point
 *    at a highlighted match behind it, so the scrim is light and the panel is
 *    pinned near the top rather than centred over the content.
 *
 * Deliberately NOT presideBootbox: that is a jQuery/bootstrap modal from the
 * admin page, unavailable on the front end (Modern inline mode), unstyled by our
 * `--tt-*` variables - and subject to exactly the theming above.
 */
import { t } from "./i18n.js";
import { injectOwnStyle } from "./ownStyle.js";

let openInstance = null;   // the dialog currently on screen, if any

/**
 * Open a dialog.
 *
 *   opts.title      heading text
 *   opts.className  extra class on the panel (per-dialog styling hook)
 *   opts.tabs       [ { id, label } ] — omitted for a tab-less dialog
 *   opts.activeTab  which tab id starts selected
 *   opts.onTab      fn( id ) after a tab change
 *   opts.build      fn( body, api ) fills the body element
 *   opts.buttons    [ { label, cls, primary, tabs: [ ids ], onClick( api ) } ]
 *   opts.onClose    fn() when the dialog goes away, however it goes
 *
 * Returns { el, body, close, status, setTab, tab }.
 */
export function openDialog( opts ) {
	opts = opts || {};
	closeDialog();

	// The host is the only element the page can see. Geometry and the z rung go on
	// it INLINE, so no admin rule can move the dialog off the screen.
	const host = document.createElement( "div" );
	host.className = "tiptap-dialog-host";
	host.style.cssText = "position:fixed;top:0;right:0;bottom:0;left:0;"
		+ "z-index:calc(var(--tt-z-base,1040) + 1060)";

	// Shadow root, or the host itself where attachShadow is unavailable - the
	// dialog then renders exactly as before, at the mercy of the page's CSS, which
	// is a cosmetic degradation rather than a broken feature.
	const shadow = host.attachShadow ? host.attachShadow( { mode: "open" } ) : null;
	if ( shadow ) { injectOwnStyle( shadow ); }

	const overlay = document.createElement( "div" );
	overlay.className = "tiptap-dialog-overlay";

	const panel = document.createElement( "div" );
	panel.className = "tiptap-dialog" + ( opts.className ? " " + opts.className : "" );
	panel.setAttribute( "role", "dialog" );
	panel.setAttribute( "aria-modal", "true" );
	panel.setAttribute( "aria-label", opts.title || "" );

	const head = document.createElement( "div" );
	head.className = "tiptap-dialog-head";
	const titleEl = document.createElement( "span" );
	titleEl.className = "tiptap-dialog-title";
	titleEl.textContent = opts.title || "";
	const closeX = document.createElement( "button" );
	closeX.type = "button";
	closeX.className = "tiptap-dialog-x";
	closeX.title = t( "picker.close" );
	closeX.setAttribute( "aria-label", t( "picker.close" ) );
	closeX.innerHTML = "&times;";
	head.appendChild( titleEl );
	head.appendChild( closeX );

	const body = document.createElement( "div" );
	body.className = "tiptap-dialog-body";

	const foot = document.createElement( "div" );
	foot.className = "tiptap-dialog-foot";

	const statusEl = document.createElement( "div" );
	statusEl.className = "tiptap-dialog-status";
	statusEl.setAttribute( "role", "status" );

	panel.appendChild( head );

	let tabBtns = {};
	let current = opts.activeTab || ( opts.tabs && opts.tabs.length ? opts.tabs[ 0 ].id : "" );

	if ( opts.tabs && opts.tabs.length ) {
		const strip = document.createElement( "div" );
		strip.className = "tiptap-dialog-tabs";
		strip.setAttribute( "role", "tablist" );
		opts.tabs.forEach( function( tab ) {
			const b = document.createElement( "button" );
			b.type = "button";
			b.className = "tiptap-dialog-tab";
			b.setAttribute( "role", "tab" );
			b.setAttribute( "data-tab", tab.id );
			b.textContent = tab.label;
			b.addEventListener( "click", function( e ) { e.preventDefault(); api.setTab( tab.id ); } );
			tabBtns[ tab.id ] = b;
			strip.appendChild( b );
		} );
		panel.appendChild( strip );
	}

	panel.appendChild( body );
	panel.appendChild( statusEl );
	panel.appendChild( foot );
	overlay.appendChild( panel );

	const api = {
		  el   : panel
		, body : body
		// Where to query from: the shadow root, not `document`. Nothing outside can
		// see in without it.
		, root : shadow || host
		, host : host
		, tab  : function() { return current; }
		, close: close
		, status: function( msg ) { statusEl.textContent = msg || ""; }
		, setTab: function( id ) {
			current = id;
			Object.keys( tabBtns ).forEach( function( k ) {
				tabBtns[ k ].classList.toggle( "is-active", k === id );
				tabBtns[ k ].setAttribute( "aria-selected", k === id ? "true" : "false" );
			} );
			// Per-tab visibility is expressed on the panel, so the body's own markup
			// stays static: a row/button lists the tabs it belongs to and the CSS
			// hides the rest. Rebuilding the body per tab would lose input values -
			// which is exactly the value-syncing CKEditor's find dialog had to do by
			// hand between its two tabs.
			panel.setAttribute( "data-tab", id );
			api.status( "" );
			buttons.forEach( function( entry ) {
				const on = !entry.tabs || entry.tabs.indexOf( id ) !== -1;
				entry.el.style.display = on ? "" : "none";
			} );
			if ( opts.onTab ) { opts.onTab( id ); }
		}
	};

	const buttons = ( opts.buttons || [] ).map( function( def ) {
		const b = document.createElement( "button" );
		b.type = "button";
		b.className = "tiptap-dialog-btn" + ( def.primary ? " is-primary" : "" ) + ( def.cls ? " " + def.cls : "" );
		b.textContent = def.label;
		b.addEventListener( "click", function( e ) {
			e.preventDefault();
			if ( def.onClick ) { def.onClick( api ); }
		} );
		foot.appendChild( b );
		return { el: b, tabs: def.tabs };
	} );

	if ( opts.build ) { opts.build( body, api ); }

	function close() {
		if ( openInstance !== api ) { return; }
		openInstance = null;
		document.removeEventListener( "keydown", onKey, true );
		host.remove();
		if ( opts.onClose ) { opts.onClose(); }
	}

	function onKey( e ) {
		if ( e.key === "Escape" ) { e.preventDefault(); e.stopPropagation(); close(); }
	}

	closeX.addEventListener( "click", function( e ) { e.preventDefault(); close(); } );
	overlay.addEventListener( "mousedown", function( e ) { if ( e.target === overlay ) { close(); } } );
	document.addEventListener( "keydown", onKey, true );

	( shadow || host ).appendChild( overlay );
	document.body.appendChild( host );
	openInstance = api;
	if ( opts.tabs && opts.tabs.length ) { api.setTab( current ); }

	return api;
}

/** Close whatever dialog is open (no-op when there is none). */
export function closeDialog() {
	if ( openInstance ) { openInstance.close(); }
}

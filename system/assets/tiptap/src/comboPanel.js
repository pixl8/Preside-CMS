/**
 * The Format/Styles dropdown panel — an IFRAME, because that is the only way the
 * previews can be styled by the site's own content CSS.
 *
 * This is `CKEDITOR.ui.panel`'s framed mode, reproduced. Both combos register
 * with the same panel config:
 *
 *     panel:{ css:[ CKEDITOR.skin.getPath("editor") ].concat( config.contentsCss ), ... }
 *
 * and the panel constructor does `this.isFramed = this.forceIFrame || this.css.length`
 * — a non-empty `css` array IS what makes the panel an iframe. `getHolderElement()`
 * then writes `CKEDITOR.tools.buildStyleHtml( this.css )`, i.e. one
 * `<link rel=stylesheet>` per URL, into the panel document, and each entry is added
 * as `style.buildPreview()` — a literal `<h1>Heading 1</h1>` string. So the preview
 * is a REAL element styled by the BYTE-UNMODIFIED site stylesheet, in a document
 * with its own 16px root.
 *
 * ## Why not style previews in the host document (what this replaces)
 *
 * The previous version rendered the items into the admin page and injected a
 * rewritten copy of the content CSS scoped to `.tiptap-fmt-preview`. Three things
 * were wrong with that, and none of them is fixable by more specificity:
 *
 *  1. THE ADMIN'S OWN STYLESHEET REACHES THE PREVIEW. The preview element sits
 *     inside `.tiptap-editor-container` in the admin's document, so an admin/theme
 *     rule like `body main .tiptap-editor-container p{text-transform:uppercase}`
 *     — (0,2,2), and real admin CSS is full of these, plus `!important` — simply
 *     wins. This is the same fight the editable lost before it moved into a frame.
 *  2. `all: revert` on `.tiptap-fmt-preview *` is (0,1,1), so it beat any content
 *     rule of lower specificity — a `:where()`d rule, or anything in an `@layer`
 *     (layered rules lose to unlayered ones at ANY specificity).
 *  3. The rewriter had no branch for `@layer`/`@container`/`@scope` (no legacy
 *     numeric rule type), so those blocks were emitted UNSCOPED into the admin's
 *     own <head> — no preview styling, and a leak that restyled the admin UI.
 *
 * A frame removes all three by construction: nothing is rewritten, there is no
 * reset, and no rule from the page can reach in.
 *
 * ## Why an iframe and not a shadow root
 *
 * A shadow root would fix (1) and (3) but not (2)'s sibling problem: `rem` always
 * resolves against the DOCUMENT root, and the admin is `html{font-size:10px}`
 * (Ace/bootstrap), so a rem-based content sheet previewed at 62.5% of its size. A
 * shadow root is not a new root. `em` chains off it, and `vw`/media queries want a
 * viewport too. Only a separate document gives all of that — which is exactly why
 * the editable is in one (see editorFrame.js) and why the preview needs one too.
 *
 * The panel is body-portalled and positioned in viewport coordinates, like the
 * slash menu and the picker overlays: a capped-height or `overflow:hidden` field
 * would otherwise clip it.
 */
import { injectOwnStyle } from "./ownStyle.js";
import { injectFrameStyles } from "./presideStyles.js";
import { containerOf } from "./editorFrame.js";

const MAX_HEIGHT = 360;   // matches .tiptap-dropdown-menu's own cap
const MIN_WIDTH  = 190;
const GAP        = 3;

/**
 * Create a panel for one combo.
 *
 * `opts.stylesheets` is the field's content-CSS csv (cfg.stylesheets).
 * `opts.editor` is used for the container lookup (theme sync) only.
 *
 * Returns { body, open, close, isOpen, refit, destroy } where `body` is the
 * element to render items into — it lives in the frame's document, so items must
 * be created with `panel.doc`, not `document`.
 */
export function createComboPanel( opts ) {
	opts = opts || {};

	// BUILT LAZILY, on first open - as CKEditor's is: richCombo.createPanel() runs
	// from the click handler and calls the combo's own init() to fill it. It matters
	// more here than there: an admin form can carry several richeditor fields, and
	// eager creation meant an iframe and a stylesheet fetch per combo per field,
	// for panels most of which are never opened.
	let host = null, frame = null, doc = null, body = null;

	/**
	 * Which stylesheets does the preview need?
	 *
	 * Boxed: the field's configured content CSS - the same sheet the editing frame
	 * links, so a preview matches the editable.
	 *
	 * MODERN INLINE: there is no editing frame and the facade injects no content CSS
	 * at all, because the editable IS the site page and inherits the site's own
	 * stylesheets. A preview built from the admin-configured `stylesheets` would then
	 * be styled by a sheet that is NOT styling the editable - so the page's own
	 * sheets are used instead, which is the honest answer to "what will this look
	 * like". (CKEditor had no inline mode here, so there is no upstream behaviour to
	 * copy; the harvest in presideStyles.harvestSelectors() reads the same document
	 * for the same reason.)
	 */
	function sheetsCsv() {
		const editor    = opts.editor;
		const container = editor && editor.view && containerOf( editor.view.dom );
		if ( !container || !container.classList.contains( "tiptap-inline" ) ) { return opts.stylesheets; }

		const hrefs = [];
		document.querySelectorAll( 'link[rel~="stylesheet"][href]' ).forEach( function( l ) {
			const href = l.getAttribute( "href" );
			// Never our own chrome sheet: it is injected as cssText already, and
			// re-linking it would just be a second copy.
			if ( /tiptap(\.[A-Z0-9]+)?\.min\.css|tiptap\.css/i.test( href ) ) { return; }
			if ( hrefs.indexOf( href ) === -1 ) { hrefs.push( href ); }
		} );
		return hrefs.join( "," );
	}

	function build() {
		if ( host ) { return; }

		host = document.createElement( "div" );
		host.className = "tiptap-combo-panel";

		frame = document.createElement( "iframe" );
		frame.setAttribute( "title", opts.title || "" );
		frame.setAttribute( "frameborder", "0" );
		host.appendChild( frame );
		document.body.appendChild( host );

		// Same synchronous open/write/close as the editing frame: a freshly appended
		// srcless iframe is about:blank, same-origin and writable straight away, and
		// the document is not replaced afterwards.
		doc = frame.contentDocument;
		if ( !doc ) { throw new Error( "tiptap: combo panel document unavailable" ); }

		doc.open();
		doc.write(
			  '<!doctype html><html class="tiptap-combo-doc"><head><meta charset="utf-8">'
			// The panel's only reset. The body must not scroll horizontally (a long
			// preview should be clipped, not widen the panel) and owns no margin.
			+ '<style>html,body{margin:0;padding:0;background:transparent;overflow-x:hidden}</style>'
			+ '</head><body></body></html>'
		);
		doc.close();

		// Our own chrome CSS first (item padding, hover, group headers, the --tt-*
		// variables), then the site's content CSS UNMODIFIED - so a content rule wins
		// over our chrome defaults for the preview elements, which is the point.
		injectOwnStyle( doc.head, doc );

		body = doc.createElement( "div" );
		body.className = "tiptap-combo-list";
		doc.body.appendChild( body );

		// Late-arriving sheets change the previews' size, so a load re-measures.
		injectFrameStyles( doc, sheetsCsv(), function() { if ( isOpen() ) { refit(); } } );

		// The caller fills the list on first build (CKEditor's combo init()). Styles
		// refills on every open, since applicability depends on the caret.
		if ( opts.build ) { opts.build( doc, body ); }
	}

	function isOpen() { return !!host && host.classList.contains( "is-open" ); }

	/**
	 * Size the frame to its content and place it under the trigger.
	 *
	 * Renders before it positions - measuring an empty box is the slash menu's
	 * lesson: a full-length menu ended up off the bottom of the screen. Height is
	 * MEASURED because a frame is a replaced element and does not grow with its
	 * content (same rule as editorFrame.refit()).
	 */
	function refit() {
		const anchor = opts.anchor;
		if ( !host || !anchor || !anchor.isConnected ) { return; }

		// Measure with no cap applied, then clamp - and let the frame's own document
		// scroll past the cap.
		frame.style.height = "0px";
		const contentW = Math.max( body.scrollWidth, MIN_WIDTH );
		frame.style.width = contentW + "px";
		const contentH = body.scrollHeight;
		const h = Math.min( contentH, MAX_HEIGHT );
		frame.style.height = Math.ceil( h ) + "px";
		doc.documentElement.style.overflowY = contentH > MAX_HEIGHT ? "auto" : "hidden";
		// A scrollbar inside the frame eats width the previews were measured for.
		const w = contentH > MAX_HEIGHT ? contentW + 16 : contentW;
		frame.style.width = w + "px";

		const r  = anchor.getBoundingClientRect();
		const bw = w, bh = Math.ceil( h );

		// Below the trigger by preference, flipping above when that overflows the
		// viewport - the slash menu's rule, for the same reason.
		let top = r.bottom + GAP;
		if ( top + bh > window.innerHeight - 8 ) {
			const above = r.top - bh - GAP;
			top = above >= 8 ? above : Math.max( 8, window.innerHeight - bh - 8 );
		}
		// Left-aligned to the trigger, then clamped inside the viewport - never
		// centred (the lesson placeBubble() and the table bubble both arrived at).
		let left = r.left;
		if ( left + bw > window.innerWidth - 8 ) { left = Math.max( 8, window.innerWidth - bw - 8 ); }

		host.style.top  = Math.round( top ) + "px";
		host.style.left = Math.round( left ) + "px";
	}

	// The panel follows the EDITOR's theme, not the OS - it is outside the
	// container, so the `--tt-*` variables' scope does not reach it. Same reasoning
	// (and same single source of truth) as the slash menu: a dark OS must not put a
	// dark menu over a light editor, or over the site page in Modern inline mode.
	// The class goes on BOTH the host and the frame's root, because a class on the
	// host cannot cross the document boundary (theme.js hits this too).
	function syncTheme() {
		const editor = opts.editor;
		const container = editor && editor.view && containerOf( editor.view.dom );
		const dark = !!( container && container.classList.contains( "tiptap-dark" ) );
		host.classList.toggle( "tiptap-dark", dark );
		doc.documentElement.classList.toggle( "tiptap-dark", dark );
	}

	// ---- Staying put, and going away -----------------------------------------
	// A `fixed` panel is placed from the trigger's viewport rect, so it has to be
	// re-placed whenever that rect moves or it just hangs in space over unrelated
	// page content while the admin form scrolls away underneath it.
	let bound = null;

	function trackedDocs() {
		// The host, and the EDITING FRAME's document. Both are needed and for
		// different reasons: the host scrolls the admin form and receives clicks on
		// the page, while the frame receives every click in the editable - which
		// never reaches the host document at all. A host-only mousedown listener is
		// why clicking back into the editor did not close the panel (the same
		// boundary the slash menu's key handling hit).
		const docs   = [ document ];
		const editor = opts.editor;
		const edDoc  = editor && editor.view && editor.view.dom.ownerDocument;
		if ( edDoc && edDoc !== document ) { docs.push( edDoc ); }
		return docs;
	}

	function bind() {
		if ( bound ) { return; }
		const docs = trackedDocs();
		let queued = false;

		function onScrollOrResize() {
			if ( queued ) { return; }
			queued = true;
			( window.requestAnimationFrame || setTimeout )( function() {
				queued = false;
				if ( !isOpen() ) { return; }
				// Gone off screen with its trigger: a panel pointing at a control the
				// user can no longer see is chrome in the way, so it closes.
				const r = opts.anchor && opts.anchor.getBoundingClientRect();
				if ( !r || r.bottom < 0 || r.top > window.innerHeight ) { api.close(); return; }
				refit();
			} );
		}

		function onDown( e ) {
			// A click inside the panel is reported on the <iframe> ELEMENT in the host
			// document, so host.contains() covers it; clicks on the items themselves
			// happen inside the frame and are handled there.
			if ( host && host.contains( e.target ) ) { return; }
			if ( opts.anchorWrap && opts.anchorWrap.contains( e.target ) ) { return; }
			api.close();
		}

		// Capture phase, so a scroll in ANY host scroller is seen (scroll does not
		// bubble), and the frame's window for a field whose own content scrolls.
		document.addEventListener( "scroll", onScrollOrResize, true );
		window.addEventListener( "resize", onScrollOrResize );
		docs.forEach( function( d ) {
			d.addEventListener( "mousedown", onDown, true );
			if ( d !== document && d.defaultView ) { d.defaultView.addEventListener( "scroll", onScrollOrResize, { passive: true } ); }
		} );

		bound = function() {
			document.removeEventListener( "scroll", onScrollOrResize, true );
			window.removeEventListener( "resize", onScrollOrResize );
			docs.forEach( function( d ) {
				d.removeEventListener( "mousedown", onDown, true );
				if ( d !== document && d.defaultView ) { d.defaultView.removeEventListener( "scroll", onScrollOrResize ); }
			} );
		};
	}

	function unbind() { if ( bound ) { bound(); bound = null; } }

	const api = {
		  // Force the frame into existence and hand back its document, for a caller
		  // that fills the list per open (Styles) rather than once (Format).
		  ensure: function() { build(); return { doc: doc, body: body }; }

		, open: function() {
			build();
			syncTheme();
			host.classList.add( "is-open" );
			refit();
			bind();
		}

		, close: function() {
			unbind();
			if ( host ) { host.classList.remove( "is-open" ); }
			if ( opts.onClose ) { opts.onClose(); }
		}
		, isOpen: isOpen
		, refit : refit

		// The panel is on <body>, so it MUST be removed with the editor - Modern
		// inline mode destroys and recreates the editor on every save, and a leaked
		// panel per cycle is exactly the bug T18 covers for the slash menu.
		, destroy: function() {
			unbind();
			if ( host && host.parentNode ) { host.parentNode.removeChild( host ); }
			host = frame = doc = body = null;
		}

		// Does a click at this point belong to the panel? A click inside the panel is
		// reported on the <iframe> element itself.
		, contains: function( node ) { return !!host && host.contains( node ); }
	};

	return api;
}

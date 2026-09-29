/**
 * Smart image handling — drag-to-resize + alignment for the presideImage embed.
 *
 * CKEditor 4 offered no direct manipulation of an embedded image: every change
 * meant re-opening the picker dialog. This module adds corner drag handles and a
 * floating bubble toolbar over the selected image, and writes the result back
 * into the SAME `{{image:<urlenc-json>:image}}` token the picker produces — so
 * the stored markup, the server renderers and the picker forms are untouched.
 *
 * WHERE THE VALUES GO (Preside-CMS, do not "improve" these mappings):
 *   dimensions  "WxH" px string. `system/handlers/renderers/asset/Image.cfc`
 *               ::RichEditor turns it into an on-the-fly derivative "WxH-<quality>"
 *               (resize, maintainAspectRatio=true) — which is why dragging is
 *               ALWAYS proportional: a non-proportional height would be ignored.
 *   alignment   auto|left|right|center. `system/views/renderers/asset/image/
 *               richEditor.cfm` turns left/right into `float:` and center into
 *               `margin:… auto; display:block`.
 *   derivative  A NAMED derivative (only offered when a site configures
 *               derivatives with `inEditor=true`, hence usually absent).
 *               `ContentRendererService.renderEmbeddedImages` DELETES
 *               width/height/quality/dimensions whenever this is set to anything
 *               other than "none" — so a dragged size would be silently thrown
 *               away. Resizing therefore resets it to "none"; that is the one
 *               thing a drag overrides, and only on the sites that use it.
 *
 * PREVIEW REFRESH IS MANUAL, BY DESIGN. Committing a size does NOT re-request
 * the server preview: every distinct size asks Preside to generate and store a
 * new image derivative, so a drag would litter the asset store. Instead the
 * geometry is applied locally over the already-rendered HTML and a refresh
 * button appears in the middle of the image; the true derivative is rendered on
 * the next load (or when that button is clicked). "Locally applied" is derived,
 * not flagged: `renderedGeom` records the geometry the visible HTML was rendered
 * for, so undo/redo back to the rendered state clears the stale marker by itself.
 *
 * BYTE FIDELITY: the token is only ever rebuilt when the user actually changes
 * something. Parsing and re-serialising an untouched token would reformat the
 * JSON and break getData()'s byte-for-byte match with CKEditor.
 */
import { t } from "./i18n.js";
import { ICONS } from "./icons.js";
import { focusEditable } from "./editorFocus.js";
import { bubbleButton, placeBubble as placeBubbleAt } from "./embedBubble.js";
import { postForm } from "./presidePickerModal.js";

const TOKEN_RE  = /^\{\{image:([\s\S]*):image\}\}$/;
const MIN_WIDTH = 32;
const PRESETS   = [ 25, 50, 100 ];
// The three keys this module writes. A change confined to them is handled locally -
// no preview re-request. Anything else (a picker edit: different asset, caption,
// spacing, link, …) needs the server to re-render.
const LOCAL_KEYS = [ "dimensions", "alignment", "derivative" ];
// ...but only these make the ALREADY-RENDERED html wrong, i.e. mark it stale and
// offer the refresh button. `alignment` is deliberately absent: we always apply it
// ourselves, onto the wrapper (see applyAlignment), so the server's own rendering of
// it is inert here and re-requesting for an alignment change would achieve nothing.
const STALE_KEYS = [ "dimensions", "derivative" ];

// Original asset dimensions, keyed by asset id. The endpoint reads the asset
// BINARY to measure it, so it is only ever called on demand ("Original size").
const originalSizes = {};

// Opt out per site/field with defaultConfigs.imageTools = false, matching the
// wordcount / outline / darkMode opt-outs.
export function imageToolsEnabled( cfg ) {
	return !!cfg && ( ( cfg.defaultConfigs || {} ).imageTools !== false );
}

export function parseImageConfig( raw ) {
	const m = String( raw || "" ).match( TOKEN_RE );
	if ( !m ) { return null; }
	try {
		const cfg = JSON.parse( decodeURIComponent( m[ 1 ] ) );
		return ( cfg && typeof cfg === "object" && !Array.isArray( cfg ) ) ? cfg : null;
	} catch ( e ) { return null; }
}

// Mirrors the picker's own commit (core dialogEventListeners.js):
// encodeURIComponent( serializeJSON( form ) ).
export function buildImageToken( config ) {
	return "{{image:" + encodeURIComponent( JSON.stringify( config ) ) + ":image}}";
}

function parseDimensions( config ) {
	const parts = String( ( config && config.dimensions ) || "" ).split( /x/i );
	const w = parseInt( parts[ 0 ], 10 );
	const h = parseInt( parts[ 1 ], 10 );
	return w > 0 ? { w: w, h: h > 0 ? h : 0 } : null;
}

// Empty, "auto" and "none" all mean "no explicit value" to the server renderers, so
// they must compare equal - otherwise clicking an alignment off (which writes the
// picker's own "auto") would leave the preview marked stale forever.
function geometryKey( config ) {
	config = config || {};
	return STALE_KEYS.map( function( k ) {
		const v = String( config[ k ] == null ? "" : config[ k ] ).toLowerCase();
		return ( v === "auto" || v === "none" ) ? "" : v;
	} ).join( "|" );
}

// Stable stringify of everything EXCEPT the keys this module writes, so two configs
// can be compared for "did anything only the server can render change?".
function nonLocalKey( config ) {
	config = config || {};
	return Object.keys( config ).filter( k => LOCAL_KEYS.indexOf( k ) === -1 ).sort()
		.map( k => k + "=" + String( config[ k ] == null ? "" : config[ k ] ) ).join( "&" );
}

function clamp( v, min, max ) { return v < min ? min : ( v > max ? max : v ); }

/**
 * Mount the tools over one image node view.
 *
 * ctx: { dom, frame, preview, node, editor, getPos, buildAjaxLink, refresh, openPicker }
 *   dom      the node view's outer element (.img-placeholder) — carries alignment
 *   frame    the position:relative shrink-wrapper around the preview
 *   preview  the element whose innerHTML is the server-rendered image
 *   refresh  () => Promise, re-requests the server preview
 *
 * Returns null when the token cannot be parsed (unknown/legacy shape — left
 * strictly alone), otherwise the hooks the node view delegates to.
 */
export function attachImageTools( ctx ) {
	let config = parseImageConfig( ctx.node.attrs.raw );
	if ( !config ) { return null; }

	let node        = ctx.node;
	let renderedGeom = geometryKey( config );   // geometry the visible HTML was rendered for
	let session     = null;                    // in-flight drag
	let selected    = false;

	const editor = ctx.editor;

	// ---- Chrome ------------------------------------------------------------
	const chrome = document.createElement( "div" );
	chrome.className = "tiptap-image-tools";

	[ "tl", "tr", "bl", "br" ].forEach( function( dir ) {
		const h = document.createElement( "span" );
		h.className = "tiptap-image-handle is-" + dir;
		h.title = t( "image.resize" );
		h.addEventListener( "pointerdown", e => beginResize( e, dir ) );
		h.addEventListener( "pointermove", onPointerMove );
		h.addEventListener( "pointerup",   e => endResize( e, true ) );
		h.addEventListener( "pointercancel", e => endResize( e, false ) );
		chrome.appendChild( h );
	} );

	const badge = document.createElement( "span" );
	badge.className = "tiptap-image-size";
	chrome.appendChild( badge );

	const bubble = document.createElement( "div" );
	// Both classes: `tiptap-embed-bubble` is the shared chrome (also the
	// widget/attachment bubble), `tiptap-image-bubble` carries the image-only extras.
	bubble.className = "tiptap-embed-bubble tiptap-image-bubble";

	const alignBtns = {};
	[ [ "left", "JustifyLeft" ], [ "center", "JustifyCenter" ], [ "right", "JustifyRight" ] ].forEach( function( pair ) {
		const b = bubbleButton( "tiptap-image-align", ICONS[ pair[ 1 ] ], t( "image.align." + pair[ 0 ] ) );
		// Clicking the active alignment clears it back to "auto" (the picker's
		// default), so the three buttons cover all four states.
		b.addEventListener( "click", () => setAlignment( currentAlignment() === pair[ 0 ] ? "auto" : pair[ 0 ] ) );
		alignBtns[ pair[ 0 ] ] = b;
		bubble.appendChild( b );
	} );

	bubble.appendChild( separator() );

	PRESETS.forEach( function( pct ) {
		const b = bubbleButton( "tiptap-image-preset", "", t( "image.size.percent", { count: pct } ), pct + "%" );
		b.addEventListener( "click", () => setWidth( Math.round( maxWidth() * pct / 100 ) ) );
		bubble.appendChild( b );
	} );

	const originalBtn = bubbleButton( "tiptap-image-original", ICONS.AspectRatio, t( "image.size.original" ) );
	originalBtn.addEventListener( "click", useOriginalSize );
	bubble.appendChild( originalBtn );

	bubble.appendChild( separator() );

	const editBtn = bubbleButton( "tiptap-image-edit", ICONS.Pencil, t( "image.edit" ) );
	editBtn.addEventListener( "click", () => ctx.openPicker() );
	bubble.appendChild( editBtn );

	const removeBtn = bubbleButton( "tiptap-image-remove", ICONS.Trash, t( "image.remove" ) );
	removeBtn.addEventListener( "click", removeNode );
	bubble.appendChild( removeBtn );

	// Centre refresh: only present while the preview is out of date (see the
	// header note on why re-rendering is manual).
	const refreshBtn = bubbleButton( "tiptap-image-refresh", ICONS.Refresh, t( "image.refresh" ) );
	refreshBtn.addEventListener( "click", function() {
		// It covers the middle of the image, so a click aimed at the image lands here
		// instead of selecting the node. Select as well as refresh, so that click is
		// never a dead end.
		selectSelf();
		refreshBtn.classList.add( "is-busy" );
		Promise.resolve( ctx.refresh() ).then( done, done );
		function done() { refreshBtn.classList.remove( "is-busy" ); }
	} );

	ctx.frame.appendChild( chrome );
	ctx.frame.appendChild( bubble );
	ctx.frame.appendChild( refreshBtn );

	function separator() {
		const s = document.createElement( "span" );
		s.className = "tiptap-toolbar-sep";
		return s;
	}

	function selectSelf() {
		const pos = typeof ctx.getPos === "function" ? ctx.getPos() : null;
		if ( pos != null && pos >= 0 ) { editor.commands.setNodeSelection( pos ); }
	}

	// ---- Reading the current state -----------------------------------------
	function previewImg() { return ctx.preview.querySelector( "img" ); }
	function currentAlignment() {
		const a = String( config.alignment || "" ).toLowerCase();
		return a === "left" || a === "right" || a === "center" ? a : "auto";
	}
	function maxWidth() {
		const w = editor.view && editor.view.dom ? editor.view.dom.clientWidth : 0;
		return w > MIN_WIDTH ? w : 1200;
	}
	// The rendered preview is a derivative, so its natural size is the CURRENT
	// size — but its aspect ratio is the original's (the derivative resize keeps
	// it), which is all a proportional drag needs.
	function aspect() {
		const img = previewImg();
		if ( img && img.naturalWidth > 0 && img.naturalHeight > 0 ) { return img.naturalWidth / img.naturalHeight; }
		const d = parseDimensions( config );
		return ( d && d.w && d.h ) ? d.w / d.h : 0;
	}
	function currentWidth() {
		const d = parseDimensions( config );
		if ( d ) { return d.w; }
		const img = previewImg();
		return img ? ( img.getBoundingClientRect().width || img.naturalWidth || 0 ) : 0;
	}

	// ---- Writing back -------------------------------------------------------
	function commit( changes ) {
		const pos = typeof ctx.getPos === "function" ? ctx.getPos() : null;
		if ( pos == null || pos < 0 ) { return; }

		const next = Object.assign( {}, config, changes );
		const tr   = editor.state.tr.setNodeMarkup( pos, undefined, Object.assign( {}, node.attrs, {
			raw: buildImageToken( next )
		} ) );
		editor.view.dispatch( tr );
	}

	// `overflow` lifts the editable-width cap. Dragging and the % presets are
	// gestures made RELATIVE to the editor, so they cap there; "Original size" is a
	// request for a specific real size and must not be quietly reduced to whatever
	// the admin editor happens to be wide (the site's layout may well be wider).
	// Oversized images still display capped, via max-width:100% in the css.
	function setWidth( width, overflow ) {
		const ar = aspect();
		const w  = Math.round( clamp( width, MIN_WIDTH, overflow ? Infinity : maxWidth() ) );
		const h  = ar ? Math.round( w / ar ) : ( parseDimensions( config ) || {} ).h || 0;

		// Image.cfc::RichEditor requires `ListLen( dimensions, "x" ) == 2`, so a bare
		// width would be silently ignored server-side. If the aspect ratio is unknown
		// (image not loaded, no height in the token) leave the token alone rather than
		// write a value that does nothing.
		if ( !h ) { return; }

		const changes = { dimensions: w + "x" + h };
		// A named derivative would make the server discard `dimensions` outright.
		if ( config.derivative && String( config.derivative ) !== "none" ) { changes.derivative = "none"; }
		commit( changes );
	}

	function setAlignment( alignment ) { commit( { alignment: alignment } ); }

	function useOriginalSize() {
		const assetId = String( config.asset || "" );
		if ( !assetId ) { return; }
		if ( originalSizes[ assetId ] ) { return setWidth( originalSizes[ assetId ].w, true ); }

		originalBtn.classList.add( "is-busy" );
		postForm( ctx.buildAjaxLink( "assetmanager.getImageDetailsForCKEditorImageDialog" ), { asset: assetId } )
			.then( r => r.json() )
			.then( function( data ) {
				// CFML serialises struct keys upper-cased (core formBehaviour.js reads
				// data.WIDTH the same way).
				const w = parseInt( data.WIDTH  || data.width  || 0, 10 );
				const h = parseInt( data.HEIGHT || data.height || 0, 10 );
				if ( w > 0 ) {
					originalSizes[ assetId ] = { w: w, h: h };
					setWidth( w, true );
				}
			} )
			.catch( function() {} )
			.then( () => originalBtn.classList.remove( "is-busy" ) );
	}

	function removeNode() {
		const pos = typeof ctx.getPos === "function" ? ctx.getPos() : null;
		if ( pos == null || pos < 0 ) { return; }
		focusEditable( editor ).chain().focus().deleteRange( { from: pos, to: pos + node.nodeSize } ).run();
	}

	// ---- Alignment + spacing ------------------------------------------------
	// ALWAYS applied, and always COMPUTED FROM THE TOKEN - never only while stale, and
	// never read back off the rendered HTML.
	//
	// Why the wrapper at all: richEditor.cfm puts `float:left/right` (or centring
	// auto-margins) and the spacing margins on the rendered element itself, and those
	// are inert inside the frame that shrink-wraps the preview - there is no room to
	// float in a box that is exactly the image's width. CKEditor hit the same wall and
	// solved it by copying the rendered image's styles onto its widget wrapper
	// (addEmbeddedImageStylesToWidgetWrapper).
	//
	// Why computed and not copied: the rendered HTML is only ever as fresh as the last
	// render, and a stored `center` renders `margin:Xpx auto` - so copying gave the
	// wrong side spacing to an image re-aligned left/right before a refresh. Deriving
	// from the token is exact in every state. The css zeroes the rendered element's own
	// float/margins so the two cannot fight.
	//
	// Mirrors richEditor.cfm exactly:
	//   spacing.<side> = Val( spacing_<side> ?: spacing ?: 0 )
	//   center -> margin: t auto b auto (i.e. NO horizontal spacing), display:block
	//   else   -> float + margin: t r b l
	function spacingPx( side ) {
		const own = config[ "spacing_" + side ];
		const raw = ( own === undefined || own === null || own === "" ) ? config.spacing : own;
		const n   = parseFloat( raw );
		return ( isFinite( n ) && n > 0 ) ? n : 0;
	}

	function applyAlignment() {
		const align = currentAlignment();
		ctx.dom.setAttribute( "data-tt-align", align );

		const centred = align === "center";
		ctx.dom.style.margin = spacingPx( "top" ) + "px "
			+ ( centred ? 0 : spacingPx( "right" ) ) + "px "
			+ spacingPx( "bottom" ) + "px "
			+ ( centred ? 0 : spacingPx( "left" ) ) + "px";
	}

	// ---- Local geometry -----------------------------------------------------
	// The SIZE override is applied only while the token's geometry differs from what
	// the visible HTML was rendered for; when it matches, the override is removed so
	// the image is exactly what the server produced (the derivative's own natural
	// size). Alignment is not part of this - see applyAlignment().
	function applyLocalGeometry() {
		const stale = geometryKey( config ) !== renderedGeom;
		const img   = previewImg();
		const fig   = ctx.preview.querySelector( "figure" );

		ctx.dom.classList.toggle( "has-local-geometry", stale );
		refreshBtn.hidden = !stale;
		applyAlignment();

		const d = stale ? parseDimensions( config ) : null;
		if ( img ) { img.style.width = d ? ( d.w + "px" ) : ""; img.style.height = d ? "auto" : ""; }
		if ( fig ) { fig.style.maxWidth = d ? ( d.w + "px" ) : ""; }
		placeBubble();
	}

	// Placement is shared with the widget/attachment bubble (src/embedBubble.js):
	// anchored to the embed's left edge, clamped inside the editable, above unless
	// there is no room. The reasoning for each of those is documented there.
	function placeBubble() {
		if ( !selected ) { return; }
		placeBubbleAt( bubble, ctx.frame, editor );
	}

	function syncButtons() {
		const a = currentAlignment();
		Object.keys( alignBtns ).forEach( k => alignBtns[ k ].classList.toggle( "is-active", k === a ) );
		originalBtn.disabled = !config.asset;
	}

	// ---- Resizing -----------------------------------------------------------
	function beginResize( e, dir ) {
		if ( !e.isPrimary || ( e.pointerType === "mouse" && e.button !== 0 ) ) { return; }
		e.preventDefault();
		e.stopPropagation();

		selectSelf();
		const width = currentWidth() || maxWidth();
		session = { id: e.pointerId, x: e.clientX, w: width, sign: dir.indexOf( "l" ) === -1 ? 1 : -1, ar: aspect() };
		try { e.currentTarget.setPointerCapture( e.pointerId ); } catch ( err ) {}
		ctx.dom.classList.add( "is-resizing" );
		paint( width );
	}

	function onPointerMove( e ) {
		if ( !session || session.id !== e.pointerId ) { return; }
		e.preventDefault();
		e.stopPropagation();
		session.last = clamp( Math.round( session.w + ( e.clientX - session.x ) * session.sign ), MIN_WIDTH, maxWidth() );
		paint( session.last );
	}

	function endResize( e, apply ) {
		if ( !session || session.id !== e.pointerId ) { return; }
		e.preventDefault();
		e.stopPropagation();

		const width = session.last;
		try { if ( e.currentTarget.hasPointerCapture( e.pointerId ) ) { e.currentTarget.releasePointerCapture( e.pointerId ); } } catch ( err ) {}
		session = null;
		ctx.dom.classList.remove( "is-resizing" );
		badge.textContent = "";

		// Only one history entry per drag: the live feedback above is plain DOM,
		// the token is written once, here.
		if ( apply && width ) { setWidth( width ); }
		else { applyLocalGeometry(); }
	}

	// Live feedback during a drag — deliberately NOT a transaction.
	function paint( width ) {
		const img = previewImg();
		const ar  = session ? session.ar : aspect();
		const h   = ar ? Math.round( width / ar ) : 0;
		if ( img ) { img.style.width = width + "px"; img.style.height = "auto"; }
		const fig = ctx.preview.querySelector( "figure" );
		if ( fig ) { fig.style.maxWidth = width + "px"; }
		badge.textContent = h ? ( width + " × " + h ) : String( width );
	}

	applyLocalGeometry();
	syncButtons();

	// ---- Node view hooks ----------------------------------------------------
	return {
		// True = handled locally, the caller must NOT re-request the preview.
		update: function( newNode ) {
			const next = parseImageConfig( newNode.attrs.raw );
			node = newNode;
			if ( !next ) { return false; }

			const wasLocalOnly = nonLocalKey( next ) === nonLocalKey( config );
			config = next;
			applyLocalGeometry();
			syncButtons();
			return wasLocalOnly;
		},

		// Called after the server preview has been (re)injected: the visible HTML
		// now matches the token's geometry, so nothing is stale.
		previewLoaded: function() {
			renderedGeom = geometryKey( config );
			applyLocalGeometry();
			syncButtons();
		},

		selectNode: function() {
			selected = true;
			ctx.dom.classList.add( "is-selected" );
			placeBubble();
		},

		deselectNode: function() {
			selected = false;
			ctx.dom.classList.remove( "is-selected" );
		},

		// Our chrome owns its own pointer/click handling; everything else (a click
		// on the image itself) still reaches ProseMirror so the node gets selected.
		ownsEvent: function( e ) {
			return !!( e.target && e.target.closest && e.target.closest( ".tiptap-image-tools,.tiptap-embed-bubble,.tiptap-image-refresh" ) );
		},

		isSelected: function() { return selected; }
	};
}

/**
 * Zero-dependency static + mock server for the editor harness.
 *
 * Serves both editors standalone with Preside's server-side dependencies mocked:
 *   /ckeditor.html   - the real Preside CKEditor 4 + ckeditorExtensions plugins
 *   /tiptap.html     - the Tiptap facade (dist/)
 *   /                - index / chooser
 *
 * Aliases into the Preside-CMS tree so the real editor assets load unchanged:
 *   /ckeditor/*           -> system/assets/ckeditor/*
 *   /ckeditorExtensions/* -> system/assets/ckeditorExtensions/*
 *   /vendor/jquery.js     -> system/assets/js/admin/lib/jquery-2.2.5-sec.js
 *   /vendor/*.js          -> system/assets/js/admin/presidecore/*
 *   /dist/*               -> ../dist/* (built Tiptap bundles)
 *
 * Mock endpoints (stand in for the Preside handlers the plugins call):
 *   /mock/ajax?action=... - preview renderers (image/attachment/widget)
 *   /mock/admin/*         - picker iframe pages + temporarilyStoreData
 *
 * Usage: node server.mjs [port]   (default 8700)
 */
import http from "node:http";
import { readFile } from "node:fs/promises";
import { existsSync, readdirSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname   = path.dirname( fileURLToPath( import.meta.url ) );
const MODULE_DIR  = path.resolve( __dirname, ".." );                 // system/assets/tiptap
// Preside core assets (jquery/presidecore/ckeditor for the comparison pane).
// Defaults to this checkout's system/assets; override with PRESIDE_ASSETS.
const PRESIDE_ASSETS = process.env.PRESIDE_ASSETS || path.resolve( __dirname, "../.." );
const PORT = Number( process.argv[ 2 ] || 8700 );

const TYPES = {
	  ".html": "text/html; charset=utf-8"
	, ".js"  : "text/javascript; charset=utf-8"
	, ".mjs" : "text/javascript; charset=utf-8"
	, ".css" : "text/css; charset=utf-8"
	, ".json": "application/json; charset=utf-8"
	, ".map" : "application/json; charset=utf-8"
	, ".png" : "image/png"
	, ".gif" : "image/gif"
	, ".svg" : "image/svg+xml"
	, ".ico" : "image/x-icon"
};

function ctype( p ) { return TYPES[ path.extname( p ).toLowerCase() ] || "application/octet-stream"; }

async function sendFile( res, filePath ) {
	try {
		const body = await readFile( filePath );
		res.writeHead( 200, { "Content-Type": ctype( filePath ) } );
		res.end( body );
	} catch ( e ) {
		res.writeHead( 404, { "Content-Type": "text/plain" } );
		res.end( "Not found: " + filePath );
	}
}

function send( res, status, type, body ) {
	res.writeHead( status, { "Content-Type": type } );
	res.end( body );
}

// ---- Sample data shared by the pickers + preview renderers ------------------
const WIDGET_NAMES = { featurednews: "Featured news", relatedlinks: "Related links", calltoaction: "Call to action", mywidget: "My widget" };
const PALETTE = [ "#dbeafe", "#dcfce7", "#fee2e2", "#fef9c3", "#f3e8ff" ];

const PICKER_CHOICES = {
	link: [
		  { label: "Page: Home",             data: { type: "sitetreelink", page: "PAGE-HOME",  defaultText: "Home" } }
		, { label: "Page: About us",         data: { type: "sitetreelink", page: "PAGE-ABOUT", defaultText: "About us" } }
		, { label: "Asset: brochure.pdf",    data: { type: "asset", asset: "ASSET-DOC-1", defaultText: "Download brochure" } }
		, { label: "External: example.com",  data: { type: "url", protocol: "https://", address: "example.com", link_target: "_blank", defaultText: "example.com" } }
		, { label: "Email: hello@example.com", data: { type: "email", emailaddress: "hello@example.com", defaultText: "hello@example.com" } }
	],
	image: [
		  { label: "Hero banner",  color: PALETTE[0], raw: imageToken( "ASSET-IMG-1", "Hero banner" ) }
		, { label: "Team photo",   color: PALETTE[1], raw: imageToken( "ASSET-IMG-2", "Team photo" ) }
		, { label: "Product shot", color: PALETTE[2], raw: imageToken( "ASSET-IMG-3", "Product shot" ) }
	],
	attachment: [
		  { label: "brochure.pdf",   raw: attachmentToken( "ASSET-DOC-1", "brochure.pdf" ) }
		, { label: "price-list.xlsx", raw: attachmentToken( "ASSET-DOC-2", "price-list.xlsx" ) }
		, { label: "terms.docx",     raw: attachmentToken( "ASSET-DOC-3", "terms.docx" ) }
	],
	widget: [
		  { label: "Featured news",   raw: widgetToken( "featurednews", { count: 3 } ) }
		, { label: "Related links",   raw: widgetToken( "relatedlinks", { max: 5 } ) }
		, { label: "Call to action",  raw: widgetToken( "calltoaction", { style: "primary" } ) }
	]
};

// Shaped like a real picker commit (core dialogEventListeners.js serialises the
// WHOLE richeditor.image form), so the image tools get the same key set to edit.
function imageToken( asset, alt ) {
	return "{{image:" + encodeURIComponent( JSON.stringify( {
		  asset: asset, asset_alt: "", alt_text: alt, alignment: "", derivative: "none"
		, dimensions: "480x270", quality: "highestPerformance"
		, spacing_top: "5", spacing_right: "5", spacing_bottom: "5", spacing_left: "5"
		, copyright: "", caption: "", link: "", link_asset: "", link_page: "", link_target: "_self"
	} ) ) + ":image}}";
}
function attachmentToken( asset, name ) { return "{{attachment:" + encodeURIComponent( JSON.stringify( { asset: asset, name: name } ) ) + ":attachment}}"; }
function widgetToken( id, cfg ) { return "{{widget:" + id + ":" + encodeURIComponent( JSON.stringify( cfg ) ) + ":widget}}"; }

function esc( s ) { return String( s == null ? "" : s ).replace( /&/g, "&amp;" ).replace( /</g, "&lt;" ).replace( />/g, "&gt;" ).replace( /"/g, "&quot;" ); }
function decodeConfig( s ) { try { return JSON.parse( decodeURIComponent( s ) ); } catch ( e ) { return {}; } }
function parseEmbed( token, re ) { const m = String( token || "" ).match( re ); return m ? decodeConfig( m[ 1 ] ) : {}; }
function colorFor( seed ) { let h = 0; seed = String( seed ); for ( let i = 0; i < seed.length; i++ ) { h = ( h * 31 + seed.charCodeAt( i ) ) >>> 0; } return PALETTE[ h % PALETTE.length ]; }
function imgSvg( label, color, width, height ) {
	const w = width  || 160;
	const h = height || 90;
	const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="${w}" height="${h}" fill="${color}"/><text x="${Math.round( w / 2 )}" y="${Math.round( h / 2 )}" font-family="sans-serif" font-size="13" fill="#123" text-anchor="middle">${esc( label )}</text></svg>`;
	return "data:image/svg+xml;base64," + Buffer.from( svg ).toString( "base64" );
}
function summarise( cfg ) { return Object.keys( cfg ).map( k => k + ": " + cfg[ k ] ).join( ", " ); }

// Mirrors Preside-CMS system/views/renderers/asset/image/richEditor.cfm closely
// enough to exercise the editor's image tools: `dimensions` ("WxH") sizes the img,
// `alignment` becomes float / centred margins, and spacing_* becomes margins - so
// what the mock sends back is what a committed token really renders as.
function renderMockImage( cfg, label ) {
	const dims  = String( cfg.dimensions || "" ).split( /x/i );
	const w     = parseInt( dims[ 0 ], 10 ) || 0;
	const h     = parseInt( dims[ 1 ], 10 ) || 0;
	const align = String( cfg.alignment || "" ).toLowerCase();
	const sp    = k => Number( cfg[ "spacing_" + k ] || 0 ) || 0;

	let style = "";
	if ( align === "left" || align === "right" ) { style += `float:${align};`; }
	if ( align === "center" ) { style += `margin:${sp("top")}px auto ${sp("bottom")}px auto;display:block;`; }
	else { style += `margin:${sp("top")}px ${sp("right")}px ${sp("bottom")}px ${sp("left")}px;`; }
	if ( w ) { style += `width:${w}px;`; }

	// The real renderer serves a derivative generated AT the requested size, so the
	// mock svg is generated at that size too (its natural size is what the editor
	// reads the aspect ratio from).
	const src = imgSvg( label, colorFor( cfg.asset || label ), w || 320, h || 180 );
	const img = `<img src="${src}" alt="${esc( label )}" />`;

	// richEditor.cfm moves the style onto the <figure> when there is a caption or
	// copyright, and onto the wrapping <a> when there is a link - so the element
	// carrying float/margins is not always the img. The editor's css zeroes
	// `.tiptap-embed-preview > *` for exactly that reason; render all three shapes so
	// the harness actually exercises it.
	const hasFigure = !!( String( cfg.copyright || "" ).trim() || String( cfg.caption || "" ).trim() );
	const link      = String( cfg.link || cfg.link_asset || cfg.link_page || "" ).trim();

	if ( hasFigure ) {
		const maxW = w ? `max-width:${w}px;` : "";
		const inner = link ? `<a href="#">${img}</a>` : img;
		return `<figure style="${style}${maxW}">${inner}<figcaption>`
			+ ( cfg.copyright ? `<small class="copyright">&copy; ${esc( cfg.copyright )}</small>` : "" )
			+ ( cfg.caption ? esc( cfg.caption ) : "" )
			+ `</figcaption></figure>`;
	}
	if ( link ) {
		return `<a href="#" style="display:block;${style}">${img}</a>`;
	}
	return `<img src="${src}" alt="${esc( label )}" style="${style}" />`;
}

// ---- Mock preview renderers (what the CKEditor/Tiptap widgets fetch) --------
// Reflects the picked asset/widget so different choices render differently.
function mockAjax( action, body ) {
	body = body || new URLSearchParams();
	switch ( action ) {
		case "assetManager.renderEmbeddedImageForEditor": {
			const cfg = parseEmbed( body.get( "embeddedImage" ), /^\{\{image:(.*):image\}\}$/ );
			const label = cfg.alt_text || cfg.asset || "image";
			return renderMockImage( cfg, label );
		}
		case "assetManager.renderEmbeddedAttachmentForEditor": {
			const cfg = parseEmbed( body.get( "embeddedAttachment" ), /^\{\{attachment:(.*):attachment\}\}$/ );
			// A REAL download href, as Preside's renderer emits: this is what made
			// clicking an attachment inside the editor download the file. With the
			// `href="#"` this used to have, that bug could not show up in the harness.
			const href = "/mock/asset/" + encodeURIComponent( cfg.asset || "doc" )
			           + "/" + encodeURIComponent( cfg.name || "document" );
			return `<a href="${esc( href )}">&#128206; ${esc( cfg.name || cfg.asset || "document" )}</a>`;
		}
		// Read by the image tools' "Original size" button (real handler measures the
		// asset binary; upper-cased keys because CFML serialises struct keys that way).
		case "assetmanager.getImageDetailsForCKEditorImageDialog": {
			const cfg = { asset: body.get( "asset" ) || "" };
			return JSON.stringify( { WIDTH: 1200, HEIGHT: 675, LABEL: cfg.asset, ALT_TEXT: "" } );
		}
		case "widgets.renderWidgetPlaceholder": {
			const id = body.get( "widgetId" ) || "widget";
			const summary = summarise( decodeConfig( body.get( "data" ) ) );
			return `<strong>${esc( WIDGET_NAMES[ id ] || id )}</strong>` + ( summary ? ` <span class="config-summary">(${esc( summary )})</span>` : "" );
		}
		default:
			return `<em>[mock:${esc( action )}]</em>`;
	}
}

// ---- Mock picker iframe page (speaks the onDialogEvent contract) ------------
// Offers a few selectable sample items; click to select, double-click or OK to commit.
function mockPicker( kind ) {
	const choices = PICKER_CHOICES[ kind ] || [];
	return `<!doctype html><html><head><meta charset="utf-8"><title>mock ${kind} picker</title>
<style>
	body{font-family:sans-serif;padding:16px;color:#333}
	h3{margin:0 0 4px}.hint{color:#777;font-size:12px;margin:0 0 14px}
	#grid{display:flex;flex-wrap:wrap;gap:10px}
	.card{border:1px solid #ccc;border-radius:6px;padding:8px;width:150px;cursor:pointer;background:#fff}
	.card:hover{border-color:#888}
	.card.sel{border-color:#1a7f5a;box-shadow:0 0 0 2px #b8e6d3}
	.thumb{height:60px;border-radius:4px;margin-bottom:6px}
	.lbl{font-size:13px}
</style>
</head><body>
<h3>Mock ${esc( kind )} picker</h3>
<p class="hint">Stands in for the real Preside admin picker. Click an item then OK (or double-click).</p>
<div id="grid"></div>
<script>
var KIND = ${JSON.stringify( kind )};
var CHOICES = ${JSON.stringify( choices )};
var selected = null, parentDialog = null;

var grid = document.getElementById("grid");
CHOICES.forEach(function( c, i ){
	var card = document.createElement("div");
	card.className = "card";
	if ( c.color ) { var t = document.createElement("div"); t.className = "thumb"; t.style.background = c.color; card.appendChild(t); }
	var lbl = document.createElement("div"); lbl.className = "lbl"; lbl.textContent = c.label; card.appendChild(lbl);
	card.addEventListener("click", function(){ select(i); });
	card.addEventListener("dblclick", function(){ select(i); if ( parentDialog && parentDialog.click ) parentDialog.click("ok"); });
	grid.appendChild(card);
});
function select( i ){
	selected = CHOICES[i];
	for ( var j=0; j<grid.children.length; j++ ) grid.children[j].classList.toggle("sel", j===i);
	if ( parentDialog && parentDialog.enableButton ) parentDialog.enableButton("ok");
}

// The parent CKEditor/Tiptap dialog forwards load/ok/cancel to this global.
window.onDialogEvent = function( e, dialog ){
	switch ( (e && e.name) || "" ){
		case "load":
			parentDialog = dialog;
			if ( dialog && dialog.disableButton ) dialog.disableButton("ok"); // enabled once something is picked
			break;
		case "ok":
			if ( !selected ) return false; // nothing chosen — keep the dialog open
			if ( KIND === "link" ) {
				if ( dialog._plugin && dialog._plugin.updateLink ) dialog._plugin.updateLink( selected.data, dialog );
			} else {
				var el = dialog.getContentElement("iframe");
				el._config = el._widgetConfig = selected.raw;
				dialog.commitContent();
			}
			return true;
	}
	return true;
};
</script>
</body></html>`;
}

function readBody( req ) {
	return new Promise( function( resolve ) {
		let data = "";
		req.on( "data", function( c ) { data += c; } );
		req.on( "end", function() { resolve( new URLSearchParams( data ) ); } );
		req.on( "error", function() { resolve( new URLSearchParams() ); } );
	} );
}

const server = http.createServer( async ( req, res ) => {
	// Parse the RAW url ourselves. `new URL("//ckeditorExtensions/...")` would treat
	// the leading "//" as a protocol-relative host and eat the first path segment;
	// ckeditorExtensions/config.js emits exactly such a "//ckeditorExtensions/" path
	// when the CKEditor basePath is root-relative.
	const qIndex   = req.url.indexOf( "?" );
	const rawPath  = qIndex >= 0 ? req.url.slice( 0, qIndex ) : req.url;
	const search   = qIndex >= 0 ? req.url.slice( qIndex + 1 ) : "";
	const params   = new URLSearchParams( search );
	let p = decodeURIComponent( rawPath ).replace( /\/{2,}/g, "/" );

	// Mock: preview renderers (POST body carries the token / widget config to reflect)
	if ( p === "/mock/ajax" ) {
		const body = await readBody( req );
		return send( res, 200, "text/html; charset=utf-8", mockAjax( params.get( "action" ) || "", body ) );
	}
	// Mock: frontend-editing save/publish flow (test-frontend-inline.html).
	// Mirrors admin.FrontendEditing.saveAction / getPublishPrompt / publishAction
	// closely enough to exercise core's saveContent()/publishChanges() contract:
	// save echoes the posted content back as the freshly-rendered region.
	if ( p === "/mock/frontend/save" ) {
		const body = await readBody( req );
		return send( res, 200, "application/json", JSON.stringify( {
			  success : true
			, message : "Content saved (mock)"
			, rendered: body.get( "content" ) || ""
		} ) );
	}
	if ( p === "/mock/frontend/publishPrompt" ) {
		await readBody( req );
		return send( res, 200, "application/json", JSON.stringify( { publishable: true, nondraft: false, prompt: "Publish these changes? (mock)" } ) );
	}
	if ( p === "/mock/frontend/publish" ) {
		await readBody( req );
		return send( res, 200, "application/json", JSON.stringify( { success: true, message: "Published (mock)" } ) );
	}

	// Mock: the attachment download itself. Real bytes with a real
	// Content-Disposition, so a click that should NOT have navigated is observable
	// (in the editor those links are neutered - see src/extensions/presideEmbeds.js).
	if ( p.startsWith( "/mock/asset/" ) ) {
		const name = decodeURIComponent( p.split( "/" ).pop() || "document" );
		res.writeHead( 200, {
			  "Content-Type"       : "application/octet-stream"
			, "Content-Disposition": 'attachment; filename="' + name.replace( /"/g, "" ) + '"'
		} );
		return res.end( "mock attachment bytes for " + name );
	}

	// Mock: admin endpoints (picker iframes + flashram store)
	if ( p.startsWith( "/mock/admin/" ) ) {
		if ( p.includes( "temporarilyStoreData" ) ) { return send( res, 200, "application/json", "{}" ); }
		if ( p.includes( "linkpicker" ) )            { return send( res, 200, "text/html; charset=utf-8", mockPicker( "link" ) ); }
		if ( p.includes( "pickerForEditorDialog" ) ) {
			const type = params.get( "type" ) || "image";
			return send( res, 200, "text/html; charset=utf-8", mockPicker( type ) );
		}
		if ( p.includes( "widgets" ) )               { return send( res, 200, "text/html; charset=utf-8", mockPicker( "widget" ) ); }
		return send( res, 200, "application/json", "{}" );
	}

	// Aliases into the Preside tree / module dist
	if ( p === "/" ) { p = "/index.html"; }
	let filePath = null;
	if ( p.startsWith( "/ckeditor/" ) ) {
		filePath = path.join( PRESIDE_ASSETS, p );
	} else if ( p.startsWith( "/ckeditorExtensions/" ) ) {
		filePath = path.join( PRESIDE_ASSETS, p );
	} else if ( p === "/vendor/jquery.js" ) {
		filePath = path.join( PRESIDE_ASSETS, "js/admin/lib/jquery-2.2.5-sec.js" );
	} else if ( p.startsWith( "/vendor/" ) ) {
		filePath = path.join( PRESIDE_ASSETS, "js/admin/presidecore", p.slice( "/vendor/".length ) );
	} else if ( p.startsWith( "/dist/" ) ) {
		filePath = path.join( MODULE_DIR, p.replace( /^\//, "" ) );
		// dist outputs are content-hashed (facade.<hash>.min.js) but the harness
		// pages reference stable names (facade.min.js) - resolve like
		// StickerBundle.cfc does: newest hashed match wins.
		if ( !existsSync( filePath ) ) {
			const m = p.match( /^\/dist\/(.+)\.min\.(js|css)(\.map)?$/ );
			if ( m ) {
				const distDir = path.join( MODULE_DIR, "dist" );
				const re      = new RegExp( "^" + m[ 1 ].replace( /\./g, "\\." ) + "\\.[A-Z0-9]+\\.min\\." + m[ 2 ] + ( m[ 3 ] ? "\\.map" : "" ) + "$", "i" );
				const match   = readdirSync( distDir )
					.filter( ( f ) => re.test( f ) )
					.sort( ( a, b ) => statSync( path.join( distDir, b ) ).mtimeMs - statSync( path.join( distDir, a ) ).mtimeMs )[ 0 ];
				if ( match ) { filePath = path.join( distDir, match ); }
			}
		}
	} else {
		filePath = path.join( __dirname, p ); // harness-local files
	}

	// prevent path traversal
	if ( !filePath || filePath.includes( ".." ) ) { return send( res, 400, "text/plain", "bad path" ); }
	if ( !existsSync( filePath ) ) { return send( res, 404, "text/plain", "Not found: " + p ); }
	return sendFile( res, filePath );
} );

server.listen( PORT, () => {
	console.log( `[harness] http://localhost:${PORT}/` );
	console.log( `[harness] CKEditor: http://localhost:${PORT}/ckeditor.html` );
	console.log( `[harness] Tiptap:   http://localhost:${PORT}/tiptap.html` );
} );

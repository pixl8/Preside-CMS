/**
 * PresideEmbeds — the image / attachment / widget Tiptap nodes.
 *
 * Each is an inline atom node holding the raw Preside token in a `raw` attribute:
 *   {{image:<urlenc-json>:image}}
 *   {{attachment:<urlenc-json>:attachment}}
 *   {{widget:<id>:<urlenc-json>:widget}}
 *
 * - parseHTML picks up the placeholder <span data-preside-*> that tokens.js
 *   detokenize() injects at load time (mirrors CKEditor's dataFilter text rule).
 * - renderHTML emits that same placeholder <span data-raw="…"> so tokenize()
 *   can turn it straight back into the raw token for getData() (mirrors downcast).
 * - the NodeView renders a live preview fetched from the SAME AJAX endpoints the
 *   CKEditor widgets use (renderEmbeddedImageForEditor / …Attachment… /
 *   renderWidgetPlaceholder).
 * - the toolbar command opens the real Preside picker iframe via PresidePickerModal
 *   using its _config / _widgetConfig commit channel.
 * - presideImage additionally gets drag-to-resize + alignment chrome over that
 *   preview (src/imageTools.js), which writes back into the same token.
 */
import { Node } from "@tiptap/core";
import { openPickerModal, postForm } from "../presidePickerModal.js";
import { attachImageTools } from "../imageTools.js";
import { attachEmbedBubble } from "../embedBubble.js";
import { focusEditable } from "../editorFocus.js";
import { t } from "../i18n.js";

function makeEmbedNode( opts, deps ) {
	const buildAjaxLink  = deps.buildAjaxLink  || window.buildAjaxLink;
	const buildAdminLink = deps.buildAdminLink || window.buildAdminLink;

	// All three embeds are BLOCK widgets in CKEditor (<div> templates whose
	// downcast is the bare token text), so stored tokens sit between paragraphs,
	// never wrapped in <p>. opts.block mirrors that.
	const tag = opts.block ? "div" : "span";

	return Node.create( {
		name      : opts.name,
		group     : opts.block ? "block" : "inline",
		inline    : !opts.block,
		atom      : true,
		selectable: true,

		addOptions() {
			return { widgetCategories: deps.widgetCategories || "", linkPickerCategory: deps.linkPickerCategory || "" };
		},

		addAttributes() {
			return { raw: { default: null } };
		},

		parseHTML() {
			// Match both tags: legacy content saved by earlier extension versions
			// used a span placeholder for widgets too.
			return [
				  { tag: "div["  + opts.dataAttr + "]", getAttrs: el => ( { raw: el.getAttribute( "data-raw" ) } ) }
				, { tag: "span[" + opts.dataAttr + "]", getAttrs: el => ( { raw: el.getAttribute( "data-raw" ) } ) }
			];
		},

		renderHTML( { node } ) {
			const attrs = { "class": opts.cssClass, "data-raw": node.attrs.raw };
			attrs[ opts.dataAttr ] = "true";
			return [ tag, attrs ];
		},

		addNodeView() {
			const options = this.options;
			return ( { editor, node, getPos } ) => makePreviewDom( node, opts, buildAjaxLink, {
				  editor        : editor
				, getPos        : getPos
				, options       : options
				, buildAdminLink: buildAdminLink
				// presideImage only, and only when editable and not opted out
				// (defaultConfigs.imageTools = false).
				, imageTools    : !!( opts.resizable && deps.imageTools !== false && editor.isEditable )
				// The edit/remove bubble for the OTHER two embeds, under the same
				// opt-out: a field that turned embed chrome off should not sprout a
				// different flavour of it.
				, embedBubble   : !!( !opts.resizable && deps.imageTools !== false && editor.isEditable )
			} );
		},

		addCommands() {
			const name    = opts.name;
			const options = this.options;
			const commands = {};

			commands[ opts.insertCmd ] = ( raw ) => ( { chain } ) =>
				chain().focus().insertContent( { type: name, attrs: { raw: raw } } ).run();

			// `extra` lets a caller open the picker pre-pointed at something - the
			// slash menu uses it for `{ widget: "<id>" }` so "/news" lands on that
			// widget's own config form instead of the widget browser. Called with no
			// argument (the toolbar buttons) the URL is byte-identical to before.
			commands[ opts.openCmd ] = ( extra ) => ( { editor } ) => {
				openEmbedPicker( editor, opts, options, buildAdminLink, null, extra ); // insert (no editRaw)
				return true;
			};

			return commands;
		}
	} );
}

function makePreviewDom( node, opts, buildAjaxLink, edit ) {
	const dom = document.createElement( opts.block ? "div" : "span" );
	dom.className = opts.cssClass;
	dom.setAttribute( "contenteditable", "false" );
	dom.title = t( "embed.edithint" );

	// The server-rendered preview gets its own child so chrome drawn over it (the
	// image tools' handles / bubble / refresh button) can be a sibling rather than
	// something the next innerHTML wipes out. `frame` is the shrink-wrapping
	// position:relative box those absolutely-positioned overlays measure against.
	const frame = document.createElement( opts.block ? "div" : "span" );
	frame.className = "tiptap-embed-frame";
	const preview = document.createElement( opts.block ? "div" : "span" );
	preview.className = "tiptap-embed-preview";
	frame.appendChild( preview );
	dom.appendChild( frame );

	function openPicker() {
		if ( typeof edit.getPos === "function" ) { edit.editor.chain().setNodeSelection( edit.getPos() ).run(); }
		openEmbedPicker( edit.editor, opts, edit.options, edit.buildAdminLink, node.attrs.raw );
	}

	// Double-click → select this node + open its picker pre-populated for editing.
	if ( edit && edit.editor ) {
		dom.addEventListener( "dblclick", function( e ) {
			e.preventDefault(); e.stopPropagation();
			openPicker();
		} );
	}

	// LINKS INSIDE A PREVIEW DO NOT NAVIGATE WHILE THE EDITOR IS OPEN.
	//
	// The previews are real server-rendered HTML: an attachment renders as an
	// `<a href>` to the asset, so clicking the paperclip icon or its filename
	// DOWNLOADED the file - from inside the editor, where the click was meant to
	// select the embed so it could be edited or removed. (An image with a link is the
	// same shape of problem.) Selecting the node already worked, because the
	// select-me handler below `preventDefault()`s the mousedown - but a mousedown
	// preventDefault does not stop the anchor's own click activation, which is what
	// navigates.
	//
	// Capture phase, so it lands before anything in the rendered markup, and it
	// covers `auxclick` too (a middle click opens the download in a new tab) and
	// keyboard activation, which fires a click of its own. Nothing is neutered
	// outside the editor: node views only exist while the editor does, so once
	// editing ends - Classic closing, or Modern re-rendering the region from the
	// server - the links are the page's own again and work normally.
	if ( edit && edit.editor ) {
		const noNavigate = function( e ) {
			const a = e.target && e.target.closest ? e.target.closest( "a" ) : null;
			if ( a && dom.contains( a ) ) { e.preventDefault(); e.stopPropagation(); }
		};
		dom.addEventListener( "click", noNavigate, true );
		dom.addEventListener( "auxclick", noNavigate, true );
	}

	// A SINGLE click selects the whole node, so an embed gets the selected-border
	// state rather than a text selection painted across its preview. These are atom
	// nodes with contenteditable=false, but their previews are server-rendered HTML
	// full of real text, and a click landing on that text left the browser to start
	// a text selection inside it.
	//
	// Images already behave this way because imageTools does it (its click also has
	// to arm the drag handles and the bubble), so this covers the embeds that have
	// no tools of their own - attachments and widgets. preventDefault is what stops
	// the text selection starting, and it also suppresses the native focus, so the
	// DOM focus is taken explicitly - see src/editorFocus.js for why that has to
	// happen outside the transaction.
	if ( edit && edit.editor && !edit.imageTools ) {
		dom.addEventListener( "mousedown", function( e ) {
			if ( e.button !== 0 || typeof edit.getPos !== "function" ) { return; }
			e.preventDefault();
			focusEditable( edit.editor ).chain().setNodeSelection( edit.getPos() ).run();
		} );
	}

	function loadPreview() {
		const req = opts.previewReq( node.attrs.raw, buildAjaxLink );
		dom.classList.add( "loading" );
		dom.classList.remove( "error" );
		preview.textContent = opts.loadingLabel( node.attrs.raw );

		return postForm( req.url, req.data )
			.then( r => r.text() )
			.then( function( html ) {
				dom.classList.remove( "loading" );
				preview.innerHTML = html;
				if ( tools ) { tools.previewLoaded(); }
			} )
			.catch( function() {
				dom.classList.remove( "loading" );
				dom.classList.add( "error" );
				preview.textContent = t( "embed.error" );
			} );
	}

	// Images get the full tool set (drag-resize, alignment, sizes, edit, remove).
	// Widgets and attachments have no geometry to offer, so they get the SAME bubble
	// with just Edit and Remove - same chrome, same placement, shared code
	// (src/embedBubble.js). Both expose the identical hook shape, so everything below
	// treats them the same.
	let tools = edit.imageTools ? attachImageTools( {
		  dom          : dom
		, frame        : frame
		, preview      : preview
		, node         : node
		, editor       : edit.editor
		, getPos       : edit.getPos
		, buildAjaxLink: buildAjaxLink
		, refresh      : loadPreview
		, openPicker   : openPicker
	} ) : null;

	// `edit.embedBubble` is false for a read-only editor and when the site turns the
	// image tools off (defaultConfigs.imageTools) - a field that opted out of embed
	// chrome should not sprout a different flavour of it.
	if ( !edit.imageTools && edit.embedBubble ) {
		tools = attachEmbedBubble( {
			  dom       : dom
			, frame     : frame
			, node      : node
			, editor    : edit.editor
			, getPos    : edit.getPos
			, openPicker: openPicker
		} );
	}

	loadPreview();

	return {
		  dom: dom
		// Without an update() ProseMirror destroys and rebuilds the node view on
		// every attribute change — which would re-request the preview (and so make
		// Preside generate a derivative) on every single resize commit. Keep the DOM,
		// and only re-request when something the SERVER renders differently changed:
		// the image tools report a geometry-only change as handled.
		, update: function( newNode ) {
			if ( newNode.type.name !== node.type.name ) { return false; }

			const rawChanged = newNode.attrs.raw !== node.attrs.raw;
			const handled    = tools ? tools.update( newNode ) : false;
			node = newNode;

			if ( rawChanged && !handled ) { loadPreview(); }
			return true;
		  }
		, selectNode  : function() { dom.classList.add( "ProseMirror-selectednode" ); if ( tools ) { tools.selectNode(); } }
		, deselectNode: function() { dom.classList.remove( "ProseMirror-selectednode" ); if ( tools ) { tools.deselectNode(); } }
		// Let ProseMirror keep handling clicks on the image itself (that is what
		// selects the node), but keep its hands off our own controls.
		, stopEvent   : function( e ) { return tools ? tools.ownsEvent( e ) : false; }
	};
}

function openEmbedPicker( editor, opts, options, buildAdminLink, editRaw, extra ) {
	const editing = !!editRaw;
	openPickerModal( {
		  title       : t( opts.titleKey )
		, editor      : editor
		, url         : opts.pickerUrl( buildAdminLink, options, extra )
		, prefillData : ( editing && opts.prefill ) ? opts.prefill( editRaw ) : null
		, storeUrl    : buildAdminLink( "ajaxhelper.temporarilyStoreData" )
		, onCommit    : function( raw ) {
			if ( editing ) { editor.chain().focus().updateAttributes( opts.name, { raw: raw } ).run(); } // edit in place
			else { editor.commands[ opts.insertCmd ]( raw ); }
		  }
	} );
}

function inner( raw, re ) { const m = String( raw || "" ).match( re ); return m ? m[ 1 ] : ""; }

const WIDGET_RE = /{{widget:([a-zA-Z\$_][a-zA-Z0-9\$_]*):([\s\S]*?):widget}}/;

// ---- Public creators --------------------------------------------------------

export function createPresideImage( deps ) {
	return makeEmbedNode( {
		  name        : "presideImage"
		, block       : true
		, resizable   : true   // drag handles + alignment bubble (src/imageTools.js)
		, dataAttr    : "data-preside-image"
		, cssClass    : "img-placeholder"
		, titleKey    : "picker.image.title"
		, insertCmd   : "insertPresideImage"
		, openCmd     : "openPresideImagePicker"
		, loadingLabel: () => t( "embed.loading.image" )
		, previewReq  : ( raw, buildAjaxLink ) => ( { url: buildAjaxLink( "assetManager.renderEmbeddedImageForEditor" ), data: { embeddedImage: raw } } )
		, pickerUrl   : ( buildAdminLink ) => buildAdminLink( "assetmanager", "pickerForEditorDialog", { type: "image" } )
		, prefill     : ( raw ) => ( { configJson: inner( raw, /^\{\{image:(.*):image\}\}$/ ) } )
	}, deps || {} );
}

export function createPresideAttachment( deps ) {
	return makeEmbedNode( {
		  name        : "presideAttachment"
		, block       : true
		, dataAttr    : "data-preside-attachment"
		, cssClass    : "attachment-placeholder"
		, titleKey    : "picker.attachment.title"
		, insertCmd   : "insertPresideAttachment"
		, openCmd     : "openPresideAttachmentPicker"
		, loadingLabel: () => t( "embed.loading.attachment" )
		, previewReq  : ( raw, buildAjaxLink ) => ( { url: buildAjaxLink( "assetManager.renderEmbeddedAttachmentForEditor" ), data: { embeddedAttachment: raw } } )
		, pickerUrl   : ( buildAdminLink ) => buildAdminLink( "assetmanager", "pickerForEditorDialog", { type: "attachment" } )
		, prefill     : ( raw ) => ( { configJson: inner( raw, /^\{\{attachment:(.*):attachment\}\}$/ ) } )
	}, deps || {} );
}

export function createPresideWidget( deps ) {
	return makeEmbedNode( {
		  name        : "presideWidget"
		, block       : true
		, dataAttr    : "data-preside-widget"
		, cssClass    : "widget-placeholder"
		, titleKey    : "picker.widget.title"
		, insertCmd   : "insertPresideWidget"
		, openCmd     : "openPresideWidgetPicker"
		, loadingLabel: ( raw ) => { const m = raw && raw.match( WIDGET_RE ); return m ? m[ 1 ] : "widget"; }
		, previewReq  : ( raw, buildAjaxLink ) => {
			const m = raw && raw.match( WIDGET_RE );
			return { url: buildAjaxLink( "widgets.renderWidgetPlaceholder" ), data: { widgetId: m ? m[ 1 ] : "", data: m ? m[ 2 ] : "" } };
		  }
		// `extra.widget` (from the slash menu) makes core's Widgets.dialog() render
		// that widget's configForm instead of the browser - its own documented
		// behaviour for rc.widget. Omitted entirely when absent, so the toolbar
		// button's URL is unchanged.
		, pickerUrl   : function( buildAdminLink, options, extra ) {
			const params = {
				  widgetCategories  : options.widgetCategories   || ""
				, linkPickerCategory: options.linkPickerCategory || ""
			};
			if ( extra && extra.widget ) { params.widget = extra.widget; }
			return buildAdminLink( "widgets", "dialog", params );
		  }
		, prefill     : ( raw ) => { const m = String( raw || "" ).match( WIDGET_RE ); return { widget: m ? m[ 1 ] : "", configJson: m ? m[ 2 ] : "" }; }
	}, deps || {} );
}

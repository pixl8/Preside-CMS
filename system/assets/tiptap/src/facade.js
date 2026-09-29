/**
 * PresideTiptapRichEditor facade (Tiptap-backed).
 *
 * Loaded BEFORE the core presidecore bundle. Exposes window.PresideTiptapRichEditor.
 * presidecore's PresideRichEditor dispatcher (preside.richeditor.js) constructs this
 * when cfrequest.richeditorEngine === "tiptap". The harness, which has no dispatcher,
 * falls back to window.PresideRichEditor when that global is still unset.
 *
 * Preserves the Preside-facing contract:
 *   - constructor( textareaEl ); instance exposed on `.editor`
 *   - CKEDITOR.instances[name] registry (getData/setData/initialdata) - used by
 *     serialize-object (AJAX submit), dirtyforms, quick-add reset, frontend version restore
 *   - $textarea.data('ckeditorinstance') with getData() - used by jquery.validate
 *   - instance API: getData/setData/on/fire/focus/destroy/execCommand/commands
 *   - custom CKEditor config files (settings.ckeditor.defaults.configFile /
 *     per-field customConfig) are loaded and honoured - see customConfig.js
 */
import { buildToolbar } from "./toolbar.js";
import { tokenize, detokenize } from "./tokens.js";
import { injectFrameStyles } from "./presideStyles.js";
import { normalizeOutput } from "./normalize.js";
import { createPasteTransform } from "./pasteFilter.js";
import { getCustomConfig, prefetchCustomConfig } from "./customConfig.js";
import { applyTheme, renderThemeToggle } from "./theme.js";
import { toggleMaximize, exitMaximize, isMaximized } from "./maximize.js";
import { createOutline, outlineEnabled } from "./outline.js";
import { imageToolsEnabled } from "./imageTools.js";
import { createTableTools, tableToolsEnabled } from "./tableTools.js";
import { createSlashMenu, slashMenuEnabled } from "./slashMenu.js";
import { createDragHandle, dragHandleEnabled } from "./dragHandle.js";
import { createResizer, resizeEnabled } from "./resize.js";
import { createFrame, containerOf, frameOf, surfaceOf, pageRect } from "./editorFrame.js";
import { focusEditable } from "./editorFocus.js";
import { openDialog, closeDialog } from "./dialog.js";
import { placeBubble, bubbleButton } from "./embedBubble.js";
import { ICONS } from "./icons.js";
import { isDark } from "./theme.js";
import { activePlugins, emitLifecycle, noteEditorCreated } from "./pluginHost.js";
import { fitFrontendEditor } from "./frontendFit.js";
import { resolveInlineMount } from "./inlineMode.js";
import { initEditModeSwitch } from "./editModeSwitch.js";
import { createSelectionBubble } from "./selectionBubble.js";
import { fixJqueryInsertOrder } from "./jqueryOrderFix.js";
import { t } from "./i18n.js";

( function() {
	"use strict";

	var $ = window.presideJQuery || window.jQuery;
	var T = window.PresideTiptap;

	// Some Preside builds ship a jQuery whose after()/prepend() insert
	// multi-node content REVERSED - which scrambles every frontend save
	// (core's setContent). Feature-detected; a no-op on healthy builds.
	// Done at parse time: this bundle loads after presidecore (jQuery) and
	// before frontendEditors.js, so the fix is in place before any save.
	try { fixJqueryInsertOrder(); } catch ( e ) {}

	// ---- Minimal CKEDITOR global shim -------------------------------------
	// Non-editor consumers still reference window.CKEDITOR. We provide only what
	// they touch; the full editor lives on each instance, not on this global.
	var CK = window.CKEDITOR = window.CKEDITOR || {};
	CK.instances = CK.instances || {};
	CK.CTRL  = CK.CTRL  || 0x110000;
	CK.SHIFT = CK.SHIFT || 0x220000;
	CK.ALT   = CK.ALT   || 0x440000;
	CK.ENTER_P = 1; CK.ENTER_BR = 2; CK.ENTER_DIV = 3;
	// preside.iframe.modal.js (nested picker modals: the widget/image "+" add and
	// edit-pencil buttons) reads `parent.CKEDITOR.document.$`, expecting the native
	// document (real CKEditor exposes it as `CKEDITOR.dom.document.$`). Without it,
	// PresideIframeModal.open() throws after building the modal but before showing
	// it, so the nested dialog never appears.
	if ( !CK.document ) { CK.document = { $: document }; }
	if ( typeof CK.on !== "function" ) { CK.on = function() {}; }

	// ---- PresideTiptap.api: the helpers, re-exported as-is ------------------
	//
	// Published at PARSE time (a plugin bundle declares .after("tiptap-facade"),
	// so it parses after this line and before formFields.js mounts anything) and
	// living on the VENDOR global, because that is the one object a plugin can
	// count on. The registry itself is over there too - see src/plugins.js.
	//
	// Nothing here is wrapped. Each entry is the module's own function, because
	// the value is not the convenience - it is that a plugin does NOT reimplement
	// these, since each one encodes a trap that cost a release:
	//
	//   containerOf( el )      closest() stops at the root of the editable's OWN
	//                          document, so from inside the editing frame it
	//                          returns null and the caller silently operates on
	//                          nothing. This is how Maximize stopped working.
	//   frameOf / surfaceOf /  the frame boundary generally: which element is the
	//   pageRect               visible editor box, and how to translate content
	//                          geometry into host coordinates. Chrome positioned
	//                          without these lands at the top-left of the admin.
	//   focusEditable( ed )    Tiptap's focus command takes DOM focus SYNCHRONOUSLY
	//                          on Safari, which dispatches a selection correction
	//                          mid-chain: "Applying a mismatched transaction", and
	//                          the whole chain is silently lost. Take DOM focus
	//                          first, then chain off the return value.
	//   openDialog             dialog chrome in a SHADOW ROOT. The admin's own
	//                          legend/label/input rules - several of them
	//                          !important - mangle a light-DOM panel, and no
	//                          amount of specificity wins that fight.
	//   placeBubble            left-anchor then clamp, flip below when there is no
	//                          room, and measure against mount ∩ viewport (inline,
	//                          the mount is page-height, so the raw rect answers
	//                          the wrong question).
	//   tokenize / detokenize  the {{...}} <-> HTML conversion, and
	//   normalizeOutput        the output normaliser. Exported deliberately: a
	//                          plugin that touches document content MUST be able to
	//                          see what getData() will really store, or it cannot
	//                          verify it has not broken fidelity.
	//
	// t() resolves at render time; ICONS is our MIT (Tabler) set; isDark reads the
	// CONTAINER, not the stored preference (an inline editor stays light).
	if ( T ) {
		T.api = {
			  t              : t
			, openDialog     : openDialog
			, closeDialog    : closeDialog
			, surfaceOf      : surfaceOf
			, pageRect       : pageRect
			, containerOf    : containerOf
			, frameOf        : frameOf
			, focusEditable  : focusEditable
			, placeBubble    : placeBubble
			, bubbleButton   : bubbleButton
			, ICONS          : ICONS
			, applyTheme     : applyTheme
			, isDark         : isDark
			, tokenize       : tokenize
			, detokenize     : detokenize
			, normalizeOutput: normalizeOutput
			// The plan's name for it; the same function, so a plugin can use either.
			, normalize      : normalizeOutput
			, apiVersion     : T.apiVersion || 1
		};
	}

	function cfreq() { return window.cfrequest || {}; }

	// ---- Config assembly (mirror of core preside.richeditor.js) -----------

	// enterMode arrives as a string ("br"/"div") from the data attribute, or as
	// a numeric CKEDITOR.ENTER_* constant when set by a custom config file.
	function normaliseEnterMode( v ) {
		if ( v === CK.ENTER_BR  ) { return "br"; }
		if ( v === CK.ENTER_DIV ) { return "div"; }
		if ( v === CK.ENTER_P   ) { return "p"; }
		return String( v || "" ).toLowerCase();
	}

	// contentsCss may be a single URL or an array of URLs in a config file;
	// Preside's stylesheets value is a comma list.
	function contentsCssToCsv( v ) {
		if ( !v ) { return ""; }
		return Array.isArray( v ) ? v.join( "," ) : String( v );
	}

	function readConfig( ta ) {
		var $ta = $( ta ), cf = cfreq();

		// The custom CKEditor config file (per-field customConfig attr, falling
		// back to settings.ckeditor.defaults.configFile via cfrequest.ckeditorConfig)
		// supplies BASE values that anything set per-instance overrides - exactly
		// CKEditor's precedence (file config < CKEDITOR.replace() config).
		var fileCfg = getCustomConfig( $ta.data( "customConfig" ) || cf.ckeditorConfig );

		// settings.ckeditor.defaults.defaultConfigs merged with the form control's
		// customDefaultConfigs arg (data-custom-default-configs, JSON - jQuery
		// .data() parses it), exactly like core preside.richeditor.js - both
		// layered over the config file's values.
		var defaultConfigs = $.extend( {}, fileCfg, cf.ckeditorDefaultConfigs || {}, $ta.data( "customDefaultConfigs" ) || {} );

		return {
			  placeholder        : $ta.attr( "placeholder" )          || cf.ckeditorDefaultPlaceholder || fileCfg.editorplaceholder || ""
			, toolbar            : $ta.data( "toolbar" )              || cf.ckeditorDefaultToolbar     || fileCfg.toolbar           || ""
			, width              : $ta.data( "width" )                || cf.ckeditorDefaultWidth       || fileCfg.width
			, minHeight          : $ta.data( "minHeight" )            || cf.ckeditorDefaultMinHeight   || fileCfg.autoGrow_minHeight
			, maxHeight          : $ta.data( "maxHeight" )            || cf.ckeditorDefaultMaxHeight   || fileCfg.autoGrow_maxHeight
			, stylesheets        : $ta.data( "stylesheets" )          || contentsCssToCsv( fileCfg.contentsCss )
			, enterMode          : normaliseEnterMode( $ta.data( "enterMode" ) || fileCfg.enterMode )
			, widgetCategories   : $ta.data( "widgetCategories" )     || cf.widgetCategories   || ""
			, linkPickerCategory : $ta.data( "linkPickerCategory" )   || cf.linkPickerCategory || ""
			, autoParagraph      : $ta.data( "autoParagraph" ) !== undefined ? $ta.data( "autoParagraph" )
			                     : ( cf.ckeditorAutoParagraph !== undefined ? cf.ckeditorAutoParagraph : fileCfg.autoParagraph )
			, defaultConfigs     : defaultConfigs
		};
	}

	/**
	 * Fire a lifecycle event on BOTH buses.
	 *
	 * The facade instance's own CKEditor-shaped `on`/`fire` is the public one and
	 * the one core already uses (instanceReady), so anything that has an instance
	 * gets it there. The registry's global bus (src/plugins.js) exists because
	 * `beforeExtensions` fires before the instance does - there is nothing else to
	 * fire it on - and a plugin registered at parse time has no instance to attach
	 * to yet either. Both carry the same ctx.
	 */
	function fireLifecycle( instance, evt, ctx ) {
		if ( instance ) { try { instance.fire( evt, ctx ); } catch ( e ) {} }
		emitLifecycle( evt, ctx );
	}

	// ---- Compat instance: CKEditor-shaped API over a Tiptap editor --------
	function CompatInstance( name, tiptap, cfg, textarea, container ) {
		this.name        = name;
		this._t          = tiptap;
		this.config      = cfg || {};
		this.mode        = "wysiwyg";
		// frontendEditors.js reads commands.maximize.state to un-maximize before
		// teardown; derive it from the DOM so it stays right no matter who toggled
		// (toolbar button, alt+enter, execCommand).
		this.commands    = { maximize: {} };
		Object.defineProperty( this.commands.maximize, "state", {
			  get : function() { return isMaximized( container ) ? 1 : 0; }
			, set : function() {}
		} );
		this._el         = textarea;
		this._container  = container;
		this._handlers   = {};
		this.initialdata = "";

		// The normaliser options, stashed where a module holding only the Tiptap
		// editor can reach them: the Source view has to render the STORED markup, and
		// it has no route back to the CKEditor-shaped config otherwise. Keep this in
		// step with getData() below - the whole point is that the two agree.
		tiptap.__ttNormalize = {
			  autoParagraph: this.config.autoParagraph
			, enterMode    : this.config.enterMode
		};

		var self = this;
		tiptap.on( "update", function() {
			self._sync();
			self._emit( "change" );
		} );
	}
	CompatInstance.prototype.getData = function() {
		return normalizeOutput( tokenize( this._t.getHTML() ), {
			  autoParagraph: this.config.autoParagraph
			, enterMode    : this.config.enterMode
		} );
	};
	CompatInstance.prototype.setData = function( html ) {
		this._t.commands.setContent( detokenize( html || "" ), { emitUpdate: false } );
		this._sync();
	};
	CompatInstance.prototype._sync = function() {
		if ( this._el ) { this._el.value = this.getData(); }
	};
	CompatInstance.prototype.on = function( evt, fn ) {
		( this._handlers[ evt ] = this._handlers[ evt ] || [] ).push( fn );

		var self = this;
		if ( evt === "key" ) {
			// CKEditor ORs modifier masks into keyCode - consumers test e.g.
			// `13 + CKEDITOR.CTRL` for ctrl+enter (frontendEditors save-draft /
			// alt+enter maximize) - and a handler returning false cancels the
			// keystroke (real CKEditor's event.cancel()).
			var listener = function( e ) {
				var code = e.keyCode
					+ ( ( e.ctrlKey || e.metaKey ) ? CK.CTRL  : 0 )
					+ ( e.shiftKey                 ? CK.SHIFT : 0 )
					+ ( e.altKey                   ? CK.ALT   : 0 );
				var result = fn( { editor: self, data: { keyCode: code, domEvent: e } } );
				if ( result === false ) {
					e.preventDefault();
					e.stopPropagation();
				}
			};
			this._t.view.dom.addEventListener( "keydown", listener );
			( this._domListeners = this._domListeners || [] ).push( [ "keydown", listener ] );
		}
		return this;
	};
	CompatInstance.prototype._emit = function( evt, data ) {
		var hs = this._handlers[ evt ] || [];
		for ( var i = 0; i < hs.length; i++ ) {
			hs[ i ]( { editor: this, data: data || {} } );
		}
	};
	CompatInstance.prototype.fire = function( evt, data ) { this._emit( evt, data ); };
	// DOM focus, deliberately NOT Tiptap's focus command.
	//
	// Tiptap builds a transaction when `.commands` is ACCESSED (`const { tr } =
	// state`) and dispatches that same transaction after the command body has run.
	// The focus command's body calls `view.focus()`, and in WebKit a DOM focus
	// synchronously fires the events prosemirror-view uses to re-read the document
	// selection - so it dispatches a correcting transaction of its own, the state
	// moves on, and the transaction Tiptap built a moment earlier is then applied to
	// a state it was not created from: "RangeError: Applying a mismatched
	// transaction".
	//
	// That was not theoretical. Core's frontendEditors.js calls
	// `e.editor.focus()` from its own `instanceReady` handler (line ~174), so in
	// Safari EVERY frontend editor threw here as it opened, and the throw aborted
	// the rest of core's handler - including its scroll-to-the-editor - leaving the
	// page silently un-scrolled.
	//
	// `view.focus()` is prosemirror-view's own method: it focuses the editable and
	// lets ProseMirror reconcile the selection itself, building no transaction, so
	// there is nothing to mismatch. It is also the more faithful reading of
	// CKEditor's focus(), which focused the editing surface and never moved the
	// caret. Chained forms (`chain().focus().x().run()`) are unaffected - a chain
	// builds and dispatches one transaction at .run().
	CompatInstance.prototype.focus = function() {
		try { this._t.view.focus(); } catch ( e ) {}
	};
	CompatInstance.prototype.getSelection = function() { return null; }; // TODO Phase 2
	// Mirrors real CKEditor's destroy(): tear down the editor DOM and restore the
	// textarea so a later `new PresideRichEditor()` on the same element starts
	// clean (frontend editors create/destroy on every edit-mode toggle).
	CompatInstance.prototype.destroy = function() {
		// FIRST, before the cleanups: a plugin that applied something to the
		// DOCUMENT (a pending suggestion, a decoration-backed preview) has to be
		// able to revert it while the editor is still alive and the change can
		// still be undone. Once _cleanups have run there is no editor left to
		// revert into.
		fireLifecycle( this, "beforeDestroy", this._ctx || { instance: this, editor: this._t } );
		try {
			if ( this._domListeners && this._t.view && this._t.view.dom ) {
				var dom = this._t.view.dom;
				this._domListeners.forEach( function( l ) { dom.removeEventListener( l[ 0 ], l[ 1 ] ); } );
			}
		} catch ( e ) {}
		this._domListeners = null;
		// Chrome that registered document/window listeners or wrote onto DOM outside
		// our container (frontendFit) hands back a teardown - run them before the
		// container goes, so nothing outlives the editor.
		if ( this._cleanups ) {
			this._cleanups.forEach( function( fn ) { try { fn(); } catch ( e ) {} } );
			this._cleanups = null;
		}
		try { this._t.destroy(); } catch ( e ) {}
		// The frame holds a ResizeObserver on its own document - dropping the
		// container would orphan it (and the observer keeps the frame's document
		// alive), so it is torn down explicitly.
		if ( this._frame ) { try { this._frame.destroy(); } catch ( e ) {} this._frame = null; }
		// Destroying while maximized would leave <html> scroll-locked and the
		// restore placeholder orphaned in the page.
		if ( this._container ) { exitMaximize( this._container ); }
		if ( this._container && this._container.parentNode ) {
			this._container.parentNode.removeChild( this._container );
		}
		this._container = null;
		if ( this._el ) {
			this._el.style.display = "";
			this._el.removeAttribute( "data-tiptap-mounted" );
			$( this._el ).removeData( "ckeditorinstance" );
		}
		if ( this.name && CK.instances[ this.name ] === this ) { delete CK.instances[ this.name ]; }
	};
	CompatInstance.prototype.execCommand = function( name ) {
		if ( name === "maximize" ) {
			var container = this._container || containerOf( this._t.view.dom );
			if ( container ) { toggleMaximize( container, this._t ); }
		}
	};

	// ---- The facade -------------------------------------------------------
	function PresideRichEditor( elementToReplace ) {
		this.init( elementToReplace );
	}

	PresideRichEditor.prototype.init = function( ta ) {
		if ( ta.getAttribute( "data-tiptap-mounted" ) === "1" ) { return; }
		ta.setAttribute( "data-tiptap-mounted", "1" );

		try {
			this._mount( ta );
		} catch ( e ) {
			ta.removeAttribute( "data-tiptap-mounted" );
			throw e;
		}
	};

	PresideRichEditor.prototype._mount = function( ta ) {
		var $ta  = $( ta );
		var name = ta.getAttribute( "name" ) || ta.id || "";
		var cfg  = readConfig( ta );

		// DOM: hide the textarea (kept for native form submit), mount editor after it.
		var container = document.createElement( "div" );
		container.className = "tiptap-editor-container";

		// Modern inline mode (frontend only): inlineMode.js marked the textarea
		// before triggering core's edit flow. The editor mounts chrome-less INSIDE
		// the page, exactly where the rendered content was (between the region's
		// comment delimiters) - no toolbar/footer/outline, no height caps, and the
		// selection bubble instead of a fixed toolbar. resolveInlineMount() returns
		// null on any mismatch, in which case this is an ordinary mount - fail safe.
		var inlineId    = ta.getAttribute( "data-tiptap-inline" ) || "";
		var inlineMount = inlineId ? resolveInlineMount( inlineId, container ) : null;
		var isInline    = !!inlineMount;
		if ( isInline ) { container.className += " tiptap-inline"; }

		var toolbarEl = document.createElement( "div" );
		toolbarEl.className = "tiptap-toolbar";
		if ( !isInline ) { container.appendChild( toolbarEl ); }

		// Honour the user's stored light/dark preference from the first paint (the
		// toolbar's toggle then flips it for every editor on the page - see theme.js).
		// Inline editors stay light: the editable IS the site page.
		// Read BEFORE the frame is built, so the frame's root is stamped with the
		// right theme on its first paint too.
		if ( !isInline ) { applyTheme( container ); }

		ta.style.display = "none";
		ta.setAttribute( "data-tiptap-mounted", "1" );
		if ( isInline ) {
			inlineMount.anchor.parentNode.insertBefore( container, inlineMount.anchor.nextSibling );
		} else {
			ta.parentNode.insertBefore( container, ta.nextSibling );
		}

		// The editable goes in an IFRAME (see src/editorFrame.js for why: rem, vw and
		// isolation, none of which CSS can deliver) - EXCEPT in Modern inline mode,
		// where the editable IS the site page and must inherit the theme.
		//
		// This has to happen AFTER the container is in the document: an iframe has no
		// contentDocument until it is attached.
		var frameApi = isInline ? null : createFrame( container, { title: cfg.label || "" } );
		var mount    = frameApi ? frameApi.mount : document.createElement( "div" );
		if ( !frameApi ) {
			mount.className = "tiptap-editor-mount";
			container.appendChild( mount );
		}
		this._frame = frameApi;
		// What the host-side chrome (outline rail, table bubble, drag gutter) treats
		// as "the editing surface": the FRAME for a boxed editor - it is a normal
		// element in this document and its rect is the visible editor box - and the
		// mount div in Modern inline mode. See surfaceOf() in editorFrame.js.
		var surfaceEl = frameApi ? frameApi.frame : mount;

		// CKEditor's editable lived in an iframe, so keystrokes never reached the
		// admin document. Tiptap edits inline, and Preside's admin hotkeys
		// (preside.hotkeys.js) fail to detect a focused contenteditable as "typing"
		// (jQuery .prop('contenteditable') misses the camelCase DOM property) - so
		// e.g. typing "e" toggles quick-edit. Reproduce the iframe isolation: let
		// everything inside the editor (ProseMirror, our key bridge, the source
		// textarea) handle keys, then stop them bubbling to the admin page.
		[ "keydown", "keypress", "keyup" ].forEach( function( evt ) {
			container.addEventListener( evt, function( e ) { e.stopPropagation(); } );
		} );

		// min/maxHeight can legitimately arrive as the string "auto" - that is what
		// ckEditorJs.cfm sends when settings.ckeditor.defaults leaves them unset -
		// so only apply a numeric value. `parseInt( "auto" ) || 0` would set
		// max-height:0px and collapse the editable entirely.
		var minHeight = parseInt( cfg.minHeight, 10 );
		var maxHeight = parseInt( cfg.maxHeight, 10 );
		// Inline: the PAGE is the scroller and the content owns its own size -
		// height caps and a fixed width belong to the boxed editor only.
		if ( !isInline ) {
			// The frame is a replaced element and does not grow with its content, so
			// the height is measured and applied (editorFrame.js). Below maxHeight it
			// tracks the content; at it, the frame's own document scrolls - which is
			// what CKEditor's iframe did.
			frameApi.setHeights( minHeight, maxHeight );
			if ( cfg.width && cfg.width !== "auto" ) {
				container.style.width = String( cfg.width ).match( /^\d+$/ ) ? cfg.width + "px" : cfg.width;
			}
		}

		// disallowedContent / pasteFromWordDisallow filtering (core applies these
		// via CKEDITOR.filter on paste - see preside.richeditor.js).
		var pasteTransform = createPasteTransform( cfg.defaultConfigs );

		// The plugin context (src/plugins.js). Created HERE - before the editor -
		// and then FILLED IN as the pieces come into existence, deliberately as one
		// object: the tiptapExtensions hook has to run before there is an editor at
		// all, and a plugin that keeps the ctx it was handed then sees `editor` and
		// `instance` appear rather than holding a permanently-null copy.
		var ctx = {
			  editor   : null
			, instance : null
			, cfg      : cfg
			, container: container
			, toolbar  : isInline ? null : toolbarEl
			, frame    : frameApi ? frameApi.frame : null   // null in Modern inline mode
			, mode     : isInline ? "inline" : "boxed"
			, api      : T && T.api
		};
		this._ctx = ctx;

		var self   = this;
		var tiptap = new T.Editor( {
			  element    : mount
			, extensions : this.buildExtensions( cfg, ctx )
			, content    : detokenize( ta.value || "" )
			, editorProps: pasteTransform ? { transformPastedHTML: pasteTransform } : {}
		} );

		// jquery.validate delegates focusin/focusout/keyup on a selector that
		// includes `[contenteditable]`, and its handler reads `this.form` before any
		// ignore check (jquery.validate.js). CKEditor's editable lived in an iframe so
		// those events never reached the host form; Tiptap's editable is inline, and a
		// bare contenteditable div has no `.form`, so the delegate does
		// `$.data( undefined, "validator" )` -> throws on every focus/keystroke. Point
		// the editable at the host form (as form-associated elements natively are) so
		// the validator resolves. jquery.validate has explicit contenteditable support
		// and no-ops on our nameless editable.
		try { if ( tiptap.view && tiptap.view.dom ) { tiptap.view.dom.form = ta.form || null; } } catch ( e ) {}

		// Fit the frame to the content NOW. setHeights() above ran before the editor
		// existed, so it measured an empty mount - the ResizeObserver corrects it a
		// tick later, but until then the frame is short and its document scrolls,
		// which anything measuring the editor synchronously after construction sees
		// (T11 caught exactly that). The first paint should be the right size.
		if ( frameApi ) {
			frameApi.refit();
			// ...and on every edit, synchronously. The ResizeObserver alone leaves the
			// frame one tick behind its content, so a block added programmatically sat
			// outside the frame's viewport until the next frame - which made chrome
			// that clamps to the visible band (the drag grip) correctly refuse to show
			// for it (T15 caught this). An edit changing the height should change the
			// frame in the same tick.
			tiptap.on( "update", frameApi.refit );
		}

		ctx.editor = tiptap;
		// From now on a register() is too late for the editors already on the page,
		// and the registry says so out loud rather than doing nothing visible.
		noteEditorCreated();

		var instance = new CompatInstance( name, tiptap, cfg, ta, container );
		instance.initialdata = instance.getData();
		ta.value = instance.initialdata;
		ctx.instance = instance;
		instance._ctx = ctx;

		// Toolbar: a config file may set config.toolbar to a CKEditor array
		// directly, and a bare toolbar NAME that reached the client unresolved
		// (i.e. not defined in settings.ckeditor.toolbars, which the server
		// resolves before rendering data-toolbar) is looked up against the config
		// file's `config.toolbar_<name>` definitions - CKEditor's named-toolbar
		// semantics.
		var parsedToolbar = Array.isArray( cfg.toolbar ) ? cfg.toolbar : this.parseToolbarConfig( cfg.toolbar );
		if ( typeof parsedToolbar === "string" && Array.isArray( cfg.defaultConfigs[ "toolbar_" + parsedToolbar ] ) ) {
			parsedToolbar = cfg.defaultConfigs[ "toolbar_" + parsedToolbar ];
		}
		var bubbleCleanup = null;
		if ( isInline ) {
			// No persistent toolbar: the selection bubble offers the same buttons
			// (same renderers - see selectionBubble.js), filtered per block.
			bubbleCleanup = createSelectionBubble( tiptap, container, parsedToolbar, cfg );
		} else {
			// Built BEFORE the footer: it reports whether a toolbar config placed the
			// light/dark toggle explicitly, which decides where the toggle ends up.
			var toolbarInfo = buildToolbar( toolbarEl, tiptap, parsedToolbar, cfg );

			// Footer status bar: word / char counts + estimated reading time, with the
			// light/dark toggle right-aligned on the same row.
			// Opt out per-site/per-field with defaultConfigs.wordcount = false.
			var wantsTheme = toolbarInfo.themeEnabled && !toolbarInfo.themeRendered;
			// Manual resize grip - CKEditor's `resize` plugin (src/resize.js). It is the
			// bottom bar's right-hand corner, so it goes in the footer's right-hand slot
			// beside the light/dark toggle; a field with no footer gets it floating in
			// the container's own corner instead (`.is-floating`), which is where the
			// author reaches for it either way.
			var resizer = resizeEnabled( cfg ) ? createResizer( container, frameApi, cfg ) : null;
			if ( cfg.defaultConfigs.wordcount !== false ) {
				container.appendChild( buildFooter( tiptap, wantsTheme, resizer ) );
			} else if ( wantsTheme ) {
				// No footer to host it - fall back to the far right of the toolbar.
				var right = document.createElement( "span" );
				right.className = "tiptap-toolbar-group tiptap-toolbar-right";
				right.appendChild( renderThemeToggle() );
				toolbarEl.appendChild( right );
			}
			if ( resizer && !resizer.parentNode ) {
				resizer.classList.add( "is-floating" );
				container.appendChild( resizer );
			}
		}

		// The toolbar exists (or, inline, has been decided against - ctx.toolbar is
		// null there and the selection bubble is what a plugin would sit next to).
		// For chrome that must be positioned RELATIVE to the toolbar; ordinary
		// after-mount work belongs in the registry's `chrome` hook, below.
		fireLifecycle( instance, "toolbarReady", ctx );

		// Document outline navigator: a hover-expanding rail of heading markers on
		// the right edge of the container (chrome only - see src/outline.js).
		// Inline (Modern) it pins to the right edge of the VIEWPORT instead - the
		// page is the scroller there, so the rail must not scroll away with it.
		// Opt out per-site/per-field with defaultConfigs.outline = false.
		if ( outlineEnabled( cfg ) ) {
			container.appendChild( createOutline( tiptap, surfaceEl, { fixed: isInline } ) );
		}

		// Table bubble toolbar: row/column/cell controls over the table the caret
		// is in (chrome only - see src/tableTools.js).
		// Opt out per-site/per-field with defaultConfigs.tableTools = false.
		if ( tableToolsEnabled( cfg ) ) {
			createTableTools( tiptap, container, surfaceEl );
		}

		// Block drag handle: hover a block to get a grip in the left gutter
		// (chrome only - see src/dragHandle.js).
		// Opt out per-site/per-field with defaultConfigs.dragHandle = false.
		// The "+" only types a "/" for the author, so it is rendered only when the
		// slash menu is actually there to react to it.
		// Inline (Modern) editors get the FIXED variant: the container sits in the
		// site's page flow, where a gutter carved out of the theme's layout is one
		// overflow:hidden ancestor away from being clipped into invisibility.
		if ( dragHandleEnabled( cfg ) ) {
			createDragHandle( tiptap, container, surfaceEl, slashMenuEnabled( cfg ), { fixed: isInline } );
		}

		// contentsCss / stylesheets, UNMODIFIED, in the frame's own head - that is
		// the fidelity fix (see editorFrame.js). The Format/Styles dropdown previews
		// get their own <link> to the same sheet, in their own panel frame
		// (src/comboPanel.js), so nothing here needs a scoped copy any more.
		// Not inline: the editable sits in the real page and inherits the site's
		// CSS directly - injecting the admin-configured content CSS again would
		// double-apply or fight it.
		if ( !isInline ) {
			// The toolbar is refreshed on load as well as the frame refitted: the Styles
			// combo's entries are harvested from these very sheets, so until they arrive
			// it has nothing to offer and correctly renders itself disabled.
			injectFrameStyles( frameApi.doc, cfg.stylesheets, function() {
				frameApi.refit();
				if ( toolbarInfo && toolbarInfo.refresh ) { try { toolbarInfo.refresh(); } catch ( e ) {} }
			} );
		}

		// Plugin chrome, LAST: it runs with everything built and the editor live, and
		// whatever it hands back is torn down with the rest. A plugin that returns no
		// teardown is taken at its word - anything it put inside the container goes
		// when the container does.
		var pluginCleanups = [];
		activePlugins( cfg ).forEach( function( p ) {
			if ( typeof p.chrome !== "function" ) { return; }
			try {
				var teardown = p.chrome( ctx );
				if ( typeof teardown === "function" ) { pluginCleanups.push( teardown ); }
			} catch ( e ) {
				if ( window.console ) { window.console.error( '[tiptap] plugin "' + p.name + '" chrome() failed', e ); }
			}
		} );

		// Teardown registry, run FIRST in destroy() - everything here wrote outside
		// the container (CSS vars on <html>, body-portalled elements, the inline
		// mount's original page nodes), so it must not outlive the editor.
		// fitFrontendEditor no-ops (null) outside core's modal wrapper.
		instance._cleanups = [
			  fitFrontendEditor( container )
			, isInline ? inlineMount.cleanup : null
			, bubbleCleanup
		].filter( Boolean ).concat( pluginCleanups );

		if ( name ) { CK.instances[ name ] = instance; }
		$ta.data( "ckeditorinstance", instance );

		this.editor = instance;

		// instanceReady fires async so callers (e.g. frontendEditors) can attach
		// first. Guarded: a frontend editor can legitimately be destroyed within
		// the same tick it was created (Modern mode's save -> re-enter churn), and
		// consumers' instanceReady handlers call getData() on a live editor.
		setTimeout( function() { if ( !tiptap.isDestroyed ) { fireLifecycle( instance, "instanceReady", ctx ); } }, 0 );
	};

	// `ctx` is the plugin context (see init). It is optional so the old
	// one-argument form - which is what an existing site monkey-patching this
	// prototype calls - keeps working unchanged.
	PresideRichEditor.prototype.buildExtensions = function( cfg, ctx ) {
		// Disable StarterKit's own link mark - PresideLink owns link serialization.
		var exts = [ T.StarterKit.configure( { link: false } ) ];
		var ext  = T.extensions || {};

		// Preserve class/style on blocks + spans (fidelity + class-based content CSS).
		if ( ext.createPresideAttributes )  { exts.push( ext.createPresideAttributes() ); }
		if ( ext.createPresideInlineStyle ) { exts.push( ext.createPresideInlineStyle() ); }

		if ( ext.createPresideLink ) {
			exts.push( ext.createPresideLink( {
				  $                 : $
				, buildAdminLink    : window.buildAdminLink
				, linkPickerCategory: cfg.linkPickerCategory
			} ) );
		}
		if ( ext.createPresideAnchor ) { exts.push( ext.createPresideAnchor() ); }

		var embedDeps = {
			  buildAdminLink    : window.buildAdminLink
			, buildAjaxLink     : window.buildAjaxLink
			, widgetCategories  : cfg.widgetCategories
			, linkPickerCategory: cfg.linkPickerCategory
			// Drag-to-resize + alignment chrome on embedded images
			// (defaultConfigs.imageTools = false opts a site/field out).
			, imageTools        : imageToolsEnabled( cfg )
		};
		if ( ext.createPresideImage )      { exts.push( ext.createPresideImage( embedDeps ) ); }
		if ( ext.createPresideAttachment ) { exts.push( ext.createPresideAttachment( embedDeps ) ); }
		if ( ext.createPresideWidget )     { exts.push( ext.createPresideWidget( embedDeps ) ); }

		// The "/" insert menu. Registered as an extension (it is a ProseMirror
		// plugin, unlike the other chrome), so it has to be built here rather than
		// appended to the container after mount.
		// Opt out per-site/per-field with defaultConfigs.slashMenu = false.
		if ( slashMenuEnabled( cfg ) && T.Suggestion && T.Extension ) {
			exts.push( createSlashMenu( T, cfg ) );
		}

		// Phase 4: wider toolbar support (subscript/superscript/text-align/table/placeholder)
		if ( ext.buildRichText ) {
			ext.buildRichText( { placeholder: cfg.placeholder } ).forEach( function( e ) { exts.push( e ); } );
		}

		// enterMode=br: Enter inserts <br> instead of a new paragraph (CKEditor's
		// ENTER_BR). Lists/code blocks keep their native Enter behaviour.
		if ( cfg.enterMode === "br" && T.Extension ) {
			exts.push( T.Extension.create( {
				  name    : "presideEnterBr"
				, priority: 1000
				, addKeyboardShortcuts: function() {
					return {
						Enter: function( args ) {
							var editor = args.editor;
							if ( editor.isActive( "listItem" ) || editor.isActive( "codeBlock" ) ) { return false; }
							return editor.commands.setHardBreak();
						}
					};
				}
			} ) );
		}

		// Plugin-contributed Tiptap extensions. THIS is the only moment they can be
		// added: a Tiptap editor's extension list is fixed at construction, so no
		// post-mount hook could do it. The context is handed over with
		// `editor`/`instance` still null for exactly that reason - it is the same
		// object init() fills in a moment later, so a plugin that keeps it will see
		// them appear.
		var pctx = ctx || {
			  editor: null, instance: null, cfg: cfg, container: null, toolbar: null
			, frame : null, mode: "boxed", api: T && T.api
		};
		activePlugins( cfg ).forEach( function( p ) {
			if ( typeof p.tiptapExtensions !== "function" ) { return; }
			try {
				var got = p.tiptapExtensions( pctx ) || [];
				( Array.isArray( got ) ? got : [ got ] ).forEach( function( e ) { if ( e ) { exts.push( e ); } } );
			} catch ( e ) {
				if ( window.console ) { window.console.error( '[tiptap] plugin "' + p.name + '" tiptapExtensions() failed', e ); }
			}
		} );

		// The array is exposed on the ctx so a `beforeExtensions` listener can push
		// onto it - that is the whole point of firing before the return. There is no
		// instance yet, so this event reaches the registry's global bus only.
		pctx.extensions = exts;
		emitLifecycle( "beforeExtensions", pctx );

		return exts;
	};

	// ---- Footer status bar --------------------------------------------------
	// Words / chars / estimated reading time, refreshed on every doc change
	// ("transaction" rather than "update" so programmatic setData( emitUpdate:
	// false ) refreshes it too).
	var READING_WORDS_PER_MINUTE = 225;

	function buildFooter( tiptap, withThemeToggle, resizer ) {
		var footer = document.createElement( "div" );
		footer.className = "tiptap-footer";

		var wordsEl   = document.createElement( "span" );
		var charsEl   = document.createElement( "span" );
		var readingEl = document.createElement( "span" );
		wordsEl.className   = "tiptap-footer-words";
		charsEl.className   = "tiptap-footer-chars";
		readingEl.className = "tiptap-footer-reading";
		footer.appendChild( wordsEl );
		footer.appendChild( charsEl );
		footer.appendChild( readingEl );

		// Right-aligned (margin-left:auto in the css) slot holding the light/dark
		// toggle and the resize grip. Always created, even when it ends up empty, so
		// there is exactly ONE auto margin in the row - two would split the free space
		// between them and park the toggle in the middle of the footer.
		var rightWrap = document.createElement( "span" );
		rightWrap.className = "tiptap-footer-right";
		if ( withThemeToggle ) { rightWrap.appendChild( renderThemeToggle() ); }
		if ( resizer ) { rightWrap.appendChild( resizer ); }
		footer.appendChild( rightWrap );

		function refresh() {
			var doc   = tiptap.state.doc;
			var text  = doc.textBetween( 0, doc.content.size, " ", " " ).trim();
			var words = text.length ? text.split( /\s+/ ).length : 0;
			var mins  = Math.max( 1, Math.ceil( words / READING_WORDS_PER_MINUTE ) );

			wordsEl.textContent   = t( "footer.words", { count: words } );
			charsEl.textContent   = t( "footer.chars", { count: text.length } );
			readingEl.textContent = t( "footer.readingtime", { count: mins } );
		}

		tiptap.on( "transaction", function( args ) {
			if ( !args || !args.transaction || args.transaction.docChanged ) { refresh(); }
		} );
		refresh();

		return footer;
	}

	// Ported verbatim from core preside.richeditor.js.
	PresideRichEditor.prototype.parseToolbarConfig = function( rawToolbarText ) {
		rawToolbarText = rawToolbarText || "";

		var bars = rawToolbarText.split( "|" )
		  , barCount = bars.length
		  , toolbar = []
		  , buttons, bar, i, n;

		if ( rawToolbarText.match( /[\,\|]/g ) === null ) {
			return rawToolbarText;
		}

		for ( i = 0; i < barCount; i++ ) {
			if ( !$.trim( bars[ i ] ).length || bars[ i ] === "/" ) {
				toolbar.push( "/" );
				continue;
			}
			buttons = bars[ i ].split( "," );
			bar = { name: i, items: [] };
			for ( n = 0; n < buttons.length; n++ ) {
				bar.items.push( buttons[ n ] );
			}
			toolbar.push( bar );
		}
		return toolbar;
	};

	window.PresideTiptapRichEditor = PresideRichEditor;
	if ( typeof window.PresideRichEditor !== "function" ) {
		window.PresideRichEditor = PresideRichEditor;
	}

	// ---- Bootstrap --------------------------------------------------------
	// formFields.js also scans textarea.richeditor on DOMContentLoaded. The
	// data-tiptap-mounted guard in init() makes the second scan a no-op.
	// Add-on scripts ordered .after("tiptap-facade") still parse before that
	// scan, so PresideTiptap.plugins.register() lands first.
	function bootstrapRichEditors( root ) {
		var scope = ( root && root.querySelectorAll ) ? root : document;
		var tas   = scope.querySelectorAll( "textarea.richeditor:not(.frontend-container)" );
		for ( var i = 0; i < tas.length; i++ ) {
			var ta = tas[ i ];
			if ( ta.getAttribute( "data-tiptap-mounted" ) === "1" ) { continue; }
			try {
				new PresideRichEditor( ta );
			} catch ( e ) {
				if ( window.console ) { window.console.error( "[tiptap] mount failed", e ); }
			}
		}
	}
	// Expose so AJAX-loaded forms (quick-add modals etc.) can re-scan their content.
	PresideRichEditor.bootstrap = bootstrapRichEditors;

	// Warm the custom-config-file cache as early as possible so editor mounts
	// (DOM-ready) resolve it without getCustomConfig's blocking-XHR fallback.
	prefetchCustomConfig( cfreq().ckeditorConfig );

	// The frontend edit-mode dropdown (Off/Classic/Modern) composes on top of
	// core's parse-time frontendEditors.js wiring, so it must wait for
	// DOMContentLoaded even when this bundle executes late. No-ops in the admin.
	function initChrome() {
		bootstrapRichEditors( document );
		try { initEditModeSwitch(); } catch ( e ) {
			if ( window.console ) { window.console.error( "[tiptap] edit-mode switch failed", e ); }
		}
	}

	if ( document.readyState === "loading" ) {
		document.addEventListener( "DOMContentLoaded", initChrome );
	} else {
		initChrome();
	}
} )();

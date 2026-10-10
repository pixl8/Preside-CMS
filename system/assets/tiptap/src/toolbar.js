/**
 * Toolbar rendering + CKEditor-button-name -> Tiptap-command mapping.
 *
 * Preside toolbars are pipe/comma strings of CKEditor button names (parsed by the
 * facade's parseToolbarConfig). We map the names Preside uses to Tiptap commands.
 * Names with no analogue are skipped gracefully. "Format" renders a block-format
 * dropdown; "Source" toggles a raw-token view. Preside-specific buttons
 * (Widgets/ImagePicker/AttachmentPicker/PresideLink/Unlink) are registered by
 * their extensions' commands.
 */
import { ICONS } from "./icons.js";
import { toggleSource } from "./sourceView.js";
import { focusEditable } from "./editorFocus.js";
import { harvestSelectors } from "./presideStyles.js";
import { createComboPanel } from "./comboPanel.js";
import { themeEnabled, renderThemeToggle } from "./theme.js";
import { toggleMaximize, isMaximized } from "./maximize.js";
import { t } from "./i18n.js";
import { containerOf } from "./editorFrame.js";
import { openFindReplace } from "./findReplace.js";
import { openSpecialChar } from "./specialChar.js";
import { setBidi, currentDir } from "./bidi.js";
import { pluginCommand, pluginIcon } from "./pluginHost.js";

// containerOf(), not closest(): the editable is in the editing IFRAME, so a
// same-document closest() from view.dom finds nothing (see editorFrame.js).
function container( e ) { return containerOf( e.view.dom ); }

// name -> { run(editor), active(editor) }; icons come from ICONS[name]
// (own MIT-licensed set — see icons.js), with `label` as a text fallback.
// Tooltips are resolved at render time via t( "toolbar.<name>" ) - see i18n.js.
export const COMMANDS = {
	  Bold          : { label: "B",  run: e => e.chain().focus().toggleBold().run(),        active: e => e.isActive( "bold" ) }
	, Italic        : { label: "I",  run: e => e.chain().focus().toggleItalic().run(),      active: e => e.isActive( "italic" ) }
	, Underline     : { label: "U",  run: e => e.chain().focus().toggleUnderline().run(),   active: e => e.isActive( "underline" ) }
	, Strike        : { label: "S",  run: e => e.chain().focus().toggleStrike().run(),      active: e => e.isActive( "strike" ) }
	, Subscript     : { label: "x₂", run: e => e.chain().focus().toggleSubscript().run(),   active: e => e.isActive( "subscript" ) }
	, Superscript   : { label: "x²", run: e => e.chain().focus().toggleSuperscript().run(), active: e => e.isActive( "superscript" ) }
	, Blockquote    : { label: "“", run: e => e.chain().focus().toggleBlockquote().run(),  active: e => e.isActive( "blockquote" ) }
	, NumberedList  : { label: "1.", run: e => e.chain().focus().toggleOrderedList().run(), active: e => e.isActive( "orderedList" ) }
	, BulletedList  : { label: "•", run: e => e.chain().focus().toggleBulletList().run(), active: e => e.isActive( "bulletList" ) }
	, Outdent       : { label: "⇤", run: e => e.chain().focus().liftListItem( "listItem" ).run() }
	, Indent        : { label: "⇥", run: e => e.chain().focus().sinkListItem( "listItem" ).run() }
	, JustifyLeft   : { label: "≡", run: e => e.chain().focus().setTextAlign( "left" ).run(),    active: e => e.isActive( { textAlign: "left" } ) }
	, JustifyCenter : { label: "≡", run: e => e.chain().focus().setTextAlign( "center" ).run(),  active: e => e.isActive( { textAlign: "center" } ) }
	, JustifyRight  : { label: "≡", run: e => e.chain().focus().setTextAlign( "right" ).run(),   active: e => e.isActive( { textAlign: "right" } ) }
	, JustifyBlock  : { label: "≡", run: e => e.chain().focus().setTextAlign( "justify" ).run(), active: e => e.isActive( { textAlign: "justify" } ) }
	, HorizontalRule: { label: "―", run: e => e.chain().focus().setHorizontalRule().run() }
	// Insert Special Character - a modal grid of characters (src/specialChar.js).
	// The field config reaches it for `defaultConfigs.specialChars`, so this runner
	// is the one that needs more than the editor; renderNames passes cfg through.
	, SpecialChar   : { label: "Ω", run: ( e, cfg ) => { openSpecialChar( e, cfg ); return true; } }
	// Text direction. CKEditor wrote a `dir` attribute on the block and dropped any
	// inline `direction:` style; the active state is the COMPUTED direction, which
	// is why LTR reads as on in an untouched LTR field - see src/bidi.js.
	, BidiLtr       : { label: "⇥", run: e => setBidi( e, "ltr" ), active: e => currentDir( e ) === "ltr" }
	, BidiRtl       : { label: "⇤", run: e => setBidi( e, "rtl" ), active: e => currentDir( e ) === "rtl" }
	// Table is rendered as a grid-size picker (renderTable), not a plain button —
	// `run` is the keyboard/fallback path and the picker's default size.
	, Table         : { label: "▦", run: e => e.chain().focus().insertTable( { rows: 3, cols: 3, withHeaderRow: true } ).run(), active: e => e.isActive( "table" ) }
	, RemoveFormat  : { label: "Tx", run: e => e.chain().focus().unsetAllMarks().clearNodes().run() }
	, Undo          : { label: "↶", run: e => e.chain().focus().undo().run() }
	, Redo          : { label: "↷", run: e => e.chain().focus().redo().run() }
	// Find / Replace: TWO buttons, ONE dialog, opened on the tab that matches the
	// button - which is exactly what CKEditor's find plugin registered
	// (`dialogCommand( "find", { tabId: "replace" } )`). See src/findReplace.js.
	, Find          : { label: "⌕", run: e => { openFindReplace( e, "find" ); return true; } }
	, Replace       : { label: "⇄", run: e => { openFindReplace( e, "replace" ); return true; } }
	, Maximize      : { label: "⛶", run: e => toggleMaximize( container( e ), e ), active: e => isMaximized( container( e ) ) }
	, PresideLink      : { run: e => e.commands.openPresideLinkPicker(), active: e => e.isActive( "presideLink" ) }
	, PresideUnlink    : { run: e => e.chain().focus().unsetPresideLink().run() }
	, PresideAnchor    : { run: e => e.commands.openPresideAnchorDialog() }
	, Widgets          : { run: e => e.commands.openPresideWidgetPicker() }
	, ImagePicker      : { run: e => e.commands.openPresideImagePicker() }
	, AttachmentPicker : { run: e => e.commands.openPresideAttachmentPicker() }
	, CodeSnippet      : { run: e => e.chain().focus().toggleCodeBlock().run(), active: e => e.isActive( "codeBlock" ) }
};

/**
 * Resolve a toolbar button name to its command - OURS first, then any a
 * registered plugin contributes for this field (src/pluginHost.js).
 *
 * Everything that renders or tests a button name goes through here rather than
 * indexing COMMANDS directly, which is what lets a dependent extension add a
 * button name at all. Built-ins always win: a plugin must not be able to
 * silently re-point `Bold`.
 *
 * Returns null for an unknown name, exactly as `COMMANDS[ name ]` did - so
 * every existing "unknown names are skipped gracefully" path is unchanged, and
 * a plugin whose `enabled( cfg )` says no is indistinguishable from one that
 * never registered (which is what keeps the separator tidying honest - see
 * tidySeparators).
 */
export function command( name, cfg ) {
	return COMMANDS[ name ] || pluginCommand( name, cfg );
}

/**
 * The icon markup for a button name: our own set, else the raw SVG string a
 * plugin's command carries. Returns "" when there is neither, so callers can
 * fall back to a text label as they always did.
 */
export function iconFor( name, cmd ) {
	return ICONS[ name ] || ( cmd && cmd.icon ) || pluginIcon( name ) || "";
}

// Format dropdown entries come from defaultConfigs.format_tags (CKEditor's
// `format_tags`, core default 'p;h1;h2;h3;h4;h5;h6;pre;div') filtered to the
// block formats the editor can actually apply. Labels come from i18n
// ("format.<tag>" keys).
const FORMAT_TAGS = [ "p", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "div" ];
const DEFAULT_FORMAT_TAGS = "p;h1;h2;h3;h4;h5;h6;pre";

function formatOpts( cfg ) {
	const raw  = ( cfg && cfg.defaultConfigs && cfg.defaultConfigs.format_tags ) || DEFAULT_FORMAT_TAGS;
	const opts = [];
	String( raw ).split( ";" ).forEach( function( tag ) {
		tag = tag.trim().toLowerCase();
		if ( FORMAT_TAGS.indexOf( tag ) !== -1 ) { opts.push( { v: tag, label: t( "format." + tag ) } ); }
	} );
	return opts.length ? opts : formatOpts( { defaultConfigs: { format_tags: DEFAULT_FORMAT_TAGS } } );
}

/**
 * Documents a host-document popover must listen to in order to close.
 *
 * The editable is in the EDITING IFRAME, so a mousedown in it never reaches the
 * host document - a host-only listener leaves the popover open when the user
 * clicks back into their content. (Same boundary as the slash menu's key
 * handling, and as containerOf() vs closest().)
 */
function popoverDocs( editor ) {
	const docs  = [ document ];
	const edDoc = editor && editor.view && editor.view.dom.ownerDocument;
	if ( edDoc && edDoc !== document ) { docs.push( edDoc ); }
	return docs;
}

// Render a list of CKEditor button names into `groupEl`, sharing the exact
// per-name behaviour of the main toolbar (Justify* collapse into one dropdown,
// Format/Styles/Table/Source/Theme special cases, plain buttons with is-active
// updaters). Extracted so the selection bubble (Modern inline mode) builds its
// filtered button set from the SAME renderers — one implementation, two hosts.
// `opts.skip` drops names entirely (the bubble excludes insert/global commands).
// The two controls CKEditor implements as richcombos, whose constructor sets
// `canGroup:!1` - so the toolbar renderer closes any open toolgroup and emits
// them OUTSIDE it, each as its own bordered block (.cke_combo_button). Nothing
// else here is a combo: CKEditor had Table as a plain button and alignment as
// four plain buttons, so those triggers stay inside their group.
const COMBO_NAMES = [ "Format", "Styles" ];

/**
 * Render a toolbar ROW.
 *
 * `rowEl` is the row, not a group: this walks the names and opens/closes
 * `.tiptap-toolbar-group` spans as it goes, exactly as CKEditor's renderer does
 * with `A ? e||(open toolgroup) : e&&(close toolgroup)`. Groupable controls
 * accumulate into the current group; a combo closes it and stands alone.
 *
 * Returns { themeRendered } (whether a Theme/DarkMode toggle was rendered).
 */
export function renderNames( rowEl, names, editor, cfg, updaters, opts ) {
	opts = opts || {};
	const skip = opts.skip || [];
	let themeRendered = false;

	// Rendered top-level pieces in order: groups, standalone combos, and the
	// row-level separators between them. Collected first so empty groups (every
	// name in them turned out to be unknown) can be dropped before appending.
	const parts = [];
	let group      = null;    // the open group - CKEditor's `e`
	let pendingSep = false;   // a deferred separator - CKEditor's `k`

	function openGroup() {
		if ( !group ) {
			group = document.createElement( "span" );
			group.className = "tiptap-toolbar-group";
			parts.push( { kind: "group", el: group } );
		}
		return group;
	}

	// CKEditor emits the deferred separator AFTER closing the group, so one
	// between a group and a combo lands at row level, between the two blocks.
	function flushSep( target ) {
		if ( !pendingSep ) { return; }
		pendingSep = false;
		const sep = document.createElement( "span" );
		sep.className = "tiptap-toolbar-sep";
		if ( target ) { target.appendChild( sep ); } else { parts.push( { kind: "sep", el: sep } ); }
	}

	function placeGroupable( el ) { const g = openGroup(); flushSep( g ); g.appendChild( el ); }
	function placeCombo( el ) {
		group = null;                       // close it
		flushSep( null );
		el.classList.add( "tiptap-combo" );
		parts.push( { kind: "combo", el: el } );
	}

	// The four Justify* buttons collapse into ONE dropdown (renderAlign) to save
	// a lot of toolbar width. Scoped to the group, and only when the group names
	// more than one of them: a toolbar naming a single alignment gets a plain
	// button, because a one-item menu is worse than the button it replaced.
	const alignNames    = names.filter ? names.filter( function( n ) { return ALIGN_NAMES.indexOf( n ) !== -1 && skip.indexOf( n ) === -1; } ) : [];
	const collapseAlign = alignNames.length > 1;

	names.forEach( function( name ) {
		if ( skip.indexOf( name ) !== -1 ) { return; }
		// Render the dropdown where the first alignment button sat and drop the
		// rest. The menu offers EXACTLY the ones this toolbar named - never all
		// four - so a site that deliberately withheld e.g. Justify keeps it out.
		if ( collapseAlign && ALIGN_NAMES.indexOf( name ) !== -1 ) {
			if ( name === alignNames[ 0 ] ) { placeGroupable( renderAlign( editor, updaters, alignNames ) ); }
			return;
		}
		// `k = e && t`: a separator is only remembered while a group is open, so one
		// between two combos is dropped - as it is in CKEditor.
		if ( name === "-" ) { pendingSep = !!group; return; }

		if ( name === "Format" ) { placeCombo( renderFormat( editor, updaters, cfg ) ); return; }
		if ( name === "Styles" ) { placeCombo( renderStyles( editor, updaters, cfg ) ); return; }
		if ( name === "Table"  ) { placeGroupable( renderTable( editor, updaters ) ); return; }
		if ( name === "Source" ) { placeGroupable( renderSource( editor ) ); return; }
		if ( name === "Theme" || name === "DarkMode" ) {
			if ( themeEnabled( cfg ) ) { placeGroupable( renderThemeToggle() ); themeRendered = true; }
			return;
		}

		// Ours, or a plugin's - and an unknown/disabled name is still simply skipped.
		const cmd = command( name, cfg );
		if ( !cmd ) { return; } // unknown / not-implemented button — skip

		const btn   = document.createElement( "button" );
		const title = t( "toolbar." + name.toLowerCase() );
		const icon  = iconFor( name, cmd );
		btn.type = "button";
		btn.className = "tiptap-btn";
		btn.title = title;
		btn.setAttribute( "aria-label", title );
		if ( icon ) { btn.innerHTML = icon; }
		else { btn.textContent = cmd.label || name; }
		btn.setAttribute( "data-cmd", name );
		// Refresh the is-active states straight after the click, not only on the next
		// transaction: Maximize toggles CHROME, so it changes its own active state
		// without touching the document, and the button would otherwise stay unlit
		// until the next edit.
		btn.addEventListener( "click", function( ev ) {
			ev.preventDefault();
			cmd.run( focusEditable( editor ), cfg );
			updaters.forEach( function( u ) { u(); } );
		} );
		placeGroupable( btn );

		if ( cmd.active ) { updaters.push( function() { btn.classList.toggle( "is-active", !!cmd.active( editor ) ); } ); }
	} );

	// Drop groups nothing rendered into (every name in them was unknown), tidy the
	// separators inside each surviving group, then drop row-level separators that
	// no longer sit between two blocks.
	const kept = parts.filter( function( p ) { return p.kind !== "group" || p.el.childNodes.length; } );
	kept.forEach( function( p ) { if ( p.kind === "group" ) { tidySeparators( p.el ); } } );

	let prevWasBlock = false;
	const final = [];
	kept.forEach( function( p ) {
		if ( p.kind === "sep" ) { if ( prevWasBlock ) { final.push( p ); prevWasBlock = false; } return; }
		prevWasBlock = true;
		final.push( p );
	} );
	while ( final.length && final[ final.length - 1 ].kind === "sep" ) { final.pop(); }
	final.forEach( function( p ) { rowEl.appendChild( p.el ); } );

	return { themeRendered: themeRendered };
}

/**
 * A separator only means anything BETWEEN two controls, so drop the ones that end
 * up leading, trailing or doubled.
 *
 * It has to run AFTER rendering rather than filter the name list, because what
 * actually renders is not knowable up front: unknown/unavailable button names are
 * skipped, and the four Justify* names collapse into one dropdown - so a config
 * like "Cut,Copy,-,Undo" (Cut/Copy have no analogue) left the separator leading its
 * group. Against the group's own border that read as a doubled line, which is
 * exactly what looked broken.
 */
function tidySeparators( groupEl ) {
	function isSep( el ) { return el && el.classList && el.classList.contains( "tiptap-toolbar-sep" ); }

	let prevWasSep = true;   // the group's own edge counts as a separator
	Array.prototype.slice.call( groupEl.children ).forEach( function( el ) {
		if ( !isSep( el ) ) { prevWasSep = false; return; }
		if ( prevWasSep ) { el.remove(); return; }
		prevWasSep = true;
	} );
	while ( isSep( groupEl.lastElementChild ) ) { groupEl.lastElementChild.remove(); }
}

export function buildToolbar( el, editor, parsedToolbar, cfg ) {
	el.innerHTML = "";

	const groups   = normaliseToolbar( parsedToolbar );
	const updaters = [];
	// The light/dark toggle normally lives in the footer status bar (the facade
	// puts it there); the toolbar only renders one when a toolbar config names it
	// explicitly ("Theme" / "DarkMode"), which is reported back so the facade
	// doesn't add a second.
	let themeRendered = false;

	groups.forEach( function( group ) {
		if ( group === "/" ) { el.appendChild( document.createElement( "br" ) ); return; }

		// renderNames opens its own .tiptap-toolbar-group spans as it walks the
		// names, because a combo (Format/Styles) is canGroup:false and has to land
		// OUTSIDE any group, as its own block - so one pipe-delimited bar can render
		// as several blocks rather than exactly one.
		const res = renderNames( el, group, editor, cfg, updaters );
		if ( res.themeRendered ) { themeRendered = true; }
	} );

	const refresh = function() { updaters.forEach( function( u ) { u(); } ); };
	editor.on( "selectionUpdate", refresh );
	editor.on( "transaction", refresh );
	refresh();

	// `refresh` is returned because one piece of toolbar state does not depend on
	// the document at all: the Styles combo's enabled/disabled state is derived from
	// the harvested content stylesheets, and those load ASYNCHRONOUSLY. Without a
	// re-run on load the first refresh() sees no sheets, finds no applicable style
	// and leaves the combo greyed out until the user happens to cause a transaction.
	return { themeEnabled: themeEnabled( cfg ), themeRendered: themeRendered, refresh: refresh };
}

// Custom dropdown (not a native <select>) so it opens directly under the button
// and each item previews its own style — matching CKEditor's Format menu.
function renderFormat( editor, updaters, cfg ) {
	const wrap = document.createElement( "span" );
	wrap.className = "tiptap-dropdown";

	const trigger = document.createElement( "button" );
	trigger.type = "button";
	trigger.className = "tiptap-btn tiptap-dropdown-trigger";
	trigger.setAttribute( "data-cmd", "Format" );
	// `tiptap-caret`/`tiptap-lbl`, never the bare `caret`/`lbl`: those are BOOTSTRAP
	// and Ace class names, and in the admin bootstrap's own `.caret` rule drew its
	// border triangle on top of ours - every dropdown showed two stacked arrows. The
	// caret itself is drawn in CSS (see .tiptap-caret) rather than printed as a
	// glyph, so there is nothing for a theme to double up.
	trigger.innerHTML = '<span class="tiptap-lbl"></span><span class="tiptap-caret" aria-hidden="true"></span>';
	trigger.querySelector( ".tiptap-lbl" ).textContent = t( "toolbar.format" );

	// The menu is an IFRAME with the site's content CSS linked in unmodified, which
	// is what makes each entry preview in the site's real typography - see
	// comboPanel.js for why nothing in the host document can do that.
	let menu = null;   // the list, inside the panel frame - only after first open

	const panel = createComboPanel( {
		  stylesheets: cfg && cfg.stylesheets
		, editor     : editor
		, anchor     : trigger
		, anchorWrap : wrap
		, title      : t( "format.panelTitle" )
		// The item list never changes (it is `format_tags`), so it is built once when
		// the panel is - CKEditor's combo init(), which createPanel() calls.
		, build      : function( pdoc, listEl ) {
			menu = listEl;

			// CKEditor's format plugin opens its panel with a single
			// startGroup( lang.format.panelTitle ) header ("Paragraph Format").
			const head = pdoc.createElement( "div" );
			head.className = "tiptap-dropdown-group";
			head.textContent = t( "format.panelTitle" );
			listEl.appendChild( head );

			formatOpts( cfg ).forEach( function( o ) {
				const item = pdoc.createElement( "div" );
				item.className = "tiptap-dropdown-item tiptap-fmt-preview fmt-" + o.v;
				// The entry IS a real h1..h6/p/pre/div, which the content CSS in this
				// document styles - CKEditor's own style.buildPreview() output.
				const inner = pdoc.createElement( o.v );
				inner.textContent = o.label;
				item.appendChild( inner );
				item.addEventListener( "mousedown", function( ev ) {
					ev.preventDefault(); // keep the editor selection
					applyFormat( editor, o.v );
					closeMenu();
				} );
				listEl.appendChild( item );
			} );
			markActive();
		}
	} );

	// The panel owns close-on-outside-click and close-on-scroll-away itself: it has
	// to listen on the EDITING FRAME's document as well as the host, and only it
	// knows about the frame.
	function closeMenu() { panel.close(); }
	function openMenu() { panel.open(); markActive(); }

	function markActive() {
		if ( !menu ) { return; }
		const v = currentFormat( editor );
		Array.prototype.forEach.call( menu.children, function( el ) {
			el.classList.toggle( "active", el.classList.contains( "fmt-" + v ) );
		} );
	}

	trigger.addEventListener( "click", function( ev ) {
		ev.preventDefault();
		if ( panel.isOpen() ) { closeMenu(); } else { openMenu(); }
	} );

	wrap.appendChild( trigger );

	updaters.push( function() {
		const v = currentFormat( editor );
		trigger.querySelector( ".tiptap-lbl" ).textContent = FORMAT_TAGS.indexOf( v ) !== -1 ? t( "format." + v ) : t( "toolbar.format" );
		markActive();
	} );

	editor.on( "destroy", panel.destroy );
	return wrap;
}

function applyFormat( editor, v ) {
	const c = focusEditable( editor ).chain().focus();
	if ( v === "p" ) { c.setParagraph().run(); }
	else if ( v === "pre" ) { c.setNode( "codeBlock" ).run(); }
	else if ( v === "div" ) { c.setNode( "presideDiv" ).run(); }
	else { c.setNode( "heading", { level: parseInt( v.slice( 1 ), 10 ) } ).run(); }
}
function currentFormat( editor ) {
	for ( let n = 1; n <= 6; n++ ) { if ( editor.isActive( "heading", { level: n } ) ) { return "h" + n; } }
	if ( editor.isActive( "codeBlock" ) ) { return "pre"; }
	if ( editor.isActive( "presideDiv" ) ) { return "div"; }
	return "p";
}

// ---- Alignment dropdown ------------------------------------------------------
// CKEditor gave alignment four separate toolbar buttons; four buttons for one
// mutually-exclusive property is a lot of width, so they collapse into one
// trigger + a compact row of icons (as reactjs-tiptap-editor does).
//
// Unlike that editor's fixed "AlignJustify" trigger icon, ours shows the CURRENT
// alignment, so the state is readable without opening the menu - matching how the
// Format dropdown displays its current value.
//
// Button name -> the textAlign value it applies. Order here is CKEditor's
// canonical order, but the menu follows the toolbar's own order (see renderAlign).
const ALIGN_VALUES = {
	  JustifyLeft  : "left"
	, JustifyCenter: "center"
	, JustifyRight : "right"
	, JustifyBlock : "justify"
};
const ALIGN_NAMES = Object.keys( ALIGN_VALUES );

function currentAlign( editor ) {
	for ( let i = 0; i < ALIGN_NAMES.length; i++ ) {
		const v = ALIGN_VALUES[ ALIGN_NAMES[ i ] ];
		if ( editor.isActive( { textAlign: v } ) ) { return ALIGN_NAMES[ i ]; }
	}
	return null;
}

function renderAlign( editor, updaters, names ) {
	const wrap = document.createElement( "span" );
	wrap.className = "tiptap-dropdown tiptap-align-picker";

	const title   = t( "toolbar.align" );
	const trigger = document.createElement( "button" );
	trigger.type = "button";
	trigger.className = "tiptap-btn";
	trigger.title = title;
	trigger.setAttribute( "aria-label", title );
	trigger.setAttribute( "data-cmd", "Align" );
	trigger.setAttribute( "aria-haspopup", "true" );

	// Icon slot + caret. The icon is swapped by the updater below, so the caret
	// lives in its own span rather than being rewritten with it.
	const iconEl = document.createElement( "span" );
	iconEl.className = "tiptap-align-icon";
	const caret = document.createElement( "span" );
	caret.className = "tiptap-caret";   // never bare `caret` - see renderFormat
	caret.setAttribute( "aria-hidden", "true" );
	trigger.appendChild( iconEl );
	trigger.appendChild( caret );

	const menu = document.createElement( "div" );
	menu.className = "tiptap-dropdown-menu tiptap-align-menu";

	const docs = popoverDocs( editor );
	function closeMenu() { menu.classList.remove( "open" ); docs.forEach( d => d.removeEventListener( "mousedown", onDocDown, true ) ); }
	function openMenu()  { menu.classList.add( "open" );    docs.forEach( d => d.addEventListener( "mousedown", onDocDown, true ) ); }
	function onDocDown( e ) { if ( !wrap.contains( e.target ) ) { closeMenu(); } }

	const itemBtns = {};
	names.forEach( function( name ) {
		const label = t( "toolbar." + name.toLowerCase() );
		const item  = document.createElement( "button" );
		item.type = "button";
		item.className = "tiptap-btn tiptap-align-item";
		item.title = label;
		item.setAttribute( "aria-label", label );
		item.innerHTML = ICONS[ name ];
		item.addEventListener( "mousedown", function( e ) { e.preventDefault(); } ); // keep the selection
		item.addEventListener( "click", function( e ) {
			e.preventDefault();
			COMMANDS[ name ].run( focusEditable( editor ) );
			closeMenu();
		} );
		itemBtns[ name ] = item;
		menu.appendChild( item );
	} );

	trigger.addEventListener( "click", function( ev ) {
		ev.preventDefault();
		if ( menu.classList.contains( "open" ) ) { closeMenu(); } else { openMenu(); }
	} );

	wrap.appendChild( trigger );
	wrap.appendChild( menu );

	updaters.push( function() {
		const cur = currentAlign( editor );
		// Show the current alignment, falling back to the first option this toolbar
		// offers (left, in every real config) when nothing is explicitly set.
		iconEl.innerHTML = ICONS[ cur && itemBtns[ cur ] ? cur : names[ 0 ] ];
		// Only "active" when an alignment really is applied - the fallback icon
		// above must not make the button look permanently on.
		trigger.classList.toggle( "is-active", !!( cur && itemBtns[ cur ] ) );
		names.forEach( function( n ) { itemBtns[ n ].classList.toggle( "is-active", cur === n ); } );
	} );

	return wrap;
}

// ---- Table grid-size picker --------------------------------------------------
// Click the toolbar button -> a grid of cells; hover (or drag) to choose the
// size, release/click to insert. Replaces the old fixed 3x3 insert.
//
// The grid GROWS towards the max as you reach its current edge, rather than
// showing the full 10x10 up front: the common table is small, and a big grid
// makes the small sizes a fiddly target. Dragging past the edge keeps extending,
// so the large sizes stay reachable without a second interaction.
const TABLE_GRID_MAX  = 10;
const TABLE_GRID_INIT = 5;

// "With header row" choice, remembered across opens and across editors on the
// page (a page-level preference, not a per-field one - same reasoning as the
// theme toggle, minus the persistence: it is a per-insert decision, so it is not
// worth a localStorage entry).
let withHeaderRowPref = true;

function renderTable( editor, updaters ) {
	const wrap = document.createElement( "span" );
	wrap.className = "tiptap-dropdown tiptap-table-picker";

	const title   = t( "toolbar.table" );
	// Deliberately NOT .tiptap-dropdown-trigger: that class means "a control whose
	// label is its current value" (Format/Styles), and things that enumerate the
	// toolbar skip those. This is an ordinary icon button that happens to open a
	// popover, so it keeps its stable title and stays enumerable.
	const trigger = document.createElement( "button" );
	trigger.type = "button";
	trigger.className = "tiptap-btn";
	trigger.title = title;
	trigger.setAttribute( "aria-label", title );
	trigger.setAttribute( "data-cmd", "Table" );
	trigger.setAttribute( "aria-haspopup", "true" );
	trigger.innerHTML = ICONS.Table;

	const menu = document.createElement( "div" );
	menu.className = "tiptap-dropdown-menu tiptap-table-grid-menu";

	const grid = document.createElement( "div" );
	grid.className = "tiptap-table-grid";
	grid.style.touchAction = "none";

	const caption = document.createElement( "div" );
	caption.className = "tiptap-table-grid-caption";

	// "With header row" is a real choice, not a hidden default: Preside content
	// uses <th> widely, and the old fixed insert always made one. Sticky within
	// the session so a user who never wants headers stops fighting it.
	const hdrLabel = document.createElement( "label" );
	hdrLabel.className = "tiptap-table-grid-header";
	const hdrBox = document.createElement( "input" );
	hdrBox.type = "checkbox";
	hdrBox.checked = withHeaderRowPref;
	hdrLabel.appendChild( hdrBox );
	hdrLabel.appendChild( document.createTextNode( " " + t( "table.withheaderrow" ) ) );
	hdrBox.addEventListener( "change", function() { withHeaderRowPref = hdrBox.checked; } );
	// Toggling the box must not count as picking a cell, nor close the menu.
	hdrLabel.addEventListener( "mousedown", function( e ) { e.stopPropagation(); } );
	hdrLabel.addEventListener( "pointerdown", function( e ) { e.stopPropagation(); } );

	let rows = TABLE_GRID_INIT, cols = TABLE_GRID_INIT;   // grid extent
	let selR = 0, selC = 0;                               // hovered size
	let dragging = false;

	function build() {
		grid.innerHTML = "";
		for ( let r = 1; r <= rows; r++ ) {
			const rowEl = document.createElement( "div" );
			rowEl.className = "tiptap-table-grid-row";
			for ( let c = 1; c <= cols; c++ ) {
				const cell = document.createElement( "span" );
				cell.className = "tiptap-table-grid-cell";
				cell.setAttribute( "data-r", r );
				cell.setAttribute( "data-c", c );
				rowEl.appendChild( cell );
			}
			grid.appendChild( rowEl );
		}
		paint();
	}

	function paint() {
		Array.prototype.forEach.call( grid.querySelectorAll( ".tiptap-table-grid-cell" ), function( cell ) {
			const r = +cell.getAttribute( "data-r" ), c = +cell.getAttribute( "data-c" );
			cell.classList.toggle( "is-on", r <= selR && c <= selC );
		} );
		caption.textContent = selR && selC
			? t( "table.gridsize", { rows: selR, cols: selC } )
			: t( "table.insert" );
	}

	// Grow towards the max when the pointer reaches the current edge.
	function select( r, c ) {
		selR = r; selC = c;
		let grew = false;
		if ( r === rows && rows < TABLE_GRID_MAX ) { rows++; grew = true; }
		if ( c === cols && cols < TABLE_GRID_MAX ) { cols++; grew = true; }
		if ( grew ) { build(); } else { paint(); }
	}

	// elementFromPoint (not the event target) so a pointer-captured drag still
	// tracks cells: with capture set, every move event targets the grid itself.
	function cellAt( e ) {
		const el = document.elementFromPoint( e.clientX, e.clientY );
		const cell = el && el.closest ? el.closest( ".tiptap-table-grid-cell" ) : null;
		return ( cell && grid.contains( cell ) ) ? cell : null;
	}
	function trackFrom( e ) {
		const cell = cellAt( e );
		if ( !cell ) { return false; }
		select( +cell.getAttribute( "data-r" ), +cell.getAttribute( "data-c" ) );
		return true;
	}

	grid.addEventListener( "pointerdown", function( e ) {
		if ( !e.isPrimary || ( e.pointerType === "mouse" && e.button !== 0 ) ) { return; }
		if ( !trackFrom( e ) ) { return; }
		e.preventDefault();
		dragging = true;
		try { grid.setPointerCapture( e.pointerId ); } catch ( err ) {}
	} );
	grid.addEventListener( "pointermove", function( e ) {
		// Hover tracks even without a drag - a plain click-then-click is the
		// mouse-friendly path, the drag is the touch-friendly one.
		trackFrom( e );
	} );
	grid.addEventListener( "pointerup", function( e ) {
		trackFrom( e );
		if ( dragging ) {
			dragging = false;
			try { if ( grid.hasPointerCapture( e.pointerId ) ) { grid.releasePointerCapture( e.pointerId ); } } catch ( err ) {}
		}
		if ( selR && selC ) { insert(); }
	} );
	grid.addEventListener( "pointercancel", function( e ) {
		dragging = false;
		try { if ( grid.hasPointerCapture( e.pointerId ) ) { grid.releasePointerCapture( e.pointerId ); } } catch ( err ) {}
	} );
	grid.addEventListener( "pointerleave", function() {
		if ( !dragging ) { selR = 0; selC = 0; paint(); }
	} );

	function insert() {
		const r = selR, c = selC;
		closeMenu();
		focusEditable( editor ).chain().focus().insertTable( { rows: r, cols: c, withHeaderRow: hdrBox.checked } ).run();
	}

	function reset() {
		rows = TABLE_GRID_INIT; cols = TABLE_GRID_INIT;
		selR = 0; selC = 0;
		hdrBox.checked = withHeaderRowPref;
		build();
	}
	const docs = popoverDocs( editor );
	function closeMenu() {
		menu.classList.remove( "open" );
		docs.forEach( function( d ) {
			d.removeEventListener( "mousedown", onDocDown, true );
			d.removeEventListener( "keydown", onKeyDown, true );
		} );
	}
	function openMenu() {
		reset();
		menu.classList.add( "open" );
		docs.forEach( function( d ) {
			d.addEventListener( "mousedown", onDocDown, true );
			d.addEventListener( "keydown", onKeyDown, true );
		} );
	}
	function onDocDown( e ) { if ( !wrap.contains( e.target ) ) { closeMenu(); } }
	function onKeyDown( e ) { if ( e.key === "Escape" ) { e.stopPropagation(); closeMenu(); } }

	trigger.addEventListener( "click", function( ev ) {
		ev.preventDefault();
		if ( menu.classList.contains( "open" ) ) { closeMenu(); } else { openMenu(); }
	} );

	menu.appendChild( grid );
	menu.appendChild( caption );
	menu.appendChild( hdrLabel );
	wrap.appendChild( trigger );
	wrap.appendChild( menu );

	updaters.push( function() { trigger.classList.toggle( "is-active", editor.isActive( "table" ) ); } );

	return wrap;
}

// ---- Styles dropdown ---------------------------------------------------------
// CKEditor's stylesheetParser feature: class-based styles are harvested from the
// field's content stylesheets (selectors matching stylesheetParser_validSelectors)
// plus any static defaultConfigs.stylesSet entries. Built lazily on open, because
// the stylesheets load asynchronously.

/**
 * CKEditor's style TYPE, which is what decides both the panel group an entry
 * lands in and whether it is applicable at all. It comes from two element tables
 * in the `CKEDITOR.style` constructor:
 *
 *   this.type = a.type || ( A[c] ? STYLE_BLOCK : L[c] ? STYLE_OBJECT : STYLE_INLINE )
 *
 *   A -> BLOCK : address,div,h1..h6,p,pre,section,header,footer,nav,article,aside,
 *                figure,dialog,hgroup,time,meter,menu,command,keygen,output,
 *                progress,details,datagrid,datalist
 *   L -> OBJECT: a,blockquote,embed,hr,img,li,object,ol,table,td,tr,th,ul,dl,dt,dd,
 *                form,audio,video
 *   anything else -> INLINE
 *
 * and `checkApplicable` then gates on it:
 *
 *   case STYLE_OBJECT: return !!path.contains( this.element )
 *   case STYLE_BLOCK : return !!path.blockLimit.getDtd()[ this.element ]
 *   (INLINE falls through to `return true` - always applicable)
 *
 * Over the tags we can actually apply that is BLOCK: p,h1..h6,pre,div / OBJECT:
 * ul,ol,li,table / INLINE: span - which is exactly the old `existingOnly` flag,
 * so the partition was already right; it was simply never used to filter.
 */
const BLOCK = 1, INLINE = 2, OBJECT = 3;   // CKEDITOR.STYLE_BLOCK / _INLINE / _OBJECT

const STYLE_TYPES = {
	  p    : { type: BLOCK,  node: "paragraph" }
	, h1   : { type: BLOCK,  node: "heading", attrs: { level: 1 } }
	, h2   : { type: BLOCK,  node: "heading", attrs: { level: 2 } }
	, h3   : { type: BLOCK,  node: "heading", attrs: { level: 3 } }
	, h4   : { type: BLOCK,  node: "heading", attrs: { level: 4 } }
	, h5   : { type: BLOCK,  node: "heading", attrs: { level: 5 } }
	, h6   : { type: BLOCK,  node: "heading", attrs: { level: 6 } }
	, pre  : { type: BLOCK,  node: "codeBlock" }
	, div  : { type: BLOCK,  node: "presideDiv" }
	, ul   : { type: OBJECT, node: "bulletList" }
	, ol   : { type: OBJECT, node: "orderedList" }
	, li   : { type: OBJECT, node: "listItem" }
	, table: { type: OBJECT, node: "table" }
	// INLINE. Every one of these is a tag Preside's own default
	// stylesheetParser_validSelectors allows, and CKEditor lists them
	// unconditionally (checkApplicable returns true for INLINE), so a Bootstrap-ish
	// site's `small.text-muted` / `strong.text-danger` really does appear there.
	// `strong`/`b` resolve onto StarterKit's bold and `em`/`i` onto its italic -
	// which is why presideAttributes gives those two marks a `class` (a second mark
	// parsing <strong> would double-apply); `span`/`small` are presideInlineStyle,
	// distinguished by its `tag` attribute.
	, span  : { type: INLINE, mark: "presideInlineStyle", markAttrs: { tag: "span" } }
	, small : { type: INLINE, mark: "presideInlineStyle", markAttrs: { tag: "small" } }
	, strong: { type: INLINE, mark: "bold" }
	, b     : { type: INLINE, mark: "bold" }
	, em    : { type: INLINE, mark: "italic" }
	, i     : { type: INLINE, mark: "italic" }
};

// CKEditor's own sort weight: `i + 1000 * ( OBJECT?1 : BLOCK?2 : 3 )`, so the
// panel reads Object, then Block, then Inline, each preserving harvest order.
function styleWeight( item, i ) {
	const type = STYLE_TYPES[ item.tag ].type;
	return i + 1000 * ( type === OBJECT ? 1 : type === BLOCK ? 2 : 3 );
}

/**
 * checkApplicable(), in Tiptap terms.
 *
 * OBJECT: `path.contains( element )` asks whether an ancestor of that tag exists,
 *   which is `editor.isActive( node )` here.
 * BLOCK : `path.blockLimit.getDtd()[ element ]` asks whether that element is a
 *   legal child of the nearest block limit - a question about the SCHEMA, not
 *   about whether applying it would change anything. `can().setNode()` answers
 *   the schema half (no heading inside a code block, say), but it is false for
 *   the block the caret is ALREADY in, which would hide `p.lead` in every
 *   paragraph - the same trap that makes `can().setParagraph()` useless for the
 *   Format dropdown. So an already-active node counts as applicable too.
 * INLINE: unconditionally true, as CKEditor's fall-through return is.
 */
function styleApplicable( editor, item ) {
	const d = STYLE_TYPES[ item.tag ];
	if ( !d ) { return false; }
	if ( d.type === INLINE ) { return true; }
	if ( d.type === OBJECT ) { return editor.isActive( d.node ); }
	if ( editor.isActive( d.node, d.attrs || {} ) ) { return true; }
	try { return editor.can().setNode( d.node, d.attrs || {} ); } catch ( e ) { return true; }
}
const DEFAULT_VALID_SELECTORS = "^(h[1-6]|p|span|pre|li|ul|ol|dl|dt|dd|small|i|b|em|strong|table)\\.\\w+";
const DEFAULT_SKIP_SELECTORS  = "(^body\\.|^\\.)";

/**
 * Reduce a document's raw selector list to `element.class` pairs, EXACTLY as
 * CKEditor's stylesheetparser does (its `function h`, in the vendored
 * ckeditor.js). The order of operations is the whole point:
 *
 *   join(" ") -> `, > + ~` become spaces -> strip `[attr...` -> strip `#id`
 *   -> strip `:pseudo`/`::pseudo` -> collapse whitespace -> SPLIT ON SPACE
 *
 * so every SIMPLE selector is tested on its own, and the pair is then
 * `token.split(".")` taking `[0]` as the element and `[1]` as the class - the
 * FIRST class only.
 *
 * Testing the raw `selectorText` instead is what produced the junk entries this
 * replaces: `table.table-ruled tbody tr td` matched on its `table.table-` prefix
 * and the whole descendant tail became the "class name", so the menu offered
 * `table.table-ruled tbody tr td` as a label and set it as three bogus classes.
 * Normalised, that selector yields exactly one usable pair, `table.table-ruled`.
 */
function selectorPairs( selectors, valid, skip ) {
	let s = selectors.join( " " );
	s = s.replace( /(,|>|\+|~)/g, " " );
	// CKEditor's own pattern here is /\[[^\]]*/g, which strips the `[` and the
	// attribute but LEAVES the closing bracket - so `p.lead[data-x]` came out as
	// `p.lead]`, a broken class that also deduped separately from a real `p.lead`.
	// The `\]?` is a deliberate fix, not a transcription slip.
	s = s.replace( /\[[^\]]*\]?/g, "" );
	s = s.replace( /#[^\s]*/g, "" );
	s = s.replace( /\:{1,2}[^\s]*/g, "" );
	s = s.replace( /\s+/g, " " );

	const out  = [];
	const seen = {};
	s.split( " " ).forEach( function( token ) {
		if ( !token || !valid.test( token ) || skip.test( token ) || seen[ token ] ) { return; }
		seen[ token ] = true;
		const parts = token.split( "." );
		out.push( { element: parts[ 0 ].toLowerCase(), className: parts[ 1 ] } );
	} );
	return out;
}

function selectorRegex( source, fallback ) {
	try { return new RegExp( source || fallback ); } catch ( e ) { return new RegExp( fallback ); }
}

export function styleItems( cfg, editor ) {
	const dc    = ( cfg && cfg.defaultConfigs ) || {};
	const items = [];
	const seen  = {};

	const valid = selectorRegex( dc.stylesheetParser_validSelectors, DEFAULT_VALID_SELECTORS );
	const skip  = selectorRegex( dc.stylesheetParser_skipSelectors, DEFAULT_SKIP_SELECTORS );

	function add( tag, className, name ) {
		tag = String( tag ).toLowerCase();
		const key = tag + "." + className;
		if ( !STYLE_TYPES[ tag ] || !className || seen[ key ] ) { return; }
		seen[ key ] = true;
		items.push( { tag: tag, className: className, name: name || key } );
	}

	// Static stylesSet entries ({ name, element, attributes: { class } }).
	// CKEditor `concat`s the harvested pairs onto these, so both arrive in one
	// shape; static entries come first and keep their authored `name`.
	( Array.isArray( dc.stylesSet ) ? dc.stylesSet : [] ).forEach( function( s ) {
		const cls = s && s.attributes && s.attributes[ "class" ];
		if ( s && s.element && cls ) { add( s.element, cls, s.name ); }
	} );

	// Harvested from the editable's OWN document - the editing frame's sheets for
	// a boxed editor, the site page's for a Modern inline one.
	const doc = editor && editor.view && editor.view.dom.ownerDocument;
	selectorPairs( harvestSelectors( doc ), valid, skip ).forEach( function( p ) {
		add( p.element, p.className );
	} );

	return items;
}

function applyStyle( editor, item ) {
	const inline = STYLE_TYPES[ item.tag ];
	if ( inline && inline.mark ) {
		// CKEditor's onClick calls removeStyle when the style is already active,
		// which takes the element AND its class off - so toggling off unsets the
		// whole mark rather than just clearing the class.
		if ( styleIsActive( editor, item ) ) {
			focusEditable( editor ).chain().focus().unsetMark( inline.mark ).run();
		} else {
			const attrs = Object.assign( { "class": item.className }, inline.markAttrs || {} );
			focusEditable( editor ).chain().focus().setMark( inline.mark, attrs ).run();
		}
		return;
	}

	const d = STYLE_TYPES[ item.tag ];
	if ( !d || !styleApplicable( editor, item ) ) { return; }

	// A BLOCK style names the element it applies, so it converts the block too
	// (`h2.intro` on a paragraph makes it an h2). An OBJECT style only ever
	// re-classes the node the caret is already inside.
	if ( d.type === BLOCK ) { applyFormat( editor, item.tag ); }
	const current = editor.getAttributes( d.node )[ "class" ];
	focusEditable( editor ).chain().focus().updateAttributes( d.node, { "class": current === item.className ? null : item.className } ).run();
}

function styleIsActive( editor, item ) {
	const d = STYLE_TYPES[ item.tag ];
	if ( !d ) { return false; }
	if ( d.mark ) { return editor.isActive( d.mark, Object.assign( { "class": item.className }, d.markAttrs || {} ) ); }
	return editor.isActive( d.node, d.attrs || {} ) && editor.getAttributes( d.node )[ "class" ] === item.className;
}

function renderStyles( editor, updaters, cfg ) {
	const wrap = document.createElement( "span" );
	wrap.className = "tiptap-dropdown";

	const trigger = document.createElement( "button" );
	trigger.type = "button";
	trigger.className = "tiptap-btn tiptap-dropdown-trigger";
	trigger.setAttribute( "data-cmd", "Styles" );
	// `tiptap-caret`/`tiptap-lbl`, never the bare `caret`/`lbl`: those are BOOTSTRAP
	// and Ace class names, and in the admin bootstrap's own `.caret` rule drew its
	// border triangle on top of ours - every dropdown showed two stacked arrows. The
	// caret itself is drawn in CSS (see .tiptap-caret) rather than printed as a
	// glyph, so there is nothing for a theme to double up.
	trigger.innerHTML = '<span class="tiptap-lbl"></span><span class="tiptap-caret" aria-hidden="true"></span>';
	trigger.querySelector( ".tiptap-lbl" ).textContent = t( "toolbar.styles" );

	// Same framed panel as Format: the entries are `<p class="lead">`-shaped real
	// elements and only the site's own stylesheet can preview them properly.
	const panel = createComboPanel( {
		  stylesheets: cfg && cfg.stylesheets
		, editor     : editor
		, anchor     : trigger
		, anchorWrap : wrap
		, title      : t( "toolbar.styles" )
	} );

	function closeMenu() { panel.close(); }

	// Mirrors stylescombo's onOpen: every entry is checked for applicability at the
	// current selection, the inapplicable ones are dropped, a type group with
	// nothing applicable in it loses its header too, and the applicable ones are
	// marked active. Built on open (not once at render) because the answer depends
	// on where the caret is, and because the sheets load asynchronously.
	function openMenu() {
		// Forces the panel frame into existence on first open (lazily, as CKEditor's
		// createPanel is) and hands back its document - items MUST be created with it,
		// not with the host `document`.
		const p    = panel.ensure();
		const pdoc = p.doc;
		const menu = p.body;
		menu.innerHTML = "";

		const items = styleItems( cfg, editor )
			.map( function( it, i ) { return { it: it, w: styleWeight( it, i ) }; } )
			.sort( function( a, b ) { return a.w - b.w; } )
			.map( function( e ) { return e.it; } )
			.filter( function( it ) { return styleApplicable( editor, it ); } );

		if ( !items.length ) {
			const none = pdoc.createElement( "div" );
			none.className = "tiptap-dropdown-item tiptap-dropdown-empty";
			none.textContent = t( "styles.none" );
			menu.appendChild( none );
		}

		let group = null;
		items.forEach( function( it ) {
			const type = STYLE_TYPES[ it.tag ].type;
			if ( type !== group ) {
				group = type;
				const head = pdoc.createElement( "div" );
				head.className = "tiptap-dropdown-group";
				head.textContent = t( type === OBJECT ? "styles.object" : type === BLOCK ? "styles.block" : "styles.inline" );
				menu.appendChild( head );
			}

			const item = pdoc.createElement( "div" );
			item.className = "tiptap-dropdown-item tiptap-fmt-preview";
			// Preview AS tag.class so the content CSS styles the entry.
			const inner = pdoc.createElement( it.tag );
			inner.className = it.className;
			inner.textContent = it.name;
			item.appendChild( inner );
			item.classList.toggle( "active", styleIsActive( editor, it ) );
			item.addEventListener( "mousedown", function( ev ) {
				ev.preventDefault(); // keep the editor selection
				applyStyle( editor, it );
				closeMenu();
			} );
			menu.appendChild( item );
		} );

		// Opened AFTER the items are in place: the panel is a frame whose height is
		// measured from its content, so an empty box would size and place wrong.
		panel.open();
	}

	trigger.addEventListener( "click", function( ev ) {
		ev.preventDefault();
		if ( trigger.disabled ) { return; }
		if ( panel.isOpen() ) { closeMenu(); } else { openMenu(); }
	} );

	// stylescombo's `refresh`: the whole combo goes TRISTATE_DISABLED when no style
	// is applicable at the caret. That is why CKEditor's Styles button reads as
	// greyed out in an ordinary paragraph on a site whose only harvested styles are
	// `table.*` - they are OBJECT styles and need a table in the element path.
	updaters.push( function() {
		const any = styleItems( cfg, editor ).some( function( it ) { return styleApplicable( editor, it ); } );
		trigger.disabled = !any;
		trigger.classList.toggle( "is-disabled", !any );
		if ( !any ) { closeMenu(); }
	} );

	wrap.appendChild( trigger );
	editor.on( "destroy", panel.destroy );
	return wrap;
}

function renderSource( editor ) {
	const btn = document.createElement( "button" );
	btn.type = "button";
	btn.className = "tiptap-btn";
	btn.title = t( "toolbar.source" );
	btn.setAttribute( "aria-label", t( "toolbar.source" ) );
	if ( ICONS.Source ) { btn.innerHTML = ICONS.Source; } else { btn.textContent = "</>"; }
	btn.setAttribute( "data-cmd", "Source" );
	btn.addEventListener( "click", function( ev ) {
		ev.preventDefault();
		// The view itself is src/sourceView.js: CKEditor's own layout, highlighted,
		// and display-only (it never rewrites the stored markup).
		btn.classList.toggle( "is-active", toggleSource( editor ) );
	} );
	return btn;
}

export function normaliseToolbar( parsed ) {
	if ( Array.isArray( parsed ) ) {
		return parsed.map( function( g ) {
			if ( g === "/" ) { return "/"; }
			if ( Array.isArray( g ) ) { return g; }
			if ( g && Array.isArray( g.items ) ) { return g.items; }
			return [];
		} );
	}
	return [ [ "Bold", "Italic", "Strike", "-", "BulletedList", "NumberedList", "Blockquote", "-", "RemoveFormat", "-", "Undo", "Redo" ] ];
}

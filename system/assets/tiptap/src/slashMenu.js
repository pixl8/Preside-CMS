/**
 * The "/" insert menu - type "/" in an empty block to filter and insert any of
 * the editor's block-level elements, INCLUDING Preside's own (image /
 * attachment / widget pickers, and individual widgets by name).
 *
 * Trigger detection is @tiptap/suggestion (MIT, framework-agnostic); the popup
 * is ours, because Tiptap only ships React/Vue renderers.
 *
 * WHY "/" ONLY AT THE START OF AN EMPTY-ISH BLOCK (see `allow` below): Preside
 * content is full of real slashes - dates, paths, "and/or" - and a menu that
 * opened mid-sentence would fight the author constantly. CKEditor had no such
 * trigger, so anything surprising here is a regression against the editor we
 * replace, not a missing feature.
 *
 * Every item is a command that already exists (the toolbar's COMMANDS, or the
 * picker commands the Preside extensions register), so this module adds a way to
 * REACH things, never a second implementation of them. Nothing here touches the
 * document beyond running that command, so getData() is unaffected by the menu's
 * existence.
 */
import { command, iconFor } from "./toolbar.js";
import { t, tIf } from "./i18n.js";
import { pluginSlashItems } from "./pluginHost.js";
import { pageRect, frameOf, containerOf } from "./editorFrame.js";
import { focusEditable } from "./editorFocus.js";

// Opt out per site/field, matching the wordcount / outline / tableTools opt-outs.
export function slashMenuEnabled( cfg ) {
	return !( cfg && cfg.defaultConfigs && cfg.defaultConfigs.slashMenu === false );
}

// ---- The item registry -------------------------------------------------------
// { key, icon, group, run(editor), keywords }
// `key` resolves the label via i18n ("slash.<key>"); `keywords` adds extra
// English search terms so "/pic" finds the image picker. Keywords are matched in
// ADDITION to the translated label, never instead of it - a localised admin must
// still be searchable in its own language.
function baseItems() {
	return [
		  { key: "h1",         icon: "Format",         group: "format", run: e => e.chain().focus().setNode( "heading", { level: 1 } ).run(), keywords: "heading title h1" }
		, { key: "h2",         icon: "Format",         group: "format", run: e => e.chain().focus().setNode( "heading", { level: 2 } ).run(), keywords: "heading subtitle h2" }
		, { key: "h3",         icon: "Format",         group: "format", run: e => e.chain().focus().setNode( "heading", { level: 3 } ).run(), keywords: "heading h3" }
		, { key: "paragraph",  icon: "Format",         group: "format", run: e => e.chain().focus().setParagraph().run(), keywords: "text body normal p" }
		, { key: "bulletlist", icon: "BulletedList",   group: "block",  run: e => e.chain().focus().toggleBulletList().run(), keywords: "unordered ul bullets" }
		, { key: "orderedlist",icon: "NumberedList",   group: "block",  run: e => e.chain().focus().toggleOrderedList().run(), keywords: "numbered ol" }
		, { key: "blockquote", icon: "Blockquote",     group: "block",  run: e => e.chain().focus().toggleBlockquote().run(), keywords: "quote citation" }
		, { key: "codeblock",  icon: "CodeSnippet",    group: "block",  run: e => e.chain().focus().toggleCodeBlock().run(), keywords: "code pre snippet" }
		, { key: "hr",         icon: "HorizontalRule", group: "block",  run: e => e.chain().focus().setHorizontalRule().run(), keywords: "divider rule separator line" }
		, { key: "table",      icon: "Table",          group: "block",  run: e => e.chain().focus().insertTable( { rows: 3, cols: 3, withHeaderRow: true } ).run(), keywords: "grid rows columns" }
		// Preside's own elements. These reuse the picker commands the embed
		// extensions register - the same ones the toolbar buttons call.
		, { key: "image",      icon: "ImagePicker",      group: "preside", cmd: "ImagePicker",      keywords: "picture photo asset media" }
		, { key: "attachment", icon: "AttachmentPicker", group: "preside", cmd: "AttachmentPicker", keywords: "file document download pdf" }
		, { key: "widget",     icon: "Widgets",          group: "preside", cmd: "Widgets",          keywords: "widget component embed" }
		, { key: "link",       icon: "PresideLink",      group: "preside", cmd: "PresideLink",      keywords: "url href page" }
		, { key: "anchor",     icon: "PresideAnchor",    group: "preside", cmd: "PresideAnchor",    keywords: "bookmark jump target" }
	];
}

/**
 * Individual widgets, from cfrequest.tiptapWidgets (emitted server-side by the
 * ckEditorJs.cfm override - translated titles/descriptions, already filtered to
 * the active site template).
 *
 * Filtered here by the FIELD's own widgetCategories, applying Preside's own rule
 * (WidgetsService._isWidgetInCategories): an empty list on either side means
 * "default". Doing it client-side is what lets one server-rendered list serve
 * every field on the page, since widgetCategories is a per-field setting.
 *
 * Selecting one opens the picker PRE-POINTED at that widget (core's
 * Widgets.dialog() renders a widget's configForm whenever rc.widget is set), so
 * "/news" lands on the news widget's own form. Deliberately not short-circuited
 * into building a {{widget:...}} token here even for widgets with no config
 * form: the token would then be ours rather than Preside's, and byte fidelity
 * with what the picker commits is the whole point of tokens.
 */
function widgetItems( cfg ) {
	const all = ( window.cfrequest && window.cfrequest.tiptapWidgets ) || [];
	if ( !all.length ) { return []; }

	const wanted = String( ( cfg && cfg.widgetCategories ) || "" )
		.split( "," ).map( s => s.trim() ).filter( Boolean );
	const want = wanted.length ? wanted : [ "default" ];

	return all.filter( function( w ) {
		const cats = ( w.categories && w.categories.length ) ? w.categories : [ "default" ];
		return cats.some( c => want.some( x => x.toLowerCase() === String( c ).toLowerCase() ) );
	} ).map( function( w ) {
		return {
			  key      : null                 // label comes straight from the server
			, label    : w.title || w.id
			, hint     : w.description || ""
			, icon     : "Widgets"
			, group    : "widget"
			, keywords : w.id + " " + ( w.description || "" )
			, run      : function( editor ) { editor.commands.openPresideWidgetPicker( { widget: w.id } ); }
		};
	} );
}

/**
 * Caret geometry -> host coordinates.
 *
 * The popup is body-portalled in the HOST document (it has to escape a capped
 * field's clipping), but the caret is measured by ProseMirror INSIDE the editing
 * frame, where 0,0 is the frame's own top-left. Without this the menu opened at
 * the top-left of the admin page instead of at the caret.
 *
 * `clientRect` arrives from @tiptap/suggestion as a FUNCTION (it is re-read on
 * scroll), so the wrapper has to stay a function.
 */
function toHostRect( editor, rect ) {
	return pageRect( frameOf( editor.view.dom ), rect );
}

function hostRectOf( editor, clientRect ) {
	if ( typeof clientRect !== "function" ) { return toHostRect( editor, clientRect ); }
	return function() {
		const r = clientRect();
		return r ? toHostRect( editor, r ) : r;
	};
}

function itemsFor( cfg, editor ) {
	const items = [];
	baseItems().forEach( function( it ) {
		// Drop anything whose command this build/field does not have (a toolbar
		// without pickers, a Preside extension not registered).
		if ( it.cmd && !command( it.cmd, cfg ) ) { return; }
		items.push( {
			  label   : t( "slash." + it.key )
			, hint    : t( "slash." + it.key + ".hint" )
			, icon    : it.icon
			, group   : it.group
			, keywords: it.keywords || ""
			, run     : it.run || ( e => command( it.cmd, cfg ).run( e, cfg ) )
		} );
	} );
	widgetItems( cfg ).forEach( it => items.push( it ) );

	// Plugin-contributed entries (src/plugins.js `slashItems`), in the same shape
	// and under the SAME rule as everything above: an item whose command is not
	// available in this build/field is dropped rather than shown broken.
	// `label`/`hint` may be given literally (as the widget entries do) or left to
	// the "slash.<key>" i18n keys; a hint that resolves nowhere becomes "" rather
	// than printing its own key under the label.
	pluginSlashItems( { cfg: cfg, editor: editor || null, api: window.PresideTiptap && window.PresideTiptap.api } )
		.forEach( function( it ) {
			if ( it.cmd && !command( it.cmd, cfg ) ) { return; }
			if ( !it.cmd && typeof it.run !== "function" ) { return; }
			items.push( {
				  label   : it.label || ( it.key ? t( "slash." + it.key ) : it.cmd )
				, hint    : it.hint  || ( it.key ? tIf( "slash." + it.key + ".hint" ) : "" )
				, icon    : it.icon
				, group   : it.group || "preside"
				, keywords: it.keywords || ""
				, run     : it.run || ( e => command( it.cmd, cfg ).run( e, cfg ) )
			} );
		} );
	return items;
}

function filterItems( items, query ) {
	const q = String( query || "" ).trim().toLowerCase();
	if ( !q ) { return items; }
	// Label match first, then keyword/hint match, so "/table" puts Table above
	// anything that merely mentions tables.
	const starts = [], contains = [], loose = [];
	items.forEach( function( it ) {
		const label = String( it.label || "" ).toLowerCase();
		if ( label.startsWith( q ) )      { starts.push( it ); }
		else if ( label.includes( q ) )   { contains.push( it ); }
		else if ( ( it.keywords + " " + ( it.hint || "" ) ).toLowerCase().includes( q ) ) { loose.push( it ); }
	} );
	return starts.concat( contains, loose );
}

/**
 * Build the Tiptap extension. `cfg` is the facade's field config (for
 * widgetCategories + the opt-out).
 */
export function createSlashMenu( T, cfg ) {
	return T.Extension.create( {
		  name: "presideSlashMenu"

		// The popup element lives on <body>, outside the editor container, so the
		// facade's container removal cannot collect it - it must be destroyed here
		// or every create/destroy cycle leaks one (Modern inline mode destroys and
		// recreates the editor on every save).
		, onDestroy() {
			if ( this.storage.popup ) { this.storage.popup.destroy(); }
		}

		, addStorage() { return { popup: null, openManual: null }; }

		, addProseMirrorPlugins() {
			const editor = this.editor;
			// Built here rather than in createSlashMenu(): a plugin's slashItems()
			// hook is handed the live editor, which does not exist until now.
			const items  = () => itemsFor( cfg, editor );
			const popup  = createPopup( editor );
			this.storage.popup = popup;

			// Programmatic open - the "+" gutter button's path (dragHandle.js). The
			// SAME popup and item list as the typed "/", but with no "/" written
			// into the document: the query lives here, typed characters are
			// swallowed by a capture-phase key handler and filter the list exactly
			// as they would after a real "/". Items run at the current caret.
			this.storage.openManual = function() {
				let query = "", active = 0, list = [];

				function currentRect() {
					try { return toHostRect( editor, editor.view.coordsAtPos( editor.state.selection.from ) ); }
					catch ( e ) { return null; }
				}
				function paint() {
					popup.render( list, active, pick );
					popup.move( currentRect );
				}
				function refilter() {
					list = filterItems( items(), query );
					if ( active >= list.length ) { active = 0; }
					paint();
				}
				function pick( i ) {
					const it = list[ i ];
					close();
					if ( it ) { it.run( focusEditable( editor ) ); }
				}
				// BOTH documents, and both are needed. The user types into the EDITABLE,
				// which for a boxed editor is inside the editing frame - a listener on the
				// host document never sees those keystrokes, so the manual menu could not
				// be filtered or dismissed from the keyboard at all. The popup itself is
				// body-portalled in the HOST document, so an outside-click that should
				// dismiss the menu is a host mousedown. Modern inline mode has one
				// document and `docs` collapses to it.
				const docs = [ document, editor.view.dom.ownerDocument ]
					.filter( function( d, i, all ) { return d && all.indexOf( d ) === i; } );
				function close() {
					docs.forEach( function( d ) {
						d.removeEventListener( "keydown", onKey, true );
						d.removeEventListener( "mousedown", onDown, true );
					} );
					popup.close();
				}
				function onDown( e ) { if ( !popup.contains( e.target ) ) { close(); } }
				function onKey( e ) {
					if ( e.key === "Escape" )    { e.preventDefault(); e.stopPropagation(); close(); return; }
					if ( e.key === "ArrowDown" || e.key === "ArrowUp" ) {
						e.preventDefault(); e.stopPropagation();
						if ( list.length ) { active = ( active + ( e.key === "ArrowDown" ? 1 : list.length - 1 ) ) % list.length; paint(); }
						return;
					}
					if ( e.key === "Enter" || e.key === "Tab" ) { e.preventDefault(); e.stopPropagation(); pick( active ); return; }
					if ( e.key === "Backspace" ) {
						if ( !query.length ) { close(); return; } // nothing to unfilter - let the key act on the doc
						e.preventDefault(); e.stopPropagation();
						query = query.slice( 0, -1 ); refilter(); return;
					}
					if ( e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey ) {
						e.preventDefault(); e.stopPropagation();
						query += e.key; refilter(); return;
					}
					// Any other key (arrows left/right, Home...) - hand the editor back.
					close();
				}

				docs.forEach( function( d ) {
					d.addEventListener( "keydown", onKey, true );
					d.addEventListener( "mousedown", onDown, true );
				} );
				popup.open();
				refilter();
			};

			return [ T.Suggestion( {
				  editor
				, char     : "/"
				, pluginKey: new T.PluginKey( "presideSlashMenu" )

				// Only at the very start of an empty-ish top-level block, and never
				// inside a code block (where "/" is just code) - see the header note.
				, allow: function( { state, range } ) {
					const $from = state.doc.resolve( range.from );
					if ( $from.parent.type.name === "codeBlock" ) { return false; }
					// The text before the "/" must be nothing at all.
					const before = $from.parent.textBetween( 0, Math.max( 0, range.from - $from.start() ) );
					return before.trim() === "";
				}

				, command: function( { editor, range, props } ) {
					// Drop the "/query" text, then run the item. Deleting first means
					// the item's own command sees a clean block - important for the
					// pickers, which insert a block-level node at the selection.
					focusEditable( editor ).chain().focus().deleteRange( range ).run();
					props.run( focusEditable( editor ) );
				}

				, items: function( { query } ) { return filterItems( items(), query ); }

				, render: function() {
					let list = [], active = 0, cmd = null, rect = null;

					// Render BEFORE positioning, always: the flip-above decision needs the
					// popup's real height, and measuring an empty box put a full-length
					// menu off the bottom of the screen.
					function paint() {
						popup.render( list, active, function( i ) {
							if ( cmd ) { cmd( list[ i ] ); }
						} );
						popup.move( rect );
					}

					return {
						  onStart: function( props ) {
							list = props.items; active = 0; cmd = props.command; rect = hostRectOf( editor, props.clientRect );
							popup.open();
							paint();
						}
						, onUpdate: function( props ) {
							list = props.items; cmd = props.command; rect = hostRectOf( editor, props.clientRect );
							if ( active >= list.length ) { active = 0; }
							paint();
						}
						, onKeyDown: function( props ) {
							const k = props.event.key;
							if ( k === "Escape" )    { popup.close(); return true; }
							if ( !list.length )      { return false; }
							if ( k === "ArrowDown" ) { active = ( active + 1 ) % list.length; paint(); return true; }
							if ( k === "ArrowUp" )   { active = ( active - 1 + list.length ) % list.length; paint(); return true; }
							if ( k === "Enter" || k === "Tab" ) {
								if ( cmd ) { cmd( list[ active ] ); }
								return true;
							}
							return false;
						}
						, onExit: function() { popup.close(); list = []; cmd = null; }
					};
				}
			} ) ];
		}
	} );
}

// ---- The popup ---------------------------------------------------------------
// Appended to <body>, positioned from the caret rect suggestion hands us. On
// <body> rather than inside the container so a capped-height or overflow-hidden
// field cannot clip it - the same reason the picker overlays live there.
function createPopup( editor ) {
	let el = null;

	function ensure() {
		if ( el ) { return el; }
		el = document.createElement( "div" );
		el.className = "tiptap-slash-menu";
		el.setAttribute( "role", "listbox" );
		el.setAttribute( "aria-label", t( "slash.title" ) );
		document.body.appendChild( el );
		return el;
	}

	// The menu follows the EDITOR's theme, not the OS: a dark-OS user with the
	// default (light) editor was getting a dark menu over light chrome — and
	// inline (Modern) the editable is the site page itself, which is light. The
	// container's tiptap-dark class is the single source of truth, checked at
	// open so a theme toggle mid-session is picked up.
	function syncTheme() {
		const container = editor && editor.view && containerOf( editor.view.dom );
		ensure().classList.toggle( "tiptap-dark", !!( container && container.classList.contains( "tiptap-dark" ) ) );
	}

	return {
		  // Only makes it visible - positioning happens in move(), after render(),
		  // because it needs the rendered height.
		  open: function() { syncTheme(); ensure().classList.add( "is-open" ); }

		, move: function( getRect ) {
			if ( !el ) { return; }
			const r = typeof getRect === "function" ? getRect() : getRect;
			if ( !r ) { return; }
			// Measured now, with content in place (see paint()).
			const h = el.offsetHeight;
			const w = el.offsetWidth;
			// Below the caret by preference; above when that would overflow the
			// viewport, and clamped if it will not comfortably fit either way.
			let top = r.bottom + 6;
			if ( top + h > window.innerHeight - 8 ) {
				const above = r.top - h - 6;
				top = above >= 8 ? above : Math.max( 8, window.innerHeight - h - 8 );
			}
			let left = r.left;
			if ( left + w > window.innerWidth - 8 ) { left = Math.max( 8, window.innerWidth - w - 8 ); }
			el.style.top  = Math.round( top ) + "px";
			el.style.left = Math.round( left ) + "px";
		}

		, render: function( items, active, pick ) {
			const box = ensure();
			box.innerHTML = "";

			if ( !items.length ) {
				const empty = document.createElement( "div" );
				empty.className = "tiptap-slash-empty";
				empty.textContent = t( "slash.empty" );
				box.appendChild( empty );
				return;
			}

			let lastGroup = null;
			items.forEach( function( it, i ) {
				if ( it.group !== lastGroup ) {
					lastGroup = it.group;
					const h = document.createElement( "div" );
					h.className = "tiptap-slash-group";
					// A plugin may name a group of its own; without a matching i18n key
					// t() would print the raw "slash.group.x", so fall back to the name.
					h.textContent = tIf( "slash.group." + it.group ) || it.group;
					box.appendChild( h );
				}

				const row = document.createElement( "div" );
				row.className = "tiptap-slash-item" + ( i === active ? " is-active" : "" );
				row.setAttribute( "role", "option" );
				row.setAttribute( "aria-selected", i === active ? "true" : "false" );

				const ico = document.createElement( "span" );
				ico.className = "tiptap-slash-icon";
				// One of our icon names, a plugin command's name, or a raw SVG string
				// a plugin item supplied directly.
				ico.innerHTML = iconFor( it.icon ) || ( /^\s*</.test( it.icon || "" ) ? it.icon : "" );
				row.appendChild( ico );

				const txt = document.createElement( "span" );
				txt.className = "tiptap-slash-text";
				const lbl = document.createElement( "span" );
				lbl.className = "tiptap-slash-label";
				lbl.textContent = it.label;
				txt.appendChild( lbl );
				if ( it.hint ) {
					const hint = document.createElement( "span" );
					hint.className = "tiptap-slash-hint";
					hint.textContent = it.hint;
					txt.appendChild( hint );
				}
				row.appendChild( txt );

				// mousedown-preventDefault keeps the editor selection: the suggestion
				// range is resolved against it, so losing focus would break the insert.
				row.addEventListener( "mousedown", e => e.preventDefault() );
				row.addEventListener( "click", function( e ) { e.preventDefault(); pick( i ); } );
				box.appendChild( row );
			} );

			// Keep the highlighted row in view for keyboard-only use.
			const activeEl = box.querySelector( ".tiptap-slash-item.is-active" );
			if ( activeEl && activeEl.scrollIntoView ) { activeEl.scrollIntoView( { block: "nearest" } ); }
		}

		, close: function() { if ( el ) { el.classList.remove( "is-open" ); el.innerHTML = ""; } }

		, contains: function( target ) { return !!( el && el.contains( target ) ); }

		, destroy: function() { if ( el ) { el.remove(); el = null; } }
	};
}

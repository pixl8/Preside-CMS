/**
 * Insert Special Character — CKEditor's `specialchar` plugin.
 *
 * A modal grid of characters with a live preview, exactly the shape CKEditor's
 * dialog had (plugins/specialchar/dialogs/specialchar.js):
 *
 *  - The list and its order are CKEditor's `config.specialChars`, and a site can
 *    override it the usual way (`defaultConfigs.specialChars`, string or array,
 *    entries either an entity/character or `[ char, label ]`) - see
 *    src/specialChars.js for the verbatim default and the character names.
 *  - 17 columns (`charColumns`), each cell titled with the character's name.
 *  - Hovering a cell fills the two preview panes: the character itself, large,
 *    and its HTML form as text. Both were in CKEditor's dialog and both are
 *    genuinely useful - the second is how you tell &ndash; from &mdash;.
 *  - Clicking inserts and closes.
 *
 * WHAT IS INSERTED IS THE CHARACTER, NOT THE ENTITY - as in CKEditor, which built
 * a span from the entity and then inserted `span.getText()` (i.e. `insertText`,
 * not `insertHtml`). The stored markup therefore holds the UTF-8 character, which
 * is also how every character the author simply TYPES already round-trips through
 * this editor; nothing here introduces a second convention. (CKEditor's own output
 * writer re-encoded non-ASCII to entities on save via `config.entities`; that is a
 * whole-document output concern, not this dialog's, and is deliberately not
 * reintroduced - it would rewrite every existing accented character in a field the
 * first time it was saved.)
 *
 * Insertion goes through `tr.insertText`, which carries the marks across the
 * replaced range: an ellipsis inserted mid-bold-run stays bold, matching
 * CKEditor's insertText behaviour (its own "sticky" styles).
 */
import { t } from "./i18n.js";
import { openDialog } from "./dialog.js";
import { focusEditable } from "./editorFocus.js";
import { CHARS, NAMES } from "./specialChars.js";

const COLUMNS = 17;   // CKEditor's dialog definition: charColumns: 17

/** The configured list, normalised to [ { html, ch, name } ]. */
function charList( cfg ) {
	const raw = ( cfg && cfg.defaultConfigs && cfg.defaultConfigs.specialChars ) || CHARS;
	const list = Array.isArray( raw ) ? raw : String( raw ).split( " " );

	const out = [];
	list.forEach( function( entry ) {
		if ( !entry ) { return; }

		// CKEditor allowed `[ character, label ]` pairs alongside plain entries.
		const html  = Array.isArray( entry ) ? entry[ 0 ] : String( entry );
		const label = Array.isArray( entry ) ? entry[ 1 ] : null;
		const ch    = decodeEntity( html );
		if ( !ch ) { return; }

		out.push( { html: html, ch: ch, name: label || charName( html ) } );
	} );
	return out;
}

// CKEditor's own key derivation for the name lookup: the entity without "&", ";"
// or "#" (so "&euro;" -> "euro", "&#372;" -> "372"), falling back to the
// character itself. i18n is consulted first so a site CAN localise an individual
// name, but the English names ship as data - see src/specialChars.js.
function charName( html ) {
	const key = html.replace( "&", "" ).replace( ";", "" ).replace( "#", "" );
	const i18nKey = "specialchar.char." + key;
	const translated = t( i18nKey );
	if ( translated !== i18nKey ) { return translated; }
	return NAMES[ key ] || html;
}

function decodeEntity( html ) {
	if ( html.indexOf( "&" ) === -1 ) { return html; }
	const el = document.createElement( "div" );
	el.innerHTML = html;
	return el.textContent || "";
}

/** Open the picker for `editor`. `cfg` is the field config (specialChars). */
export function openSpecialChar( editor, cfg ) {
	const chars = charList( cfg );

	let previewChar, previewHtml, cells = [];
	let focused = 0;

	function preview( item ) {
		previewChar.textContent = item ? item.ch : "";
		previewHtml.textContent = item ? item.html : "";
	}

	function insert( item, api ) {
		api.close();
		const ed  = focusEditable( editor );
		const sel = ed.state.selection;
		try { ed.view.dispatch( ed.state.tr.insertText( item.ch, sel.from, sel.to ).scrollIntoView() ); }
		catch ( e ) {}
	}

	return openDialog( {
		  title    : t( "specialchar.title" )
		, className: "tiptap-specialchar-dialog"
		, build: function( body, api ) {
			const wrap = document.createElement( "div" );
			wrap.className = "tiptap-specialchar-wrap";

			const grid = document.createElement( "div" );
			grid.className = "tiptap-specialchar-grid";
			grid.setAttribute( "role", "listbox" );
			grid.setAttribute( "aria-label", t( "specialchar.options" ) );
			grid.style.gridTemplateColumns = "repeat(" + COLUMNS + ", 1fr)";

			chars.forEach( function( item, i ) {
				const cell = document.createElement( "button" );
				cell.type = "button";
				cell.className = "tiptap-specialchar-cell";
				cell.setAttribute( "role", "option" );
				cell.setAttribute( "tabindex", i === 0 ? "0" : "-1" );
				cell.title = item.name;
				cell.setAttribute( "aria-label", item.name );
				cell.textContent = item.ch;
				cell.addEventListener( "mouseenter", function() { preview( item ); } );
				cell.addEventListener( "focus", function() { focused = i; preview( item ); } );
				// mousedown is prevented so the dialog keeps focus until the click
				// lands (the same reason every toolbar dropdown here does it).
				cell.addEventListener( "mousedown", function( e ) { e.preventDefault(); } );
				cell.addEventListener( "click", function( e ) { e.preventDefault(); insert( item, api ); } );
				cells.push( cell );
				grid.appendChild( cell );
			} );

			// Arrow-key navigation across the grid, as CKEditor's dialog had (its own
			// handler walked the table's rows/cells); Enter and Space insert.
			grid.addEventListener( "keydown", function( e ) {
				let next = -1;
				if ( e.key === "ArrowRight" ) { next = focused + 1; }
				else if ( e.key === "ArrowLeft" ) { next = focused - 1; }
				else if ( e.key === "ArrowDown" ) { next = focused + COLUMNS; }
				else if ( e.key === "ArrowUp" ) { next = focused - COLUMNS; }
				else if ( e.key === "Enter" || e.key === " " ) {
					e.preventDefault();
					insert( chars[ focused ], api );
					return;
				} else { return; }

				e.preventDefault();
				if ( next < 0 || next >= cells.length ) { return; }
				cells[ focused ].setAttribute( "tabindex", "-1" );
				cells[ next ].setAttribute( "tabindex", "0" );
				cells[ next ].focus();
			} );

			const side = document.createElement( "div" );
			side.className = "tiptap-specialchar-preview";
			previewChar = document.createElement( "div" );
			previewChar.className = "tiptap-specialchar-big";
			previewHtml = document.createElement( "div" );
			previewHtml.className = "tiptap-specialchar-html";
			side.appendChild( previewChar );
			side.appendChild( previewHtml );

			wrap.appendChild( grid );
			wrap.appendChild( side );
			body.appendChild( wrap );

			if ( cells.length ) {
				preview( chars[ 0 ] );
				setTimeout( function() { cells[ 0 ].focus(); }, 0 );
			}
		}
		, buttons: [
			{ label: t( "picker.close" ), cls: "tiptap-specialchar-close", onClick: function( api ) { api.close(); } }
		  ]
	} );
}

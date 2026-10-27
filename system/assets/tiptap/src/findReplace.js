/**
 * Find / Find and Replace — CKEditor's `find` plugin.
 *
 * CKEditor had TWO toolbar buttons (`Find`, `Replace`) opening ONE dialog with a
 * "Find" and a "Replace" tab; the Replace button just opened it on the second tab
 * (`new CKEDITOR.dialogCommand( "find", { tabId: "replace" } )`). That is exactly
 * what this does - two buttons, two icons, one dialog (src/dialog.js).
 *
 * WHAT IS FAITHFUL TO CKEDITOR (plugins/find/dialogs/find.js):
 *  - Fields and options: "Find what", "Replace with", Match case / Match whole
 *    word / Match cyclic, the last defaulting to ON. The options are SHARED by
 *    both tabs - CKEditor copied the values across on every tab change; here
 *    there is one set of inputs and the tabs only show or hide the replace row,
 *    so they cannot drift.
 *  - The search starts at the CURRENT SELECTION and runs forwards; "match cyclic"
 *    wraps back to the top of the document once. Not found -> the dialog reports
 *    CKEditor's own `notFoundMsg`.
 *  - A match never spans a BLOCK boundary (CKEditor's walker treated one as a
 *    match boundary and reset), but it does span inline marks - "**bo**ld" is
 *    found by "bold". Inline atoms (an anchor, an embed) break the run for the
 *    same reason a block does.
 *  - "Match whole word" uses CKEditor's own boundary test - its punctuation set
 *    plus the C0/Unicode space ranges - and the start/end of a block counts as a
 *    boundary.
 *  - REPLACE IS TWO CLICKS, as it was in CKEditor: the first click finds and
 *    highlights, the second replaces THAT match, the next finds again. Changing
 *    any option invalidates the current match, so the next click re-finds.
 *  - REPLACE ALL runs from the top of the document, is never cyclic, and reports
 *    `replaceSuccessMsg` ("%1 occurrence(s) replaced.") - as ONE undo step, which
 *    is what CKEditor's saveSnapshot pair around its loop produced.
 *  - The dialog prefills "Find what" with the editor's selected text.
 *  - While searching, the match is HIGHLIGHTED and the editor selection is left
 *    alone; on close the last match becomes the selection and the editable takes
 *    focus (CKEditor's onHide, verbatim behaviour). The highlight colours are
 *    CKEditor's `config.find_highlight` (#004 on white text) - see src/tiptap.css.
 *
 * WHAT IS DELIBERATELY DIFFERENT:
 *  - The highlight is a ProseMirror DECORATION, not a real `<span>` inserted into
 *    the document (which is what CKEditor did, then unpicked on close). So
 *    searching cannot dirty the form, cannot appear in getData(), and needs no
 *    clean-up path - the same reasoning as the outline navigator's landed-on
 *    highlight (src/outline.js).
 *  - Messages appear in the dialog's status line instead of `alert()`.
 *  - Enter in a field runs that tab's primary action. In CKEditor it did nothing
 *    (its Enter handler looks for an "ok" button, and this dialog has none).
 */
import { t } from "./i18n.js";
import { openDialog } from "./dialog.js";
import { focusEditable } from "./editorFocus.js";
import { surfaceOf, frameOf } from "./editorFrame.js";

// ---- the search engine -------------------------------------------------------

// CKEditor's own word-boundary test (plugins/find/dialogs/find.js): its
// punctuation/space set, plus the C0 control range and the Unicode space block.
// A missing character - i.e. the start or end of the run - counts as a boundary.
const BOUNDARY_CHARS = /[.,"'?!;: \u0085\u00a0\u1680\u280e\u2028\u2029\u202f\u205f\u3000]/;

function isBoundary( ch ) {
	if ( !ch ) { return true; }
	const c = ch.charCodeAt( 0 );
	if ( c >= 9 && c <= 13 ) { return true; }
	if ( c >= 8192 && c <= 8202 ) { return true; }
	return BOUNDARY_CHARS.test( ch );
}

/**
 * The document as searchable RUNS: one per uninterrupted stretch of text within a
 * single textblock, each with the document position of its first character.
 *
 * Runs are what make "no match across a block boundary" fall out for free, and
 * they keep the position arithmetic trivial - consecutive text nodes occupy
 * contiguous positions, so `start + index` is the position of a character.
 */
function textRuns( doc ) {
	const runs = [];

	doc.descendants( function( node, pos ) {
		if ( !node.isTextblock ) { return true; }

		let text = "", start = -1, offset = pos + 1;
		const flush = function() {
			if ( text.length ) { runs.push( { text: text, start: start } ); }
			text = ""; start = -1;
		};

		node.forEach( function( child ) {
			if ( child.isText ) {
				if ( start < 0 ) { start = offset; }
				text += child.text;
			} else {
				flush();   // an inline atom breaks the run, as a block boundary does
			}
			offset += child.nodeSize;
		} );
		flush();

		return false;   // inline content is already accounted for
	} );

	return runs;
}

/** Every match of `needle`, in document order. Non-overlapping, as CKEditor's was. */
function allMatches( doc, needle, matchCase, matchWord ) {
	const out = [];
	if ( !needle ) { return out; }

	const n = matchCase ? needle : needle.toLowerCase();

	textRuns( doc ).forEach( function( run ) {
		const hay = matchCase ? run.text : run.text.toLowerCase();
		let i = hay.indexOf( n );
		while ( i !== -1 ) {
			const wordOk = !matchWord
				|| ( isBoundary( run.text.charAt( i - 1 ) ) && isBoundary( run.text.charAt( i + n.length ) ) );
			if ( wordOk ) { out.push( { from: run.start + i, to: run.start + i + needle.length } ); }
			i = hay.indexOf( n, i + n.length );
		}
	} );

	return out;
}

// ---- the highlight -----------------------------------------------------------

/**
 * `highlight( range | null )` for an editor, registering the decoration plugin on
 * first use. A decoration rather than markup: view-only, so the document, the
 * dirty state and getData() are all untouched (src/outline.js has the same note).
 */
function highlighter( editor ) {
	if ( editor.__ttFindHighlight ) { return editor.__ttFindHighlight; }

	const PM = window.PresideTiptap || {};
	if ( !PM.Plugin || !PM.PluginKey || !PM.Decoration || !PM.DecorationSet ) {
		editor.__ttFindHighlight = function() {};
		return editor.__ttFindHighlight;
	}

	const key = new PM.PluginKey( "presideFindHighlight" );
	editor.registerPlugin( new PM.Plugin( {
		  key  : key
		, state: {
			  init : function() { return PM.DecorationSet.empty; }
			, apply: function( tr, set ) {
				const action = tr.getMeta( key );
				if ( action && action.clear ) { return PM.DecorationSet.empty; }
				if ( action && action.range ) {
					return PM.DecorationSet.create( tr.doc, [
						PM.Decoration.inline( action.range.from, action.range.to, { "class": "tiptap-find-match" } )
					] );
				}
				return set.map( tr.mapping, tr.doc );
			}
		}
		, props: {
			decorations: function( state ) { return key.getState( state ); }
		}
	} ) );

	editor.__ttFindHighlight = function( range ) {
		try {
			editor.view.dispatch( editor.state.tr.setMeta( key, range ? { range: range } : { clear: true } ) );
		} catch ( e ) {}
	};
	return editor.__ttFindHighlight;
}

// ---- revealing a match -------------------------------------------------------

/**
 * Scroll a match into view, whatever is doing the scrolling: the editing frame's
 * own document when the field is capped (or maximized), otherwise the admin page
 * - and then only when the match really is off screen. Same three-branch shape,
 * and the same reasoning, as outline.js's go(): a scrollIntoView() fallback on an
 * uncapped field makes the browser scroll the whole admin FORM to satisfy it.
 */
function reveal( editor, pos ) {
	const surface = surfaceOf( frameOf( editor.view.dom ) || editor.view.dom.parentNode );

	let c;
	try { c = editor.view.coordsAtPos( pos ); } catch ( e ) { return; }

	if ( surface.canScroll() ) {
		// Both boxes in the CONTENT's own coordinate space - inside a frame the
		// match and the scrollport share it, so nothing is translated here.
		const box      = surface.box();
		const portTop  = surface.isFrame ? 0 : ( box ? box.top : 0 );
		const portHigh = surface.isFrame ? surface.viewportHeight() : ( box ? box.height : 0 );
		if ( c.top < portTop + 8 || c.bottom > portTop + portHigh - 8 ) {
			surface.scrollTo( Math.max( 0, surface.scrollTop() + ( c.top - portTop ) - 40 ), true );
		}
		return;
	}

	// Nothing of our own scrolls, so the match is where the page put it.
	const host   = surface.toHost( c );
	const height = window.innerHeight || document.documentElement.clientHeight || 0;
	if ( host.top >= 0 && host.bottom <= height ) { return; }

	const delta = host.top < 0 ? host.top - 40 : host.bottom - height + 40;
	try { window.scrollBy( { top: delta, behavior: "smooth" } ); }
	catch ( e ) { window.scrollBy( 0, delta ); }
}

// ---- the dialog --------------------------------------------------------------

/**
 * Open the Find and Replace dialog for `editor`.
 * `tab` is "find" or "replace" - which button was pressed.
 */
export function openFindReplace( editor, tab ) {
	const highlight = highlighter( editor );

	// The match currently highlighted, and the option signature it was found
	// with. CKEditor invalidated its match whenever an option changed
	// (hasMatchOptionsChanged) so the next click re-finds instead of replacing
	// something the user is no longer looking for.
	let current   = null;
	let currentSig = "";
	let replaced  = false;

	// Where the next search starts. CKEditor's searchRange begins at the
	// collapsed current selection and is reset to the document start on a wrap.
	let cursor = editor.state.selection.from;

	const selectedText = editor.state.doc.textBetween( editor.state.selection.from, editor.state.selection.to, " ", " " );

	let findInput, replaceInput, caseBox, wordBox, cyclicBox;

	function opts() {
		return {
			  needle   : findInput.value
			, matchCase: caseBox.checked
			, matchWord: wordBox.checked
			, cyclic   : cyclicBox.checked
		};
	}
	function signature( o ) { return [ o.needle, o.matchCase, o.matchWord ].join( " " ); }

	function setCurrent( match, sig ) {
		current    = match;
		currentSig = sig;
		replaced   = false;
		highlight( match );
		if ( match ) { reveal( editor, match.from ); }
	}

	/** Find the next match at or after `cursor`, wrapping once when cyclic. */
	function find( api ) {
		const o = opts();
		if ( !o.needle ) { findInput.focus(); return null; }

		const all = allMatches( editor.state.doc, o.needle, o.matchCase, o.matchWord );
		let next = null;
		for ( let i = 0; i < all.length; i++ ) {
			if ( all[ i ].from >= cursor ) { next = all[ i ]; break; }
		}
		if ( !next && o.cyclic && all.length ) { next = all[ 0 ]; }

		if ( !next ) {
			setCurrent( null, "" );
			api.status( t( "find.notfound" ) );
			return null;
		}

		cursor = next.to;
		setCurrent( next, signature( o ) );
		api.status( "" );
		return next;
	}

	/**
	 * CKEditor's replace(): replace the CURRENT match if there is a live, unreplaced
	 * one found with these same options - otherwise find the next one and leave it
	 * highlighted for the following click.
	 */
	function replace( api ) {
		const o   = opts();
		const sig = signature( o );

		if ( !current || replaced || sig !== currentSig ) { find( api ); return; }

		const at = current;
		try {
			// insertText carries the marks across the replaced range, so replacing a
			// word inside a link or a bold run keeps its formatting.
			editor.view.dispatch( editor.state.tr.insertText( replaceInput.value, at.from, at.to ) );
		} catch ( e ) { return; }

		replaced = true;
		cursor   = at.from + replaceInput.value.length;
		const range = { from: at.from, to: cursor };
		current = range;
		highlight( range );
		reveal( editor, range.from );
		// Silent, as CKEditor was: only Replace All and "not found" ever reported.
		api.status( "" );
	}

	/** From the top of the document, every match, one undo step. */
	function replaceAll( api ) {
		const o = opts();
		if ( !o.needle ) { findInput.focus(); return; }

		const all = allMatches( editor.state.doc, o.needle, o.matchCase, o.matchWord );
		if ( !all.length ) {
			setCurrent( null, "" );
			api.status( t( "find.notfound" ) );
			return;
		}

		// Applied back to front so each match's positions are still valid when it is
		// reached - and all in ONE transaction, so it is one undo step (CKEditor
		// bracketed its loop with saveSnapshot for the same reason).
		const tr = editor.state.tr;
		for ( let i = all.length - 1; i >= 0; i-- ) {
			tr.insertText( replaceInput.value, all[ i ].from, all[ i ].to );
		}
		try { editor.view.dispatch( tr ); } catch ( e ) { return; }

		setCurrent( null, "" );
		cursor = 0;
		api.status( t( "find.replaced", { count: all.length } ) );
	}

	const dialog = openDialog( {
		  title    : t( "find.title" )
		, className: "tiptap-find-dialog"
		, activeTab: tab === "replace" ? "replace" : "find"
		, tabs     : [
			  { id: "find"   , label: t( "find.find" ) }
			, { id: "replace", label: t( "find.replace" ) }
		  ]
		, build: function( body, api ) {
			body.appendChild( row( "find.findwhat", function( input ) { findInput = input; } ) );

			const replaceRow = row( "find.replacewith", function( input ) { replaceInput = input; } );
			replaceRow.className += " tiptap-dialog-row-replace";
			body.appendChild( replaceRow );

			const fs = document.createElement( "fieldset" );
			fs.className = "tiptap-find-options";
			const legend = document.createElement( "legend" );
			legend.textContent = t( "find.findoptions" );
			fs.appendChild( legend );
			fs.appendChild( option( "find.matchcase"  , false, function( b ) { caseBox   = b; } ) );
			fs.appendChild( option( "find.matchword"  , false, function( b ) { wordBox   = b; } ) );
			fs.appendChild( option( "find.matchcyclic", true , function( b ) { cyclicBox = b; } ) );
			body.appendChild( fs );

			findInput.value = selectedText.indexOf( "\n" ) === -1 ? selectedText : "";

			// Enter runs the tab's primary action. CKEditor's Enter handler looked for
			// an "ok" button, which this dialog never had, so Enter did nothing there.
			[ findInput, replaceInput ].forEach( function( input ) {
				input.addEventListener( "keydown", function( e ) {
					if ( e.key !== "Enter" ) { return; }
					e.preventDefault();
					if ( api.tab() === "replace" ) { replace( api ); } else { find( api ); }
				} );
			} );
			// Editing the term restarts the search from the current position rather
			// than continuing from a match of the OLD term.
			findInput.addEventListener( "input", function() { cursor = editor.state.selection.from; } );

			setTimeout( function() { findInput.focus(); findInput.select(); }, 0 );
		}
		, buttons: [
			// Each tab gets exactly the buttons CKEditor's own dialog put on it: Find on
			// the Find tab, Replace + Replace All on the Replace tab (whose Replace
			// click IS the find on the first press - see replace() above).
			  { label: t( "find.find" )      , primary: true, cls: "tiptap-find-go"        , tabs: [ "find" ], onClick: find }
			, { label: t( "find.replace" )   , primary: true, cls: "tiptap-find-replace"   , tabs: [ "replace" ], onClick: replace }
			, { label: t( "find.replaceall" ),                cls: "tiptap-find-replaceall", tabs: [ "replace" ], onClick: replaceAll }
			, { label: t( "picker.close" )   ,                cls: "tiptap-find-close"     , onClick: function( api ) { api.close(); } }
		  ]
		, onClose: function() {
			// CKEditor's onHide: drop the highlight, put the SELECTION on the match the
			// user stopped at, and hand focus back to the editable.
			highlight( null );
			if ( current ) {
				focusEditable( editor );
				try { editor.chain().setTextSelection( current ).run(); } catch ( e ) {}
			} else {
				focusEditable( editor );
			}
		}
	} );

	return dialog;
}

function row( labelKey, take ) {
	const wrap = document.createElement( "label" );
	wrap.className = "tiptap-dialog-row";
	const lbl = document.createElement( "span" );
	lbl.className = "tiptap-dialog-label";
	lbl.textContent = t( labelKey );
	const input = document.createElement( "input" );
	input.type = "text";
	input.className = "tiptap-dialog-input";
	wrap.appendChild( lbl );
	wrap.appendChild( input );
	take( input );
	return wrap;
}

function option( labelKey, checked, take ) {
	const wrap = document.createElement( "label" );
	wrap.className = "tiptap-find-option";
	const box = document.createElement( "input" );
	box.type = "checkbox";
	box.checked = !!checked;
	wrap.appendChild( box );
	wrap.appendChild( document.createTextNode( " " + t( labelKey ) ) );
	take( box );
	return wrap;
}

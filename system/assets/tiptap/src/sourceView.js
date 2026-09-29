/**
 * Source view — a small code editor: CKEditor's own layout, syntax highlighted.
 *
 * CKEditor's source view is readable because its OUTPUT WRITER formats as it
 * serialises: a blank line between top-level blocks, a tab per level inside
 * lists/tables, `<pre>` left verbatim. That formatting is in its stored data.
 *
 * OURS IS DISPLAY-ONLY, AND THAT IS THE WHOLE CONSTRAINT. `getData()` is byte-
 * compared against CKEditor's corpus and every `{{...}}` token has to round-trip
 * exactly (see src/normalize.js, src/tokens.js), so the stored string stays the
 * single line it is today. What this module does is lay that line out for reading
 * and put it back untouched:
 *
 *  - `formatHtml()` only ever INSERTS newlines and tabs at block boundaries. Every
 *    original byte is emitted verbatim from the token's own `raw` text - nothing is
 *    re-serialised, no attribute is rewritten, no quote style is normalised. So the
 *    formatter cannot invent a difference, which is the property that lets the
 *    editor trust the text it gets back.
 *  - closing the view with the text UNCHANGED does not touch the document at all -
 *    not even a `setContent` with identical html. That is what makes open-then-close
 *    a no-op for both `getData()` and the form's dirty state (it used to re-parse
 *    on every close, which risked churn for nothing).
 *  - inline content is never broken across lines and `<pre>` is never touched:
 *    whitespace is SIGNIFICANT in both, so a prettier layout there would change
 *    what the page renders.
 *
 * The editing surface is a transparent `<textarea>` over a highlighted `<pre>`,
 * scroll-synced. Deliberately not a contenteditable: the textarea keeps native
 * caret behaviour, IME, spellcheck-off, and its own undo stack, and only the paint
 * behind it is ours. The two elements MUST share font, size, line-height, padding,
 * wrapping and tab-size exactly or the highlight drifts off the text - that is why
 * those properties are set on a shared selector in src/tiptap.css.
 *
 * No line-number gutter: the view soft-wraps (Preside's image/widget tokens are
 * single lines hundreds of characters long, and a horizontal scrollbar hides more
 * than a gutter reveals), and numbering wrapped lines correctly means measuring
 * every soft break. A gutter that mis-numbers is worse than no gutter.
 *
 * Re-opening the view reuses the text the user left there, as long as the document
 * has not changed in between - so hand-made layout survives a toggle instead of
 * being reformatted away.
 */
import { tokenize, detokenize } from "./tokens.js";
import { normalizeOutput } from "./normalize.js";
import { containerOf } from "./editorFrame.js";

/**
 * The markup the view shows and compares against: EXACTLY what getData() would
 * store, normaliser included.
 *
 * It used to be `tokenize( getHTML() )` - Tiptap's INTERNAL html - which is not what
 * this view claims to show. The visible difference was the schema's <p> inside every
 * <li>: normalize.js unwraps it, so a flat list is stored bare, but the source view
 * displayed all of them and made a wrapper that mostly is not persisted look like it
 * always is.
 *
 * Passing the real enterMode/autoParagraph options (rather than only the structural
 * ones) is safe for the data even though those branches restructure top-level
 * paragraphs: re-parsing the normalised form on an edited close can change the
 * DOCUMENT's shape, but each of those branches is a fixed point of getData() - a
 * br-mode field stores "a<br />b" whether the doc holds two paragraphs or one with a
 * <br> in it - so the stored bytes come out the same either way. Asserted in T26.
 */
function storedHtml( editor ) {
	return normalizeOutput( tokenize( editor.getHTML() ), editor.__ttNormalize || {} );
}

// Block-level element names: the ones allowed to start a new line. Anything else is
// inline and is emitted inside its parent's line, untouched.
const BLOCK = {};
( "address article aside blockquote caption col colgroup dd div dl dt fieldset "
+ "figcaption figure footer form h1 h2 h3 h4 h5 h6 header hr li main nav ol p "
+ "pre section table tbody td tfoot th thead tr ul" ).split( " " )
	.forEach( function( n ) { BLOCK[ n ] = true; } );

// Void elements never take a closing tag.
const VOID = {};
( "area base br col embed hr img input link meta param source track wbr" )
	.split( " " ).forEach( function( n ) { VOID[ n ] = true; } );

// Whitespace inside these is part of the content - they are emitted verbatim.
const VERBATIM = { pre: true, textarea: true };

// Tokens are matched BEFORE tags: a Preside token's JSON payload can contain a
// `<` or `>` (alt text, a caption), and letting the tag branch see it first would
// mis-scan the rest of the string.
const SCAN = /(\{\{[\s\S]*?\}\})|(<!--[\s\S]*?-->)|(<!\[CDATA\[[\s\S]*?\]\]>)|(<![^>]*>)|(<\/?)([a-zA-Z][\w:.-]*)((?:"[^"]*"|'[^']*'|[^>"'])*)(>)/g;

/* ---- 1. tokenise ---------------------------------------------------------- */

function scan( html ) {
	const out = [];
	let last = 0, m;
	SCAN.lastIndex = 0;
	while ( ( m = SCAN.exec( html ) ) !== null ) {
		if ( m.index > last ) { out.push( { type: "text", raw: html.slice( last, m.index ) } ); }
		last = m.index + m[ 0 ].length;
		if ( m[ 1 ] ) { out.push( { type: "token"  , raw: m[ 0 ] } ); continue; }
		if ( m[ 2 ] ) { out.push( { type: "comment", raw: m[ 0 ] } ); continue; }
		if ( m[ 3 ] || m[ 4 ] ) { out.push( { type: "decl", raw: m[ 0 ] } ); continue; }

		const name   = m[ 6 ].toLowerCase();
		const closing = m[ 5 ] === "</";
		const selfEnd = /\/\s*$/.test( m[ 7 ] );
		out.push( {
			  type: closing ? "close" : ( selfEnd || VOID[ name ] ? "self" : "open" )
			, name: name
			, raw : m[ 0 ]
		} );
	}
	if ( last < html.length ) { out.push( { type: "text", raw: html.slice( last ) } ); }
	return out;
}

/* ---- 2. tree (tolerant: unbalanced markup must still display) ------------- */

function parse( html ) {
	const root = { children: [] };
	const stack = [ root ];
	const toks = scan( html );

	for ( let i = 0; i < toks.length; i++ ) {
		const tk  = toks[ i ];
		const top = stack[ stack.length - 1 ];

		if ( tk.type === "open" ) {
			const el = { type: "el", name: tk.name, raw: tk.raw, close: "", children: [] };
			top.children.push( el );
			stack.push( el );
			// Verbatim elements swallow everything up to their own close tag, so their
			// inner whitespace is never reindented.
			if ( VERBATIM[ tk.name ] ) {
				let inner = "";
				let j = i + 1;
				for ( ; j < toks.length; j++ ) {
					if ( toks[ j ].type === "close" && toks[ j ].name === tk.name ) { break; }
					inner += toks[ j ].raw;
				}
				el.verbatim = inner;
				el.close = j < toks.length ? toks[ j ].raw : "";
				stack.pop();
				i = j;
			}
			continue;
		}
		if ( tk.type === "close" ) {
			// Find the nearest matching open; ignore a stray close tag otherwise.
			let at = -1;
			for ( let s = stack.length - 1; s > 0; s-- ) {
				if ( stack[ s ].name === tk.name ) { at = s; break; }
			}
			if ( at === -1 ) { top.children.push( { type: "raw", raw: tk.raw } ); continue; }
			stack[ at ].close = tk.raw;
			stack.length = at;
			continue;
		}
		top.children.push( { type: tk.type === "self" ? "el" : tk.type, name: tk.name, raw: tk.raw, children: [] } );
	}
	return root;
}

/* ---- 3. print ------------------------------------------------------------- */

function isBlockNode( n ) {
	return n.type === "el" && BLOCK[ n.name ];
}

/** True when this element has block children, i.e. its content wants its own lines. */
function breaksInside( el ) {
	return !el.verbatim && el.children.some( isBlockNode );
}

/** Everything inside `el`, byte-for-byte - used for inline content. */
function rawInner( node ) {
	if ( node.verbatim !== undefined ) { return node.verbatim; }
	let out = "";
	( node.children || [] ).forEach( function( c ) {
		out += c.raw || "";
		if ( c.type === "el" && !VOID[ c.name ] ) { out += rawInner( c ) + ( c.close || "" ); }
	} );
	return out;
}

function printChildren( node, depth, lines ) {
	const kids = node.children || [];
	kids.forEach( function( c ) {
		// Whitespace between blocks carries no meaning - it is the layout we are about
		// to redraw. Text with content is kept exactly as it is.
		if ( c.type === "text" && !c.raw.replace( /\s+/g, "" ) ) { return; }
		printNode( c, depth, lines );
	} );
}

function printNode( n, depth, lines ) {
	const pad = new Array( depth + 1 ).join( "\t" );

	if ( n.type === "el" && n.verbatim !== undefined ) {
		// <pre>: the open tag starts a line, the content is untouched (CKEditor also
		// begins it on the next line), the close tag rides on the content's last line.
		const inner = /^\n/.test( n.verbatim ) ? n.verbatim : "\n" + n.verbatim;
		lines.push( { depth: depth, text: pad + n.raw + inner + ( n.close || "" ), block: true } );
		return;
	}
	if ( n.type === "el" && breaksInside( n ) ) {
		lines.push( { depth: depth, text: pad + n.raw, block: true } );
		printChildren( n, depth + 1, lines );
		if ( n.close ) { lines.push( { depth: depth, text: pad + n.close, block: true } ); }
		return;
	}
	const body = n.type === "el"
		? n.raw + rawInner( n ) + ( n.close || "" )
		: n.raw;
	lines.push( { depth: depth, text: pad + body, block: isBlockNode( n ) || n.type === "token" || n.type === "comment" } );
}

/**
 * Lay `html` out for reading. Insertions only: newlines and tabs at block
 * boundaries. Every other byte is the caller's own.
 */
export function formatHtml( html ) {
	const lines = [];
	printChildren( parse( String( html == null ? "" : html ) ), 0, lines );

	let out = "";
	lines.forEach( function( ln, i ) {
		if ( i ) {
			// A blank line BETWEEN top-level blocks, as CKEditor's writer does; single
			// newlines everywhere else.
			out += ( ln.depth === 0 && lines[ i - 1 ].depth === 0 && ln.block && lines[ i - 1 ].block )
				? "\n\n" : "\n";
		}
		out += ln.text;
	} );
	return out;
}

/* ---- 4. highlight -------------------------------------------------------- */

function esc( s ) {
	return s.replace( /&/g, "&amp;" ).replace( /</g, "&lt;" ).replace( />/g, "&gt;" );
}

const ATTR = /([\w:.-]+)(\s*=\s*)("[^"]*"|'[^']*'|[^\s>]+)|(\S+)/g;

function paintTag( raw ) {
	// `<name attrs>` — the punctuation, name, attribute names and values are each
	// their own span so the CSS owns the palette.
	const m = /^(<\/?)([a-zA-Z][\w:.-]*)([\s\S]*?)(\/?>)$/.exec( raw );
	if ( !m ) { return "<span class=\"tt-src-punct\">" + esc( raw ) + "</span>"; }

	let out = "<span class=\"tt-src-punct\">" + esc( m[ 1 ] ) + "</span>"
		+ "<span class=\"tt-src-tag\">" + esc( m[ 2 ] ) + "</span>";

	let rest = m[ 3 ], last = 0, a;
	ATTR.lastIndex = 0;
	while ( ( a = ATTR.exec( rest ) ) !== null ) {
		if ( a.index > last ) { out += esc( rest.slice( last, a.index ) ); }
		last = a.index + a[ 0 ].length;
		if ( a[ 4 ] !== undefined ) { out += "<span class=\"tt-src-attr\">" + esc( a[ 4 ] ) + "</span>"; continue; }
		out += "<span class=\"tt-src-attr\">" + esc( a[ 1 ] ) + "</span>"
			+ "<span class=\"tt-src-punct\">" + esc( a[ 2 ] ) + "</span>"
			+ "<span class=\"tt-src-val\">" + esc( a[ 3 ] ) + "</span>";
	}
	out += esc( rest.slice( last ) );
	return out + "<span class=\"tt-src-punct\">" + esc( m[ 4 ] ) + "</span>";
}

/** `text` -> highlighted html. Escapes everything; adds only spans. */
export function highlight( text ) {
	let out = "", last = 0, m;
	SCAN.lastIndex = 0;
	while ( ( m = SCAN.exec( text ) ) !== null ) {
		if ( m.index > last ) { out += esc( text.slice( last, m.index ) ); }
		last = m.index + m[ 0 ].length;
		if ( m[ 1 ] ) { out += "<span class=\"tt-src-token\">" + esc( m[ 0 ] ) + "</span>"; continue; }
		if ( m[ 2 ] ) { out += "<span class=\"tt-src-comment\">" + esc( m[ 0 ] ) + "</span>"; continue; }
		if ( m[ 3 ] || m[ 4 ] ) { out += "<span class=\"tt-src-decl\">" + esc( m[ 0 ] ) + "</span>"; continue; }
		out += paintTag( m[ 0 ] );
	}
	out += esc( text.slice( last ) );
	// A trailing newline of its own keeps the painted box as tall as the textarea
	// while the caret sits on a fresh last line.
	return out + "\n";
}

/* ---- 5. the view --------------------------------------------------------- */

/**
 * Toggle the source view on `editor`. Returns true when it is now open.
 *
 * The elements are created in the MOUNT's own document - for a boxed editor that is
 * the editing frame, not the host page: that is where our stylesheet and the
 * editor's key isolation live, and a host-created node would be adopted with the
 * wrong realm's prototypes.
 */
export function toggleSource( editor ) {
	const mount = editor.view.dom.parentNode;   // .tiptap-editor-mount
	if ( mount.__srcView ) { closeSource( editor ); return false; }

	const doc  = mount.ownerDocument;
	const html = storedHtml( editor );

	// Reuse the text the user left here if the document has not moved on, so their
	// own line breaks survive a toggle instead of being reformatted away.
	const kept = editor.__ttSource;
	const text = ( kept && kept.html === html ) ? kept.text : formatHtml( html );

	const wrap = doc.createElement( "div" );
	wrap.className = "tiptap-source-wrap";

	// A DIV, NOT A <pre>, even though it renders pre-formatted text. Both the
	// editor's own code-block styling (`.tiptap-editor-mount pre`, at (0,1,1)) and
	// any content stylesheet the field loads - a site styling its own `<pre>` is
	// entirely normal - would otherwise land on the paint layer and change its font,
	// size or padding. The two layers only stay glyph-aligned while nothing can
	// restyle one of them, and a bare div is the element least likely to be reached.
	const pre = doc.createElement( "div" );
	pre.className = "tiptap-source-hl";
	pre.setAttribute( "aria-hidden", "true" );

	const ta = doc.createElement( "textarea" );
	ta.className = "tiptap-source";
	ta.setAttribute( "spellcheck", "false" );
	ta.setAttribute( "autocapitalize", "off" );
	ta.setAttribute( "autocomplete", "off" );
	ta.value = text;

	function paint() {
		pre.innerHTML = highlight( ta.value );
		pre.scrollTop  = ta.scrollTop;
		pre.scrollLeft = ta.scrollLeft;
	}
	function sync() { pre.scrollTop = ta.scrollTop; pre.scrollLeft = ta.scrollLeft; }

	ta.addEventListener( "input", paint );
	ta.addEventListener( "scroll", sync );
	// Tab indents, as it does in any code editor - it must not walk the focus out of
	// a view whose whole content is markup.
	ta.addEventListener( "keydown", function( e ) {
		if ( e.key !== "Tab" || e.ctrlKey || e.metaKey || e.altKey ) { return; }
		e.preventDefault();
		const s = ta.selectionStart, en = ta.selectionEnd;
		ta.value = ta.value.slice( 0, s ) + "\t" + ta.value.slice( en );
		ta.selectionStart = ta.selectionEnd = s + 1;
		paint();
	} );

	// THE VIEW IS THE HEIGHT THE EDITOR ALREADY HAS, as CKEditor's source textarea
	// was: it took the editor's height rather than the source's own length. Sizing it
	// to its content instead would make the editor jump on every toggle (source is
	// several times taller than the rendered document), and leaving it at a fixed
	// 220px left dead space under it in any taller field. The frame's own auto-fit
	// then measures a body exactly its viewport's height, so nothing moves.
	function fit() {
		const view = doc.documentElement;
		if ( !view ) { return; }
		const pad  = parseFloat( doc.defaultView.getComputedStyle( mount ).paddingBottom ) || 0;
		const room = view.clientHeight - wrap.offsetTop - pad;
		wrap.style.height = Math.max( 180, room ) + "px";
	}
	// Re-fit when the frame itself is resized - the resize grip and Maximize both
	// change the frame's box while the source can be open.
	const win = doc.defaultView;
	if ( win ) { win.addEventListener( "resize", fit ); }

	wrap.appendChild( pre );
	wrap.appendChild( ta );
	editor.view.dom.style.display = "none";
	// The mount's padding exists for the content: the left inset in particular is the
	// block drag gutter's room (.tiptap-gutter-1/-2). There is no rail over the
	// source - and no blocks for it to grab - so the code view gets the full width
	// back and its own 10/12px inset is the only padding. THE CLASS GOES ON THE MOUNT,
	// not the container: the gutter rule targets the mount, which lives inside the
	// frame where a container selector cannot reach it.
	mount.classList.add( "is-source" );
	mount.appendChild( wrap );
	mount.__srcView = { wrap: wrap, ta: ta, opened: text, html: html, fit: fit, win: win };
	fit();
	paint();

	// The outline rail navigates HEADINGS in a document that is not on screen, and
	// clicking one would move a caret nobody can see - so the container is marked
	// while the source is up and the css hides it (the rest of the content-glued
	// chrome cannot appear: it all hangs off the hidden editable).
	const container = containerOf( editor.view.dom );
	if ( container ) { container.classList.add( "is-source" ); }

	// Open at the TOP, on the first line - focusing a textarea puts the caret at the
	// end of its value, which scrolled a long document's source straight to the
	// bottom (and took the frame's own scroll with it).
	try { ta.focus( { preventScroll: true } ); } catch ( e ) { ta.focus(); }
	ta.setSelectionRange( 0, 0 );
	ta.scrollTop = 0;
	if ( ta.ownerDocument.documentElement ) { ta.ownerDocument.documentElement.scrollTop = 0; }
	pre.scrollTop = 0;
	return true;
}

/** Apply and close, if open. */
export function closeSource( editor ) {
	const mount = editor.view.dom.parentNode;
	const view  = mount.__srcView;
	if ( !view ) { return; }

	const value = view.ta.value;

	if ( view.win ) { view.win.removeEventListener( "resize", view.fit ); }
	view.wrap.remove();
	mount.classList.remove( "is-source" );
	mount.__srcView = null;
	editor.view.dom.style.display = "";
	const container = containerOf( editor.view.dom );
	if ( container ) { container.classList.remove( "is-source" ); }

	// UNCHANGED means untouched: no setContent, so no transaction, so getData() is
	// byte-identical and the form does not go dirty for having been looked at.
	if ( value !== view.opened ) { editor.commands.setContent( detokenize( value ) ); }

	// Remember the text the user is leaving behind, keyed on the document it goes
	// with, so re-opening gives them their OWN layout back rather than reformatting
	// it - which is the point of laying it out by hand in the first place. The key is
	// what makes it safe: any later edit in the editable changes the html and the
	// stale text is dropped. It can differ from what the doc holds (the parser
	// straightens up invalid nesting), and that is harmless: closing without a change
	// writes nothing, so the doc keeps its own version either way.
	try { editor.__ttSource = { html: storedHtml( editor ), text: value }; }
	catch ( e ) { editor.__ttSource = null; }
}

export function sourceOpen( editor ) {
	return !!( editor.view.dom.parentNode && editor.view.dom.parentNode.__srcView );
}

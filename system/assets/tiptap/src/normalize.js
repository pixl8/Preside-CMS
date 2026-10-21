/**
 * Output normaliser — bring Tiptap's persisted HTML closer to CKEditor's stored
 * form, so migrating an existing CKEditor-authored corpus produces clean diffs
 * rather than churn/bloat. Applied in getData() AFTER tokenize().
 *
 * Handles the *structural* divergences (not cosmetic whitespace, which the browser
 * renders identically):
 *   - unwrap a single attribute-less <p> inside <li>/<td>/<th>/<blockquote>
 *     (StarterKit wraps block content in <p>; CKEditor stores it bare), including
 *     the leading one on a list item that also holds a sublist
 *   - slim Tiptap table markup (drop the table's min-width style and default
 *     colspan/rowspan="1"; keep a <colgroup> ONLY when a column has an explicit
 *     width, since that is what makes a resized column render on the site)
 *   - drop a trailing empty <p></p> that setContent can append
 *
 * Must stay idempotent: normalize(normalize(x)) === normalize(x). A <p> carrying a
 * class/style is left wrapped so those attributes are never lost.
 */

export function normalizeOutput( html, opts ) {
	if ( !html ) { return ""; }
	opts = opts || {};

	const root = document.createElement( "div" );
	root.innerHTML = html;

	// Unwrap single, attribute-less <p> inside block containers.
	//
	// A LIST ITEM HOLDING A SUBLIST COUNTS AS "SINGLE" TOO, and that is not a
	// loosening of the rule - it is the same rule applied to the shape CKEditor
	// actually stored. Tiptap gives `<li><p>parent</p><ul>…</ul></li>`, so the item
	// has two element children and the length test alone left the wrapper in place;
	// CKEditor stored `<li>parent<ul>…</ul></li>`.
	//
	// BUT ONLY WHEN THAT LEADING <p> HAS CONTENT, and this is the one rule here that
	// is NOT about matching CKEditor - it is about surviving a reload, which beats
	// byte-fidelity when the two disagree. An unlabelled sublist parent gives
	// `<li><p></p><ol>…</ol></li>`, whose wrapper really is pure noise and which
	// CKEditor really did store bare. Store it bare and it does not come back: our
	// ListItem is `paragraph block*`, so a leading <ol> cannot satisfy it and the
	// parser SPLITS the item into two sibling lists, losing the nesting. Measured
	// both ways - `<li>parent<ul>` round-trips stably, `<li><ol>` does not. So the
	// empty one keeps a wrapper that reloads, and we accept the noise.
	//
	// (The same parser divergence means raw CKEditor `<li><ol>` markup is already
	// restructured on the way IN, before this function ever sees it. That is a
	// separate, pre-existing input-side issue and cannot be fixed from here.)
	//
	// A GENUINELY multi-paragraph item is still left alone: only a LEADING <p> whose
	// every remaining sibling is a list qualifies, so `<li><p>a</p><p>b</p></li>`
	// keeps both wrappers and no text is silently run together.
	root.querySelectorAll( "li, td, th, blockquote" ).forEach( function( el ) {
		const kids = elementChildren( el );
		if ( !kids.length ) { return; }

		const first = kids[ 0 ];
		if ( first.tagName !== "P" || first.attributes.length !== 0 ) { return; }

		const only = kids.length === 1;
		const leadingInList = el.tagName === "LI" && hasContent( first )
		                   && kids.slice( 1 ).every( isList );

		if ( only || leadingInList ) { unwrap( first ); }
	} );

	// Slim tables.
	//
	// The table's own `style` is always dropped: Tiptap sets a min-width sized for
	// the resize handles, which is an editing concern and would fight the site's
	// own table CSS.
	//
	// <colgroup> is the DOCUMENTED EXCEPTION to "slim it away". The cells carry
	// Tiptap's `colwidth` attribute, which is what the EDITOR reads back - but no
	// browser understands it, so the colgroup is the only thing that makes a
	// resized column actually render at that width on the site. Dropping it (as
	// this did before column resizing existed) would let an author drag a column,
	// see it stick in the editor, and silently lose it everywhere else.
	//
	// A table nobody has resized still serialises WITHOUT a colgroup - byte
	// identical to before - so an existing CKEditor-authored corpus does not churn
	// just by being opened and saved.
	root.querySelectorAll( "table" ).forEach( function( t ) {
		t.removeAttribute( "style" );

		const cg = t.querySelector( ":scope > colgroup" );
		if ( !cg ) { return; }

		let sized = false;
		cg.querySelectorAll( ":scope > col" ).forEach( function( col ) {
			// Keep an explicit width; drop the min-width that only exists so the
			// resize handles have something to grab. Rewriting the whole style
			// attribute (rather than editing it) keeps this idempotent.
			const w = col.style.width;
			if ( w ) { col.setAttribute( "style", "width:" + w ); sized = true; }
			else { col.removeAttribute( "style" ); }
		} );

		if ( !sized ) { cg.remove(); }
	} );
	root.querySelectorAll( "td, th" ).forEach( function( c ) {
		if ( c.getAttribute( "colspan" ) === "1" ) { c.removeAttribute( "colspan" ); }
		if ( c.getAttribute( "rowspan" ) === "1" ) { c.removeAttribute( "rowspan" ); }
	} );

	// Drop a trailing empty paragraph.
	const last = root.lastElementChild;
	if ( last && last.tagName === "P" && last.innerHTML.trim() === "" ) { last.remove(); }

	// enterMode=br (CKEditor ENTER_BR): paragraphs are not the line separator -
	// unwrap every top-level attribute-less <p>, joining consecutive ones with
	// <br />, matching what CKEditor stores for such fields.
	if ( opts.enterMode === "br" ) {
		let prevWasP = false;
		Array.prototype.slice.call( root.children ).forEach( function( el ) {
			const isBareP = el.tagName === "P" && el.attributes.length === 0;
			if ( isBareP && prevWasP ) { root.insertBefore( document.createElement( "br" ), el ); }
			if ( isBareP ) { unwrap( el ); }
			prevWasP = isBareP;
		} );
	} else if ( isFalse( opts.autoParagraph ) ) {
		// autoParagraph=false: CKEditor does not wrap lone inline content in <p>.
		// Mirror that when the whole document is a single attribute-less paragraph.
		const kids = elementChildren( root );
		if ( kids.length === 1 && kids[ 0 ].tagName === "P" && kids[ 0 ].attributes.length === 0 ) {
			unwrap( kids[ 0 ] );
		}
	}

	return root.innerHTML;
}

function isFalse( v ) {
	return v === false || v === "false" || v === 0;
}

function isList( el ) {
	return el.tagName === "UL" || el.tagName === "OL";
}

function hasContent( el ) {
	return el.textContent.trim() !== "" || !!el.firstElementChild;
}

function elementChildren( el ) {
	// Ignore whitespace-only text nodes (getHTML is compact, but be safe).
	const out = [];
	for ( let i = 0; i < el.childNodes.length; i++ ) {
		const n = el.childNodes[ i ];
		if ( n.nodeType === 1 ) { out.push( n ); }
		else if ( n.nodeType === 3 && n.nodeValue.trim() !== "" ) { out.push( n ); }
	}
	return out;
}

function unwrap( el ) {
	const parent = el.parentNode;
	while ( el.firstChild ) { parent.insertBefore( el.firstChild, el ); }
	parent.removeChild( el );
}

/**
 * Text direction (BidiLtr / BidiRtl) — CKEditor's `bidi` plugin.
 *
 * THE MARKUP IS THE POINT, so it is worth being exact about what CKEditor wrote
 * (the plugin is inlined in ckeditor.js; its `allowedContent` is
 * `h1..h6 table ul ol blockquote div tr p li td { attributes: "dir" }` and its
 * `requiredContent` is `p[dir]`):
 *
 *  1. IT SETS THE `dir` ATTRIBUTE on the block - never a CSS `direction`. In fact
 *     it REMOVES an existing inline `direction:` declaration on the way past,
 *     which this does too (stripDirection below): leaving both behind would mean
 *     the style silently beating the attribute the button just wrote.
 *  2. WITH `useComputedState` (its default), applying the direction the block
 *     WOULD HAVE ANYWAY removes the attribute instead of writing it. So in an LTR
 *     field, "left to right" on a plain paragraph produces NO markup at all, and
 *     on an already-`dir="rtl"` paragraph it removes the attribute rather than
 *     writing `dir="ltr"`. That is the whole reason this compares against the
 *     PARENT's computed direction rather than just setting the attribute.
 *  3. THE BUTTON STATE IS THE COMPUTED DIRECTION of the block the caret is in -
 *     which means, in an ordinary LTR field, the LTR button reads as ON before
 *     anything has been applied. That looks odd and it is nonetheless exactly what
 *     CKEditor did (its `refresh` sets bidiltr ON whenever the computed direction
 *     is "ltr"); the alternative would report "no direction" as "left to right is
 *     off", which is worse.
 *
 * WHICH NODES IT WRITES ON. CKEditor applied to each paragraph in the range, plus
 * any of {table, ul, ol, blockquote, div, tr, p, li} that the selection fully
 * encloses. Here: a container type entirely inside the selection takes the
 * attribute and its children are left alone (so selecting a whole table, or the
 * grip's NodeSelection on one, writes `<table dir>`); otherwise every textblock
 * the selection touches takes it (so the ordinary caret-in-a-paragraph case writes
 * `<p dir>`, as CKEditor did).
 *
 * `useComputedState: false` is NOT supported - it is an obscure config, and the
 * COMMANDS map in toolbar.js hands its runners the editor alone, with no field
 * config to read it from. The default behaviour is what is implemented.
 *
 * Round-tripping `dir` at all needs it in the schema: it is declared as a global
 * passthrough attribute on the block types in src/extensions/presideAttributes.js
 * (which also means existing `dir` in stored content stops being dropped).
 */
import { focusEditable } from "./editorFocus.js";

// The block containers CKEditor let carry `dir` and treated as a unit when the
// selection enclosed one, mapped to Tiptap/Preside node names.
const CONTAINERS = {
	  table      : true
	, tableRow   : true
	, tableCell  : true
	, tableHeader: true
	, bulletList : true
	, orderedList: true
	, listItem   : true
	, blockquote : true
	, presideDiv : true
};

function canTakeDir( node ) {
	const attrs = node.type.spec.attrs;
	return !!( attrs && attrs.dir );
}

// Drop an inline `direction:` declaration, as CKEditor's removeStyle did. The
// whole attribute is rewritten (rather than spliced) so this stays idempotent -
// the same discipline normalize.js applies to <col> widths.
function stripDirection( style ) {
	if ( !style ) { return style || null; }
	const out = String( style )
		.split( ";" )
		.filter( function( d ) { return d.trim() && !/^\s*direction\s*:/i.test( d ); } )
		.join( ";" )
		.trim();
	return out.length ? out : null;
}

/**
 * The direction a node would have with no `dir` of its own: its parent's computed
 * direction. This is CKEditor's `useComputedState` test, expressed once - it
 * checked the element itself, removed the attribute, then checked again, which
 * amounts to the same comparison.
 */
function inheritedDir( editor, pos ) {
	try {
		const dom    = editor.view.nodeDOM( pos );
		const parent = dom && dom.parentElement;
		if ( !parent ) { return "ltr"; }
		const win = parent.ownerDocument.defaultView || window;
		return win.getComputedStyle( parent ).direction || "ltr";
	} catch ( e ) { return "ltr"; }
}

/** Apply `dir` ("ltr" | "rtl") to the blocks the selection covers. */
export function setBidi( editor, dir ) {
	const ed    = focusEditable( editor );
	const state = ed.state;
	const sel   = state.selection;
	const tr    = state.tr;

	state.doc.nodesBetween( sel.from, sel.to, function( node, pos ) {
		const enclosed = sel.from <= pos && sel.to >= pos + node.nodeSize;

		if ( CONTAINERS[ node.type.name ] && enclosed ) {
			apply( node, pos );
			return false;   // the container is the unit - leave its children alone
		}
		if ( node.isTextblock ) {
			apply( node, pos );
			return false;
		}
		return true;
	} );

	function apply( node, pos ) {
		if ( !canTakeDir( node ) ) { return; }
		const attrs = Object.assign( {}, node.attrs );
		attrs.style = stripDirection( attrs.style );
		attrs.dir   = ( dir === inheritedDir( ed, pos ) ) ? null : dir;
		if ( attrs.dir === node.attrs.dir && attrs.style === node.attrs.style ) { return; }
		tr.setNodeMarkup( pos, undefined, attrs, node.marks );
	}

	if ( tr.docChanged ) {
		try { ed.view.dispatch( tr ); } catch ( e ) {}
	}
	return true;
}

/**
 * The COMPUTED direction at the caret - what lights the buttons. Read off the DOM
 * rather than the attribute, because that is what CKEditor's refresh did and it is
 * the only way an inherited direction (a `dir` on an ancestor, or an RTL admin
 * locale) shows up in the toolbar at all.
 */
export function currentDir( editor ) {
	try {
		let node = editor.view.domAtPos( editor.state.selection.$from.pos ).node;
		if ( node && node.nodeType === 3 ) { node = node.parentNode; }
		if ( !node || node.nodeType !== 1 ) { return "ltr"; }
		const win = node.ownerDocument.defaultView || window;
		return win.getComputedStyle( node ).direction || "ltr";
	} catch ( e ) { return "ltr"; }
}

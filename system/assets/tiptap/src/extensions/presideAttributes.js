/**
 * PresideAttributes — preserve `class` and `style` on content.
 *
 * StarterKit drops unknown attributes, so content authored in CKEditor with
 * classes/inline-styles (e.g. `<p class="lead">`, `<span class="hl">`) would lose
 * them on save — a round-trip data-loss bug — and class-based content CSS would not
 * apply in the editor. This adds:
 *
 *   createPresideAttributes()  — a global `class`/`style` attribute on block nodes
 *   createPresideInlineStyle() — an inline mark that keeps `<span class|style>`
 *
 * It is also the foundation a stylesheetParser-style "Styles" dropdown would build
 * on (apply a class from the parsed content stylesheet).
 */
import { Extension, Mark, mergeAttributes } from "@tiptap/core";

// Block/text node types that legitimately carry class/style in Preside content.
const BLOCK_TYPES = [
	"paragraph", "heading", "blockquote", "codeBlock",
	"bulletList", "orderedList", "listItem",
	"table", "tableRow", "tableHeader", "tableCell",
	"presideDiv"
];

// StarterKit marks that a class-bearing INLINE style resolves onto. `strong`/`b`
// -> bold, `em`/`i` -> italic (see STYLE_TYPES in src/toolbar.js). `small` is not
// here because StarterKit has no `small` mark - it is handled by
// presideInlineStyle's `tag` attribute below.
const INLINE_MARK_TYPES = [ "bold", "italic" ];

// The element names presideInlineStyle is allowed to render as. An allow-list, not
// whatever is in the attribute: `tag` is parsed off the DOM, so anything else would
// be a way for stored markup to choose an arbitrary element name on save.
const TAGS = [ "span", "small" ];

function passthroughAttr( name ) {
	return {
		  default   : null
		, parseHTML : el => el.getAttribute( name )
		, renderHTML: attrs => attrs[ name ] ? ( { [ name ]: attrs[ name ] } ) : {}
	};
}

export function createPresideAttributes() {
	return Extension.create( {
		name: "presideAttributes",
		addGlobalAttributes() {
			return [ {
				types: BLOCK_TYPES,
				attributes: {
					  "class": passthroughAttr( "class" )
					, style   : passthroughAttr( "style" )
					// `dir` backs the BidiLtr/BidiRtl toolbar buttons (src/bidi.js):
					// CKEditor's bidi plugin wrote exactly this attribute, on exactly
					// these element types. Declaring it also stops a `dir` in existing
					// CKEditor-authored content being dropped on save - which is this
					// module's whole purpose.
					, dir     : passthroughAttr( "dir" )
				}
			}, {
				// StarterKit's own inline MARKS also need to carry a class, so a
				// `strong.text-danger` / `em.subtle` style from the Styles dropdown can
				// be applied and round-trip as `<strong class="text-danger">`.
				//
				// Deliberately done by extending these marks rather than adding a new
				// mark that parses <strong>/<em>: two marks claiming the same tag would
				// BOTH apply, and serialise as `<strong><strong class="...">`.
				//
				// Consequence, and it is intentional: CKEditor could tell a `b.x` style
				// from a `strong.x` one, and here both resolve to `<strong class="x">`
				// (same for i/em). That is not new loss - StarterKit already normalises
				// <b> to <strong> and <i> to <em> today.
				types: INLINE_MARK_TYPES,
				attributes: {
					  "class": passthroughAttr( "class" )
					, style   : passthroughAttr( "style" )
				}
			} ];
		}
	} );
}

export function createPresideInlineStyle() {
	return Mark.create( {
		name: "presideInlineStyle",
		priority: 90,        // below the embed nodes + PresideLink
		inclusive: false,

		addAttributes() {
			return {
				  "class": passthroughAttr( "class" )
				, style   : passthroughAttr( "style" )
				// WHICH TAG this mark renders as. It exists so a `small.text-muted`
				// style from the Styles dropdown round-trips as `<small class=...>`
				// rather than being flattened to a span - Preside's own default
				// stylesheetParser_validSelectors allows `small.` and a Bootstrap-ish
				// site really does have such rules.
				//
				// One mark with a tag attribute rather than a mark per tag: they behave
				// identically in every other respect, and a second Mark would be another
				// name in the schema, another `unsetMark` target and another priority to
				// reason about.
				//
				// NOT rendered as an attribute (renderHTML below drops it) - it chooses
				// the element name instead.
				, tag: {
					  default   : "span"
					, parseHTML : el => el.tagName.toLowerCase()
					, renderHTML: () => ( {} )
				}
			};
		},

		parseHTML() {
			// `small` is claimed unconditionally, `span` only when it carries something
			// worth keeping: a bare <span> is noise, but a bare <small> is semantic
			// markup in its own right and dropping it would lose content meaning.
			return [
				{
					tag: "span",
					getAttrs: function( el ) {
						// Leave the embed placeholder spans to their own atom nodes.
						if ( el.hasAttribute( "data-preside-image" ) || el.hasAttribute( "data-preside-attachment" ) || el.hasAttribute( "data-preside-widget" ) ) {
							return false;
						}
						// Only claim spans that actually carry class/style worth keeping.
						if ( !el.getAttribute( "class" ) && !el.getAttribute( "style" ) ) { return false; }
						return { tag: "span" };
					}
				},
				{ tag: "small", getAttrs: function() { return { tag: "small" }; } }
			];
		},

		// `mark`, not HTMLAttributes, is where the tag is read from: the attribute's
		// own renderHTML returns {} so it never becomes a DOM attribute, and that also
		// keeps it out of HTMLAttributes - so reading it from there always gave
		// undefined and every <small> was serialised back as a <span>.
		renderHTML( { mark, HTMLAttributes } ) {
			const attrs = {};
			Object.keys( HTMLAttributes ).forEach( function( k ) {
				if ( k === "tag" ) { return; }   // chooses the element, is not an attribute
				if ( HTMLAttributes[ k ] !== null && HTMLAttributes[ k ] !== undefined ) { attrs[ k ] = HTMLAttributes[ k ]; }
			} );
			const tag = mark && mark.attrs && mark.attrs.tag;
			return [ TAGS.indexOf( tag ) !== -1 ? tag : "span", mergeAttributes( attrs ), 0 ];
		}
	} );
}

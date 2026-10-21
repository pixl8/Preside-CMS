/**
 * Content-token conversion.
 *
 * Preside stores rich content with placeholder tokens that the server-side
 * ContentRendererService expands to HTML:
 *
 *   {{image:<urlenc-json>:image}}
 *   {{attachment:<urlenc-json>:attachment}}
 *   {{widget:<id>:<urlenc-json>:widget}}
 *   links (in <a href>):  {{link:…}} | {{asset:…}} | {{custom:…}}   (handled by PresideLink)
 *
 * detokenize (load / setData): turn the image/attachment/widget tokens into the
 *   placeholder <span data-preside-*> elements the nodes' parseHTML recognises.
 *   Mirrors the CKEditor dataFilter text rule. Link/asset/custom tokens live in
 *   href attributes and are left untouched (PresideLink owns them).
 *
 * tokenize (save / getData): turn those placeholder spans (as emitted by the
 *   nodes' renderHTML) straight back into the raw token text. Mirrors downcast.
 */

const IMAGE_RE      = /{{image:[\s\S]*?:image}}/gi;
const ATTACHMENT_RE = /{{attachment:[\s\S]*?:attachment}}/gi;
const WIDGET_RE     = /{{widget:[a-zA-Z$_][a-zA-Z0-9$_]*:[\s\S]*?:widget}}/gi;

function attrEscape( s ) {
	return String( s ).replace( /&/g, "&amp;" ).replace( /"/g, "&quot;" ).replace( /</g, "&lt;" ).replace( />/g, "&gt;" );
}
function embedEl( tag, dataAttr, cssClass, raw ) {
	return '<' + tag + ' ' + dataAttr + '="true" class="' + cssClass + '" data-raw="' + attrEscape( raw ) + '"></' + tag + '>';
}

const P_WRAPPED_TOKEN_RE = /<p>\s*({{(?:image|attachment|widget):[\s\S]*?:(?:image|attachment|widget)}})\s*<\/p>/gi;

export function detokenize( stored ) {
	if ( !stored ) { return ""; }
	// All embeds are block-level <div>s (CKEditor treats image/attachment/widget
	// as BLOCK widgets, so stored tokens are never <p>-wrapped). Legacy content
	// saved by earlier extension versions p-wrapped tokens - unwrap those first,
	// otherwise the browser parser splits the <p> around the div and leaves empty
	// <p></p> shells in the document.
	return stored
		.replace( P_WRAPPED_TOKEN_RE, "$1" )
		.replace( IMAGE_RE,      m => embedEl( "div", "data-preside-image",      "img-placeholder",        m ) )
		.replace( ATTACHMENT_RE, m => embedEl( "div", "data-preside-attachment", "attachment-placeholder", m ) )
		.replace( WIDGET_RE,     m => embedEl( "div", "data-preside-widget",     "widget-placeholder",     m ) );
}

export function tokenize( html ) {
	if ( !html || html.indexOf( "data-raw" ) === -1 ) { return html || ""; }
	// Browser DOM pass: replace each placeholder span with its raw token text.
	// Only our embed nodes carry data-raw (links do not), so this is targeted.
	const tmp = document.createElement( "div" );
	tmp.innerHTML = html;
	const nodes = tmp.querySelectorAll( "[data-raw]" );
	for ( let i = 0; i < nodes.length; i++ ) {
		const el = nodes[ i ];
		el.replaceWith( document.createTextNode( el.getAttribute( "data-raw" ) ) );
	}
	return tmp.innerHTML;
}

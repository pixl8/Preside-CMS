/**
 * OUR OWN stylesheet, as text — for injecting into a document or shadow root that
 * the page's `<link>` does not reach.
 *
 * Two consumers, both of them isolation boundaries:
 *   - the editing iframe (src/editorFrame.js), which needs the editable's
 *     functional CSS and the `--tt-*` variables inside its own document;
 *   - the modal dialog shell (src/dialog.js), whose shadow root is - by design -
 *     unreachable from any stylesheet in the page, ours included.
 *
 * The sheet's own `cssText` is used rather than a `<link>` so it applies
 * SYNCHRONOUSLY: the frame measures its height immediately after mount, and a
 * dialog positions itself as soon as it is built. Where the rules are unreadable
 * (a cross-origin CDN), `href` is returned instead so the caller can fall back to
 * a real `<link>`.
 *
 * Resolved once per page and cached: it is the same file for every editor.
 */

let cached = null;

export function ownStyleText() {
	if ( cached ) { return cached; }

	const sheets = document.styleSheets;
	for ( let i = 0; i < sheets.length; i++ ) {
		const href = sheets[ i ].href || "";
		if ( !/tiptap(\.[A-Z0-9]+)?\.min\.css|tiptap\.css/i.test( href ) ) { continue; }
		try {
			const rules = sheets[ i ].cssRules;
			let out = "";
			for ( let r = 0; r < rules.length; r++ ) { out += rules[ r ].cssText; }
			if ( out ) { return ( cached = { css: out, href: href } ); }
		} catch ( e ) {
			return ( cached = { css: "", href: href } );   // unreadable - use the link
		}
	}
	return ( cached = { css: "", href: "" } );
}

/** Put our stylesheet into `root` (a document head, or a shadow root). */
export function injectOwnStyle( root, doc ) {
	const own = ownStyleText();
	doc = doc || document;
	if ( own.css ) {
		const style = doc.createElement( "style" );
		style.setAttribute( "data-tiptap-own", "1" );
		style.textContent = own.css;
		root.appendChild( style );
		return style;
	}
	if ( own.href ) {
		const link = doc.createElement( "link" );
		link.rel = "stylesheet";
		link.href = own.href;
		root.appendChild( link );
		return link;
	}
	return null;
}

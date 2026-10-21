/**
 * Content stylesheet handling (the CKEditor `contentsCss` / Preside `stylesheets`
 * equivalent).
 *
 * EVERY CONSUMER GETS THE STYLESHEET UNMODIFIED, as a plain <link> in a document of
 * its own - exactly what CKEditor did. No scoping, no selector rewriting, no unit
 * rebasing. There are two such documents:
 *
 *   - the editing iframe (src/editorFrame.js), for the editable itself;
 *   - the Format/Styles panel iframe (src/comboPanel.js), for the entry previews.
 *
 * That is the whole point of a frame: `html`/`:root`/`body` selectors match because
 * the frame HAS an html and a body, `rem` resolves against the frame's own root,
 * `vw`/media queries resolve against its own box, and no rule from the admin page
 * can reach in.
 *
 * There used to be a second, TRANSFORMED path here - the sheet re-serialised with
 * every selector scoped to `.tiptap-fmt-preview` and `rem` rebased to px - because
 * the previews were chrome in the host document. It is gone with them, and it
 * should not come back: it could not express what it needed to. `html`/`body`
 * selectors had to be REMAPPED onto the preview element and any qualifier on them
 * then matched nothing; the rem base was GUESSED from the sheet's own `:root`
 * rule; `@layer`/`@container`/`@scope` had no branch at all and were emitted
 * unscoped into the admin's own <head>, restyling the admin UI; and it all
 * depended on a same-origin `fetch()` succeeding, which a `<link>` does not.
 */

/**
 * The editable's copy: the sheet as the site wrote it, in the frame's own head.
 *
 * Deliberately a <link> and not a fetched-and-inlined <style>: it keeps the
 * bytes byte-identical, it shares the browser cache with the site itself, and it
 * works cross-origin. The frame's auto-height re-measures on load, since a late
 * stylesheet changes the content height.
 */
export function injectFrameStyles( doc, stylesheetsCsv, onLoad ) {
	if ( !doc || !stylesheetsCsv ) { return; }
	urlList( stylesheetsCsv ).forEach( function( url ) {
		if ( doc.querySelector( 'link[data-preside-content-css="' + cssAttr( url ) + '"]' ) ) { return; }
		const link = doc.createElement( "link" );
		link.rel = "stylesheet";
		link.href = url;
		link.setAttribute( "data-preside-content-css", url );
		if ( onLoad ) { link.addEventListener( "load", onLoad ); }
		doc.head.appendChild( link );
	} );
}

function cssAttr( s ) { return String( s ).replace( /"/g, "&quot;" ); }

function urlList( csv ) {
	return String( csv ).split( "," ).map( s => s.trim() ).filter( Boolean );
}

/**
 * Raw selectors from a document's own stylesheets — the input to the Styles
 * dropdown (`styleItems()` in src/toolbar.js applies CKEditor's filtering).
 *
 * `doc` is the EDITING FRAME's document for a boxed editor, so these are the
 * sheets `injectFrameStyles()` put there, read live off the CSSOM. That is what
 * CKEditor's stylesheetparser reads too - `h( editor.document.$, ... )` walks
 * `document.styleSheets` of the editing iframe - and it means the dropdown no
 * longer depends on being able to `fetch()` the bytes ourselves. In Modern inline
 * mode there is no frame and `doc` is the host page, whose sheets ARE the site's.
 *
 * Two deliberate departures from CKEditor's loop, both strictly wider:
 *  - it recurses into @media/@supports, where CKEditor reads only top-level
 *    rules (and pushes `undefined` for every non-style rule it meets);
 *  - it skips non-style rules properly rather than stringifying them.
 * A sheet we cannot read (cross-origin, no CORS) throws on `.cssRules` and is
 * skipped, exactly as CKEditor's per-sheet try/catch does.
 */
export function harvestSelectors( doc ) {
	const out = [];
	if ( !doc || !doc.styleSheets ) { return out; }

	for ( let i = 0; i < doc.styleSheets.length; i++ ) {
		const sheet = doc.styleSheets[ i ];
		// CKEditor skips its own temp sheets and chrome:// - ours is the same idea:
		// never harvest from the editor's own chrome stylesheet.
		if ( sheet.href && sheet.href.indexOf( "chrome://" ) === 0 ) { continue; }
		if ( isOwnStyle( sheet ) ) { continue; }
		try { collectSelectors( sheet.cssRules, out ); } catch ( e ) { /* unreadable sheet */ }
	}
	return out;
}

// Our own chrome stylesheet, in whichever of the two forms injectOwnStyle() used
// (src/ownStyle.js): a <style data-tiptap-own> when the rules were readable, else
// a <link> to the hashed dist file.
function isOwnStyle( sheet ) {
	const node = sheet.ownerNode;
	if ( node && node.getAttribute && node.getAttribute( "data-tiptap-own" ) ) { return true; }
	return /tiptap(\.[A-Z0-9]+)?\.min\.css|tiptap\.css/i.test( sheet.href || "" );
}

function collectSelectors( rules, out ) {
	if ( !rules ) { return; }
	for ( let i = 0; i < rules.length; i++ ) {
		const rule = rules[ i ];
		if ( typeof rule.selectorText === "string" ) {
			if ( out.indexOf( rule.selectorText ) === -1 ) { out.push( rule.selectorText ); }
		} else if ( rule.cssRules && rule.cssRules.length ) {
			collectSelectors( rule.cssRules, out );
		}
	}
}

/**
 * Paste filtering — honours the CKEditor content-filter rules Preside configures
 * via settings.ckeditor.defaults.defaultConfigs:
 *
 *   disallowedContent     — applied to EVERY paste (core default:
 *                           'font; *[align,contenteditable]; *{line-height,margin*}')
 *   pasteFromWordDisallow — applied additionally when the pasted HTML comes from
 *                           MS Word/Office (core default strips spans, classes,
 *                           inline styles)
 *
 * Implements the subset of CKEditor's disallowed-content syntax those defaults
 * (and typical site overrides) use:
 *
 *   rule      := elements [attrs] {styles} (classes)     rules separated by ';'
 *   elements  := space/comma list of tag names, '*' = any
 *   attrs     := [a,b,c]   comma list, '*' = all, trailing '*' = prefix match
 *   styles    := {a,b*}    ditto (e.g. margin*)
 *   classes   := (x,*)     ditto
 *
 * A rule with elements only (no [..]/{..}/(..)) disallows the element itself —
 * the tag is unwrapped, its children kept (CKEditor's behaviour for non-empty
 * disallowed elements). A rule with properties strips just those properties
 * from matching elements.
 */

export function parseDisallowRules( raw ) {
	var list = Array.isArray( raw ) ? raw : String( raw || "" ).split( ";" );
	var rules = [];

	list.forEach( function( item ) {
		item = String( item || "" ).trim();
		if ( !item ) { return; }

		var m = item.match( /^([^\[\]{}()]*)(?:\[([^\]]*)\])?\s*(?:\{([^}]*)\})?\s*(?:\(([^)]*)\))?$/ );
		if ( !m ) { return; }

		var elements = ( m[ 1 ] || "*" ).trim();
		var rule = {
			  elements  : elements.split( /[\s,]+/ ).filter( Boolean ).map( function( e ) { return e.toLowerCase(); } )
			, attributes: splitProps( m[ 2 ] )
			, styles    : splitProps( m[ 3 ] )
			, classes   : splitProps( m[ 4 ] )
		};
		if ( !rule.elements.length ) { rule.elements = [ "*" ]; }
		rule.removeElement = !rule.attributes && !rule.styles && !rule.classes;
		rules.push( rule );
	} );

	return rules;
}

function splitProps( s ) {
	if ( s === undefined || s === null ) { return null; }
	return String( s ).split( "," ).map( function( p ) { return p.trim().toLowerCase(); } ).filter( Boolean );
}

function nameMatches( name, patterns ) {
	name = name.toLowerCase();
	for ( var i = 0; i < patterns.length; i++ ) {
		var p = patterns[ i ];
		if ( p === "*" ) { return true; }
		if ( p.slice( -1 ) === "*" ) { if ( name.indexOf( p.slice( 0, -1 ) ) === 0 ) { return true; } }
		else if ( name === p ) { return true; }
	}
	return false;
}

export function applyDisallowRules( html, rules ) {
	if ( !rules || !rules.length || !html ) { return html; }

	var root = document.createElement( "div" );
	root.innerHTML = html;

	rules.forEach( function( rule ) {
		var wildcarded = rule.elements.some( function( p ) { return p.indexOf( "*" ) !== -1; } );
		var els = Array.prototype.slice.call( root.querySelectorAll( wildcarded ? "*" : rule.elements.join( "," ) ) );

		els.forEach( function( el ) {
			if ( rule.elements.indexOf( "*" ) === -1 && !nameMatches( el.tagName, rule.elements ) ) { return; }

			if ( rule.removeElement ) {
				unwrap( el );
				return;
			}
			if ( rule.attributes ) {
				Array.prototype.slice.call( el.attributes ).forEach( function( a ) {
					if ( a.name === "style" || a.name === "class" ) { return; } // handled by {..}/(..)
					if ( nameMatches( a.name, rule.attributes ) ) { el.removeAttribute( a.name ); }
				} );
			}
			if ( rule.styles && el.getAttribute( "style" ) ) {
				if ( rule.styles.indexOf( "*" ) !== -1 ) { el.removeAttribute( "style" ); }
				else {
					for ( var i = el.style.length - 1; i >= 0; i-- ) {
						var prop = el.style[ i ];
						if ( nameMatches( prop, rule.styles ) ) { el.style.removeProperty( prop ); }
					}
					if ( !el.getAttribute( "style" ) ) { el.removeAttribute( "style" ); }
				}
			}
			if ( rule.classes && el.getAttribute( "class" ) ) {
				if ( rule.classes.indexOf( "*" ) !== -1 ) { el.removeAttribute( "class" ); }
				else {
					var kept = String( el.getAttribute( "class" ) ).split( /\s+/ ).filter( function( c ) {
						return c && !nameMatches( c, rule.classes );
					} );
					if ( kept.length ) { el.setAttribute( "class", kept.join( " " ) ); }
					else { el.removeAttribute( "class" ); }
				}
			}
		} );
	} );

	return root.innerHTML;
}

function unwrap( el ) {
	var parent = el.parentNode;
	if ( !parent ) { return; }
	while ( el.firstChild ) { parent.insertBefore( el.firstChild, el ); }
	parent.removeChild( el );
}

var WORD_MARKERS = /class="?Mso|style=["'][^"']*mso-|urn:schemas-microsoft-com:office|<o:p>/i;

// Builds the transformPastedHTML hook for a field, from its merged defaultConfigs.
export function createPasteTransform( defaultConfigs ) {
	defaultConfigs = defaultConfigs || {};

	var always = parseDisallowRules( defaultConfigs.disallowedContent );
	var word   = parseDisallowRules( defaultConfigs.pasteFromWordDisallow );

	if ( !always.length && !word.length ) { return null; }

	return function( html ) {
		if ( word.length && WORD_MARKERS.test( html ) ) { html = applyDisallowRules( html, word ); }
		if ( always.length ) { html = applyDisallowRules( html, always ); }
		return html;
	};
}

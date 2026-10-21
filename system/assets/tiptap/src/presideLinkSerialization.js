/**
 * Preside link serialization — the byte-exact link-token contract.
 *
 * Ported verbatim from the CKEditor plugin
 * (system/assets/ckeditorExtensions/plugins/presidelink/plugin.js:
 *  getLinkAttributes / parseLinkAttributes). Framework-agnostic and pure so it can
 * be unit-tested and reused unchanged. Produces/consumes:
 *   sitetreelink  {{link:<page>:link}}#anchor
 *   asset         {{asset:<id>:asset}}
 *   custom        {{custom:<base64 json, v:2>:custom}}
 *   url / email / anchor / emailvariable  (raw href forms)
 *
 * emailProtection defaults to Preside's "encode". The custom-function protection
 * mode (a rare non-default) is not ported; callers using it should extend here.
 */

const javascriptProtocolRegex = /^javascript:/,
	emailRegex           = /^mailto:([^?]+)(?:\?(.+))?$/,
	emailSubjectRegex    = /subject=([^;?:@&=$,\/]*)/,
	emailBodyRegex       = /body=([^;?:@&=$,\/]*)/,
	emailAntiSpamRegex   = /emailantispam=(\d)/,
	emailVariableRegex   = /(\$\{[^\}]+\})/,
	anchorRegex          = /^#(.*)$/,
	urlRegex             = /^((?:[a-z]+):\/\/)?(.*)$/,
	presideLinkRegex     = /^{{link:(.*?):link}}(?:#([^'"]+))?$/,
	presideAssetRegex    = /^{{asset:(.*?):asset}}$/,
	customRegex          = /^{{custom:(.*?):custom}}$/,
	encodedEmailLinkRegex = /^javascript:void\(location\.href='mailto:'\+String\.fromCharCode\(([^)]+)\)(?:\+'(.*)')?\)$/,
	bodyNewlines         = /\%0D\%0A/g;

const advAttrNames = {
	id: "advId", dir: "advLangDir", accessKey: "advAccessKey", name: "advName",
	lang: "advLangCode", tabindex: "advTabIndex", title: "title", type: "advContentType",
	"class": "advCSSClasses", charset: "advCharset", style: "advStyles", rel: "advRel"
};

function escapeSingleQuote( str ) { return str.replace( /'/g, "\\$&" ); }
function unescapeSingleQuote( str ) { return str.replace( /\\'/g, "'" ); }
function unescapeNewlines( str ) { return str.replace( /\%250D\%250A/g, "%0D%0A" ); }
function protectEmailAddressAsEncodedString( address ) {
	var codes = [];
	for ( var i = 0; i < address.length; i++ ) { codes.push( address.charCodeAt( i ) ); }
	return "String.fromCharCode(" + codes.join( "," ) + ")";
}

/**
 * Preside object-pickers (the anchor/page/asset selects carry class="object-picker")
 * store their selection in a hidden input as a value that can arrive as a JSON array
 * STRING (e.g. `["Test"]`) or an actual array — a multi-value representation even for
 * a single pick. The link fields these back are all single-valued, so unwrap to the
 * first element; plain scalars pass through untouched. Without this the raw
 * `["Test"]` string is concatenated straight into the href/token
 * (`#["Test"]`, `{{link:["PAGE-1"]:link}}`).
 */
function pickerScalar( v ) {
	if ( v === undefined || v === null ) { return ""; }
	if ( Array.isArray( v ) ) { return v.length ? v[ 0 ] : ""; }
	if ( typeof v === "string" ) {
		var s = v.trim();
		if ( s.charAt( 0 ) === "[" ) {
			try {
				var parsed = JSON.parse( s );
				if ( Array.isArray( parsed ) ) { return parsed.length ? parsed[ 0 ] : ""; }
			} catch ( e ) { /* not JSON — treat as a literal string */ }
		}
	}
	return v;
}

/**
 * data (from the link form) -> { set, removed }.
 * `set` carries href + optional target/rel/title/referrerpolicy.
 */
export function getLinkAttributes( data, emailProtection ) {
	emailProtection = emailProtection === undefined ? "encode" : emailProtection;
	var set = {};

	switch ( data.type ) {
		case "sitetreelink":
			set[ "data-cke-saved-href" ] = "{{link:" + ( pickerScalar( data.page ) || "" ) + ":link}}" + ( data.pageanchor ? "#" + data.pageanchor : "" );
			break;
		case "asset":
			set[ "data-cke-saved-href" ] = "{{asset:" + ( pickerScalar( data.asset ) || "" ) + ":asset}}";
			break;
		case "url":
			var protocol = ( data.protocol != undefined ) ? data.protocol : "http://",
				url      = ( data.address && String( data.address ).trim() ) || "";
			set[ "data-cke-saved-href" ] = ( url.indexOf( "/" ) === 0 ) ? url : protocol + url;
			break;
		case "anchor":
			set[ "data-cke-saved-href" ] = "#" + ( pickerScalar( data.anchor ) || "" );
			break;
		case "emailvariable":
			set[ "data-cke-saved-href" ] = data.emailvariable || "";
			break;
		case "email":
			var address = data.emailaddress, linkHref;
			var subject         = encodeURIComponent( data.emailsubject || "" ),
				body            = encodeURIComponent( data.emailbody    || "" ),
				antiSpam        = "0",
				disableAntiSpam = encodeURIComponent( typeof data.emailantispam === "string" && data.emailantispam === "1" ),
				argList         = [];

			if ( subject ) { argList.push( "subject=" + subject ); }
			if ( body )    { argList.push( "body=" + body.replace( bodyNewlines, "%250D%250A" ) ); }
			argList.push( "emailantispam=" + ( disableAntiSpam == "true" ? "1" : "0" ) );
			argList = argList.length ? "?" + argList.join( "&" ) : "";

			if ( emailProtection == "encode" && disableAntiSpam == "false" ) {
				linkHref = [ "javascript:void(location.href='mailto:'+", protectEmailAddressAsEncodedString( address ) ];
				if ( argList ) { linkHref.push( "+'", escapeSingleQuote( argList ), "'" ); }
				linkHref.push( ")" );
			} else {
				linkHref = [ "mailto:", address, argList ];
			}
			set[ "data-cke-saved-href" ] = linkHref.join( "" );
			break;

		default:
			var safeData = {};
			for ( var d in data ) { safeData[ d ] = encodeURIComponent( data[ d ] ); }
			safeData[ "v" ] = 2; // backwards-compat flag for older content
			set[ "data-cke-saved-href" ] = "{{custom:" + btoa( JSON.stringify( safeData ) ) + ":custom}}";
	}

	if ( data.link_target && data.link_target !== "_self" ) { set.target = data.link_target; }
	if ( data.nofollow && data.nofollow !== "" ) { set.rel = "nofollow"; }
	if ( data.title && data.title.length ) { set.title = data.title; }
	if ( data.referrer_policy && data.referrer_policy.length ) { set.referrerpolicy = data.referrer_policy; }

	if ( set[ "data-cke-saved-href" ] ) { set.href = set[ "data-cke-saved-href" ]; }

	var removed = Object.assign( { target: 1, onclick: 1, "data-cke-pa-onclick": 1, "data-cke-saved-name": 1 }, advAttrNames );
	for ( var s in set ) { delete removed[ s ]; }

	return { set: set, removed: Object.keys( removed ) };
}

/**
 * An anchor's attributes -> link-form data (for prefilling on edit).
 * `attrs` is a plain object: { href, target, rel, referrerpolicy, title, name, ... }.
 */
export function parseLinkAttributes( attrs ) {
	attrs = attrs || {};
	var href = attrs[ "data-cke-saved-href" ] || attrs.href || "";
	var retval = {}, m;

	if ( href.match( javascriptProtocolRegex ) ) {
		href = href.replace( encodedEmailLinkRegex, function( match, protectedAddress, rest ) {
			return "mailto:" + String.fromCharCode.apply( String, protectedAddress.split( "," ) ) +
				unescapeNewlines( rest || "" ) + unescapeSingleQuote( rest || "" );
		} );
	}

	if ( !retval.type ) {
		if ( ( m = href.match( anchorRegex ) ) ) {
			retval.type = "anchor"; retval.anchor = m[ 1 ];
		} else if ( ( m = href.match( emailRegex ) ) ) {
			var subjectMatch  = href.match( emailSubjectRegex ),
				bodyMatch     = href.match( emailBodyRegex ),
				antiSpamMatch = href.match( emailAntiSpamRegex );
			retval.type = "email";
			retval.emailaddress = m[ 1 ];
			if ( subjectMatch )  { retval.emailsubject  = decodeURIComponent( subjectMatch[ 1 ] ); }
			if ( bodyMatch )     { retval.emailbody     = decodeURIComponent( bodyMatch[ 1 ] ); }
			if ( antiSpamMatch ) { retval.emailantispam = decodeURIComponent( antiSpamMatch[ 1 ] ); }
		} else if ( href && ( m = href.match( presideLinkRegex ) ) ) {
			retval.type = "sitetreelink"; retval.page = m[ 1 ]; retval.pageanchor = m[ 2 ];
		} else if ( href && ( m = href.match( presideAssetRegex ) ) ) {
			retval.type = "asset"; retval.asset = m[ 1 ];
		} else if ( href && ( m = href.match( customRegex ) ) ) {
			try {
				retval = JSON.parse( atob( m[ 1 ] ) );
				if ( retval.hasOwnProperty( "v" ) ) {
					for ( var r in retval ) { retval[ r ] = decodeURIComponent( retval[ r ] ); }
				}
			} catch ( e ) { retval = {}; }
		} else if ( href && ( m = href.match( emailVariableRegex ) ) ) {
			retval.type = "emailvariable"; retval.emailvariable = m[ 1 ];
		} else if ( href && ( m = href.match( urlRegex ) ) ) {
			retval.type = "url"; retval.protocol = m[ 1 ]; retval.address = m[ 2 ];
		}
	}

	if ( attrs.target ) { retval.link_target = attrs.target; }
	if ( attrs.referrerpolicy ) { retval.referrer_policy = attrs.referrerpolicy; }
	if ( attrs.rel == "nofollow" ) { retval.nofollow = 1; }
	if ( attrs.title ) { retval.title = attrs.title; }

	return retval;
}

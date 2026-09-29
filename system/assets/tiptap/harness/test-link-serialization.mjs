/**
 * Unit test for the ported link serialization (the byte-exact token contract).
 * Run: node harness/test-link-serialization.mjs
 */
import { getLinkAttributes, parseLinkAttributes } from "../src/presideLinkSerialization.js";

let pass = 0, fail = 0;
function eq( label, actual, expected ) {
	if ( actual === expected ) { pass++; console.log( "  ✓ " + label ); }
	else { fail++; console.log( "  ✗ " + label + "\n      expected: " + JSON.stringify( expected ) + "\n      actual:   " + JSON.stringify( actual ) ); }
}

console.log( "getLinkAttributes -> href token:" );
eq( "sitetreelink",         getLinkAttributes( { type: "sitetreelink", page: "PAGE-123" } ).set.href, "{{link:PAGE-123:link}}" );
eq( "sitetreelink+anchor",  getLinkAttributes( { type: "sitetreelink", page: "PAGE-123", pageanchor: "sec" } ).set.href, "{{link:PAGE-123:link}}#sec" );
eq( "asset",                getLinkAttributes( { type: "asset", asset: "ASSET-9" } ).set.href, "{{asset:ASSET-9:asset}}" );
eq( "url (bare)",           getLinkAttributes( { type: "url", protocol: "https://", address: "example.com" } ).set.href, "https://example.com" );
eq( "url (root-relative)",  getLinkAttributes( { type: "url", protocol: "https://", address: "/path" } ).set.href, "/path" );
eq( "anchor",               getLinkAttributes( { type: "anchor", anchor: "top" } ).set.href, "#top" );
eq( "emailvariable",        getLinkAttributes( { type: "emailvariable", emailvariable: "${email}" } ).set.href, "${email}" );

// Object-picker values may arrive as a JSON-array string (or array) for a single
// pick — they must unwrap to the scalar, not embed `["..."]` in the href/token.
eq( "anchor (json-array string)",  getLinkAttributes( { type: "anchor", anchor: '["Test"]' } ).set.href, "#Test" );
eq( "anchor (real array)",         getLinkAttributes( { type: "anchor", anchor: [ "Test" ] } ).set.href, "#Test" );
eq( "sitetree page (json-array)",  getLinkAttributes( { type: "sitetreelink", page: '["PAGE-9"]' } ).set.href, "{{link:PAGE-9:link}}" );
eq( "asset (json-array)",          getLinkAttributes( { type: "asset", asset: '["ASSET-3"]' } ).set.href, "{{asset:ASSET-3:asset}}" );

console.log( "getLinkAttributes -> extra attributes:" );
const withTarget = getLinkAttributes( { type: "url", protocol: "https://", address: "x.com", link_target: "_blank", nofollow: "1", title: "T", referrer_policy: "no-referrer" } ).set;
eq( "target",         withTarget.target, "_blank" );
eq( "rel nofollow",   withTarget.rel, "nofollow" );
eq( "title",          withTarget.title, "T" );
eq( "referrerpolicy", withTarget.referrerpolicy, "no-referrer" );

console.log( "custom (unknown type) -> {{custom:...}} round-trips:" );
const customHref = getLinkAttributes( { type: "somethingCustom", foo: "bar baz", num: "7" } ).set.href;
eq( "is custom token", /^{{custom:.*:custom}}$/.test( customHref ), true );
const parsedCustom = parseLinkAttributes( { href: customHref } );
eq( "custom.foo round-trip", parsedCustom.foo, "bar baz" );
eq( "custom.type round-trip", parsedCustom.type, "somethingCustom" );

console.log( "parseLinkAttributes (prefill on edit):" );
eq( "sitetree page",  parseLinkAttributes( { href: "{{link:PAGE-5:link}}" } ).page, "PAGE-5" );
eq( "sitetree anchor",parseLinkAttributes( { href: "{{link:PAGE-5:link}}#a" } ).pageanchor, "a" );
eq( "asset id",       parseLinkAttributes( { href: "{{asset:AID:asset}}" } ).asset, "AID" );
eq( "url type",       parseLinkAttributes( { href: "https://foo.com" } ).type, "url" );
eq( "anchor type",    parseLinkAttributes( { href: "#top" } ).type, "anchor" );
eq( "target prefill", parseLinkAttributes( { href: "https://x", target: "_blank" } ).link_target, "_blank" );

console.log( "\nround-trip (getLinkAttributes -> parseLinkAttributes):" );
[ { type: "sitetreelink", page: "P1" }, { type: "asset", asset: "A1" }, { type: "anchor", anchor: "z" } ].forEach( function( d ) {
	const href = getLinkAttributes( d ).set.href;
	const back = parseLinkAttributes( { href: href } );
	eq( d.type + " type survives", back.type, d.type );
} );

console.log( "\n" + pass + " passed, " + fail + " failed" );
process.exit( fail ? 1 : 0 );

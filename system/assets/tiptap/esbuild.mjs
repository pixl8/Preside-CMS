/**
 * esbuild build for the Preside Tiptap external.
 *
 * Produces three self-contained, CONTENT-HASHED outputs under dist/
 * (committed, web-served by Preside from
 * /preside/system/assets/tiptap/dist/):
 *
 *   tiptap.bundle.<hash>.min.js  - Tiptap v3 + Preside extensions, exposes
 *                                  window.PresideTiptap. Sticker id "tiptap".
 *                                  Loads before presidecore when the tiptapEditor lab is on.
 *   facade.<hash>.min.js         - defines window.PresideTiptapRichEditor.
 *                                  References window.PresideTiptap; @tiptap/* kept
 *                                  external so Tiptap is never bundled twice.
 *   tiptap.<hash>.min.css        - editor chrome + content styles (src/tiptap.css).
 *
 * The <hash> is esbuild's content hash, so filenames change when (and only
 * when) content changes - browser cache busting with no ?v= query games.
 * system/assets/StickerBundle.cfc declares each asset with a Sticker wildcard path
 * (e.g. "/tiptap/dist/facade.*.min.js") which Sticker resolves to the single matching
 * file; harness/server.mjs globs /dist/ itself. Stale hashed outputs are
 * pruned after every (re)build - Sticker throws if a pattern matches more
 * than one file.
 *
 * Usage:  npm install && npm run build   (or: npm run watch)
 */
import * as esbuild from "esbuild";
import { mkdirSync, readdirSync, rmSync } from "node:fs";
import path from "node:path";

const watch  = process.argv.includes( "--watch" );
const OUTDIR = "dist";

mkdirSync( OUTDIR, { recursive: true } );

// Matches our hashed outputs: <base>.<HASH>.min.<js|css>[.map]
const HASHED_RE = /^(.+)\.([A-Z0-9]{8})\.min\.(js|css)(\.map)?$/;

// After each successful (re)build, delete previously-hashed outputs for the
// same entry base names so dist only ever contains the current files.
const prune = {
	name: "prune-stale-outputs",
	setup( build ) {
		build.onEnd( ( result ) => {
			if ( !result.metafile ) { return; }
			const current = Object.keys( result.metafile.outputs ).map( ( p ) => path.basename( p ) );
			const bases   = new Set( current.map( ( f ) => { const m = f.match( HASHED_RE ); return m && m[ 1 ]; } ).filter( Boolean ) );
			readdirSync( OUTDIR ).forEach( ( f ) => {
				const m = f.match( HASHED_RE );
				if ( m && bases.has( m[ 1 ] ) && !current.includes( f ) && !current.includes( f.replace( /\.map$/, "" ) ) ) {
					rmSync( path.join( OUTDIR, f ) );
				}
			} );
		} );
	}
};

const common = {
	  bundle        : true
	, minify        : true
	, sourcemap     : true
	, target        : [ "es2019" ]
	, legalComments : "none"
	, logLevel      : "info"
	, outdir        : OUTDIR
	, entryNames    : "[name].[hash].min"
	, metafile      : true
	, plugins       : [ prune ]
};

const vendor = {
	...common
	, format      : "iife"
	, entryPoints : { "tiptap.bundle": "src/index.js" }
};

const facade = {
	...common
	, format      : "iife"
	, entryPoints : { "facade": "src/facade.js" }
	, external    : [ "@tiptap/*" ]
};

const styles = {
	...common
	, entryPoints : { "tiptap": "src/tiptap.css" }
};

if ( watch ) {
	const ctxs = await Promise.all( [ esbuild.context( vendor ), esbuild.context( facade ), esbuild.context( styles ) ] );
	await Promise.all( ctxs.map( ( c ) => c.watch() ) );
	console.log( "[preside-tiptap] watching for changes..." );
} else {
	// Full build: clear ALL generated files first (incl. legacy unhashed names)
	// so dist is exactly the current build output.
	readdirSync( OUTDIR ).forEach( ( f ) => {
		if ( /\.(js|css|map)$/.test( f ) ) { rmSync( path.join( OUTDIR, f ) ); }
	} );
	await Promise.all( [ esbuild.build( vendor ), esbuild.build( facade ), esbuild.build( styles ) ] );
	console.log( "[preside-tiptap] build complete -> dist/" );
}

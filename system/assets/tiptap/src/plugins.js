/**
 * The plugin registry - `window.PresideTiptap.plugins`.
 *
 * WHY IT LIVES IN THE VENDOR BUNDLE (src/index.js) and not in the facade:
 * a dependent extension's bundle declares `.dependsOn("tiptap-facade")`, so it
 * parses after both of ours - but the vendor bundle loads first (Sticker id
 * "tiptap", before presidecore), so a registry living
 * here can never be reached before it exists. `register()` is therefore always
 * safe to call at a plugin's own parse time, which is the only moment early
 * enough to affect the editors formFields.js mounts on DOM-ready.
 *
 * This module is the WRITE side (the object itself). The READ side - the
 * helpers our own facade modules use to consume what has been registered - is
 * src/pluginHost.js, which reaches the registry through the global rather than
 * by import, precisely because the two live in different bundles.
 *
 * A spec: every field optional except `name`. See "Extending this extension" in
 * CLAUDE.md for the full contract.
 *
 *   {
 *       name             : "ai"
 *     , enabled          : cfg => cfg.defaultConfigs.ai !== false
 *     , tiptapExtensions : ctx => [ ... ]        // BEFORE the editor exists
 *     , commands         : { AI: { run, active, icon, label } }
 *     , slashItems       : ctx => [ ... ]
 *     , bubble           : { AI: editor => true }
 *     , chrome           : ctx => teardownFn     // AFTER mount, editor live
 *     , i18nDefaults     : { "ai.button": "Ask AI" }
 *   }
 */

// The one version number a plugin can check. There are no compatibility shims -
// this exists so a plugin can refuse to run against an API it does not know,
// which is a far better failure than half-working chrome.
export const API_VERSION = 1;

function warn( msg ) {
	if ( window.console && window.console.warn ) { window.console.warn( "[tiptap] " + msg ); }
}

export function createPluginRegistry() {
	const specs  = [];
	const byName = {};
	const buses  = {};
	// Flipped by the facade the first time an editor is constructed. A
	// registration after that point still applies to editors created LATER (AJAX
	// forms, frontend edit-mode toggles), so it is warned about rather than
	// refused: a predictable half-failure beats a silent one.
	let live = false;

	return {
		  apiVersion: API_VERSION

		, register( spec ) {
			if ( !spec || !spec.name ) { warn( "plugins.register() needs a spec with a `name`" ); return null; }
			if ( byName[ spec.name ] ) {
				warn( 'plugin "' + spec.name + '" is already registered - the second registration is ignored' );
				return byName[ spec.name ];
			}
			if ( live ) {
				warn( 'plugin "' + spec.name + '" registered after an editor already existed - it applies to editors '
					+ "created from now on, not to the ones already on the page" );
			}
			byName[ spec.name ] = spec;
			specs.push( spec );
			return spec;
		  }

		, all() { return specs.slice(); }
		, get( name ) { return byName[ name ] || null; }

		// ---- Lifecycle bus --------------------------------------------------
		// The three post-construction events (toolbarReady / instanceReady /
		// beforeDestroy) are also fired on the facade instance's own CKEditor-shaped
		// bus. `beforeExtensions` can only be fired here: it happens before the
		// instance exists, so there is nothing else to fire it on.
		, on( evt, fn ) { if ( typeof fn === "function" ) { ( buses[ evt ] = buses[ evt ] || [] ).push( fn ); } return this; }
		, off( evt, fn ) {
			const hs = buses[ evt ] || [];
			const i  = hs.indexOf( fn );
			if ( i !== -1 ) { hs.splice( i, 1 ); }
			return this;
		  }
		, emit( evt, payload ) {
			( buses[ evt ] || [] ).slice().forEach( function( fn ) {
				// A listener must never take the editor down with it - the same rule
				// the slash menu's widget list follows.
				try { fn( payload ); } catch ( e ) {
					if ( window.console ) { window.console.error( "[tiptap] plugin listener for " + evt + " failed", e ); }
				}
			} );
		  }

		, noteEditorCreated() { live = true; }
	};
}

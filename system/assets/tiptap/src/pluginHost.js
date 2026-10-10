/**
 * The READ side of the plugin registry (src/plugins.js).
 *
 * Everything here reaches `window.PresideTiptap.plugins` through the GLOBAL and
 * never by import. That is deliberate: the registry object is created in the
 * vendor bundle, and importing it from the facade bundle would build a second,
 * empty copy of it - so registrations would land in one registry and be read
 * from another. This module is imported by both bundles and reads the one that
 * is actually on the page.
 *
 * Every hook is called inside a try/catch and every failure is logged rather
 * than thrown: a broken add-on must degrade to "its feature is missing", never
 * to "the editor did not mount".
 */

function log( msg, e ) {
	if ( window.console && window.console.error ) { window.console.error( "[tiptap] " + msg, e ); }
}

export function registry() {
	try { return ( window.PresideTiptap && window.PresideTiptap.plugins ) || null; } catch ( e ) { return null; }
}

export function allPlugins() {
	const r = registry();
	return r ? r.all() : [];
}

/**
 * The plugins that apply to THIS field.
 *
 * `enabled( cfg )` is the conventional `defaultConfigs.<name> !== false`
 * opt-out - the same shape every built-in feature uses (wordcount, outline,
 * tableTools, slashMenu, imageTools, dragHandle). A plugin with no `enabled` is
 * always on; one whose `enabled` throws is treated as off.
 */
export function activePlugins( cfg ) {
	const c = cfg || { defaultConfigs: {} };
	if ( !c.defaultConfigs ) { c.defaultConfigs = {}; }
	return allPlugins().filter( function( p ) {
		if ( typeof p.enabled !== "function" ) { return true; }
		try { return p.enabled( c ) !== false; } catch ( e ) { log( 'plugin "' + p.name + '" enabled() failed', e ); return false; }
	} );
}

/** A toolbar command contributed by a plugin, or null. Built-ins always win. */
export function pluginCommand( name, cfg ) {
	const plugins = activePlugins( cfg );
	for ( let i = 0; i < plugins.length; i++ ) {
		const cmds = plugins[ i ].commands;
		if ( cmds && cmds[ name ] && typeof cmds[ name ].run === "function" ) { return cmds[ name ]; }
	}
	return null;
}

/**
 * A plugin-supplied icon (a raw SVG string) for a command name.
 *
 * Deliberately NOT gated on `enabled()`: this only ever runs for a name that
 * already resolved to a command, and an icon lookup that silently returned
 * nothing would be far harder to diagnose than one drawn for a control that is
 * not there.
 */
export function pluginIcon( name ) {
	const plugins = allPlugins();
	for ( let i = 0; i < plugins.length; i++ ) {
		const cmds = plugins[ i ].commands;
		if ( cmds && cmds[ name ] && cmds[ name ].icon ) { return cmds[ name ].icon; }
	}
	return null;
}

/** "/" menu entries, in the slashMenu.js internal shape. */
export function pluginSlashItems( ctx ) {
	const out = [];
	activePlugins( ctx && ctx.cfg ).forEach( function( p ) {
		if ( typeof p.slashItems !== "function" ) { return; }
		try {
			( p.slashItems( ctx ) || [] ).forEach( function( it ) { if ( it ) { out.push( it ); } } );
		} catch ( e ) { log( 'plugin "' + p.name + '" slashItems() failed', e ); }
	} );
	return out;
}

/** name -> does it apply here? - merged into the selection bubble's own map. */
export function pluginBubbleTests( cfg ) {
	const out = {};
	activePlugins( cfg ).forEach( function( p ) {
		if ( !p.bubble ) { return; }
		Object.keys( p.bubble ).forEach( function( k ) {
			if ( typeof p.bubble[ k ] === "function" ) { out[ k ] = p.bubble[ k ]; }
		} );
	} );
	return out;
}

/**
 * Client-side English fallbacks, merged UNDER src/i18n.js's own DEFAULTS.
 *
 * Cached against the registration count: `t()` runs on every render, and
 * rebuilding this object per string would be a real cost for a table that only
 * changes when a plugin registers (parse time, a handful of times per page).
 */
let i18nCache = null, i18nCacheAt = -1;
export function pluginI18nDefaults() {
	const plugins = allPlugins();
	if ( i18nCache && i18nCacheAt === plugins.length ) { return i18nCache; }
	const out = {};
	plugins.forEach( function( p ) {
		if ( !p.i18nDefaults ) { return; }
		Object.keys( p.i18nDefaults ).forEach( function( k ) { out[ k ] = p.i18nDefaults[ k ]; } );
	} );
	i18nCache   = out;
	i18nCacheAt = plugins.length;
	return out;
}

/** Fire a lifecycle event on the registry's global bus. */
export function emitLifecycle( evt, payload ) {
	const r = registry();
	if ( r ) { r.emit( evt, payload ); }
}

/** Tell the registry an editor now exists, so a late register() can warn. */
export function noteEditorCreated() {
	const r = registry();
	if ( r && r.noteEditorCreated ) { r.noteEditorCreated(); }
}

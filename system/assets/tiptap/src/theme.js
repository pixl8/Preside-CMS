/**
 * Editor light / dark theme.
 *
 * Chrome-only: it themes the editor container (toolbar, dropdowns, footer,
 * editable background) and never touches the stored content — dark mode is a
 * viewing preference, not a document property, so getData() is unaffected.
 *
 * The choice is a per-user preference (localStorage), not a per-field config:
 * toggling in one editor re-themes every editor on the page, and the preference
 * survives page loads. Sites/fields opt out of the control with
 * `defaultConfigs.darkMode = false`.
 *
 * The toggle button itself lives here (rather than in toolbar.js) because it is
 * rendered into the FOOTER status bar by default - the toolbar only builds one
 * when a toolbar config names it explicitly ("Theme" / "DarkMode").
 */
import { ICONS } from "./icons.js";
import { t } from "./i18n.js";

const STORAGE_KEY = "presideTiptapTheme";
const DARK_CLASS  = "tiptap-dark";

export function getTheme() {
	let stored = null;
	try { stored = window.localStorage.getItem( STORAGE_KEY ); } catch ( e ) {}
	return stored === "dark" ? "dark" : "light";
}

/**
 * Is THIS editor dark? (PresideTiptap.api.isDark)
 *
 * A container argument is the honest question for chrome, and it is not the same
 * as getTheme(): an inline (Modern) editor is deliberately left light whatever
 * the stored preference is, because the editable there IS the site page. Chrome
 * portalled to <body> - a menu, a bubble, a panel - must read the CONTAINER, not
 * the preference, or a dark-preference user gets dark chrome over a light editor.
 */
export function isDark( container ) {
	if ( container && container.classList ) { return container.classList.contains( DARK_CLASS ); }
	return getTheme() === "dark";
}

// Called for every editor as it mounts, so a stored preference applies without
// the user having to toggle again.
export function applyTheme( container, mode ) {
	const dark = ( mode || getTheme() ) === "dark";
	container.classList.toggle( DARK_CLASS, dark );

	// The editable lives in an iframe (src/editorFrame.js), and a class on the
	// container cannot reach into another document - so the frame's own root
	// carries a copy of the flag. Same reason the `--tt-*` variables are declared
	// for `.tiptap-editor-doc` as well as the container.
	const frame = container.querySelector( "iframe.tiptap-editor-frame" );
	try {
		if ( frame && frame.contentDocument ) {
			frame.contentDocument.documentElement.classList.toggle( DARK_CLASS, dark );
		}
	} catch ( e ) {}
}

export function setTheme( mode ) {
	mode = mode === "dark" ? "dark" : "light";
	try { window.localStorage.setItem( STORAGE_KEY, mode ); } catch ( e ) {}

	// Re-theme every editor on the page (and refresh their toggle buttons) rather
	// than keeping a listener registry — editors are created/destroyed freely
	// (frontend editors, quick-add modals), so the live DOM is the only reliable
	// source of "which editors exist".
	const containers = document.querySelectorAll( ".tiptap-editor-container" );
	Array.prototype.forEach.call( containers, function( c ) { applyTheme( c, mode ); } );

	const buttons = document.querySelectorAll( ".tiptap-theme-toggle" );
	Array.prototype.forEach.call( buttons, function( b ) {
		if ( typeof b.__syncTheme === "function" ) { b.__syncTheme(); }
	} );

	return mode;
}

export function toggleTheme() {
	return setTheme( getTheme() === "dark" ? "light" : "dark" );
}

// Opt out with defaultConfigs.darkMode = false (no toggle rendered anywhere).
export function themeEnabled( cfg ) {
	return !cfg || !cfg.defaultConfigs || cfg.defaultConfigs.darkMode !== false;
}

export function renderThemeToggle() {
	const btn = document.createElement( "button" );
	btn.type = "button";
	btn.className = "tiptap-btn tiptap-theme-toggle";
	btn.setAttribute( "data-cmd", "Theme" );

	// The icon shows the CURRENT mode (sun = light, moon = dark); the tooltip says
	// what a click will do. setTheme() calls this on every toggle button on the
	// page, so all editors' buttons stay in sync.
	btn.__syncTheme = function() {
		const mode  = getTheme();
		const title = t( "toolbar.theme." + ( mode === "dark" ? "light" : "dark" ) );
		btn.title = title;
		btn.setAttribute( "aria-label", title );
		btn.setAttribute( "aria-pressed", mode === "dark" ? "true" : "false" );
		btn.innerHTML = mode === "dark" ? ICONS.ThemeDark : ICONS.ThemeLight;
	};
	btn.__syncTheme();

	btn.addEventListener( "click", function( ev ) { ev.preventDefault(); toggleTheme(); } );
	return btn;
}

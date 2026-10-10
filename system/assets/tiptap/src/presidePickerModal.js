/**
 * PresidePickerModal — a CKEditor-"dialog"-shaped modal that hosts a Preside admin
 * picker iframe and speaks the exact `onDialogEvent` contract, so the existing
 * picker pages and their behaviour files (linkpicker / pickerForEditorDialog /
 * widgets) are reused verbatim.
 *
 * The iframe page calls back through one of:
 *   dialog._plugin.updateLink(data, dialog)                    (link)
 *   dialog.getContentElement("iframe")._config      + commitContent()  (image/attachment)
 *   dialog.getContentElement("iframe")._widgetConfig + commitContent()  (widget)
 *
 * We provide: enableButton/disableButton("ok"), getContentElement("iframe"),
 * commitContent(), hide(), click("ok"), `_plugin`, and `_.selectedElement`.
 */

import { t } from "./i18n.js";

let seq = 0;

export function openPickerModal( opts ) {
	// opts: { title, url, prefillData, storeUrl, plugin, selectedElement, onCommit }
	const id = "preside-picker-" + ( ++seq );

	// ---- DOM -----------------------------------------------------------------
	const overlay = document.createElement( "div" );
	overlay.className = "preside-picker-overlay";
	overlay.id = id;
	overlay.innerHTML =
		'<div class="preside-picker-dialog" role="dialog" aria-modal="true">'
		+   '<div class="preside-picker-header"><span class="preside-picker-title"></span>'
		+     '<button type="button" class="preside-picker-close">&times;</button></div>'
		+   '<div class="preside-picker-body"><iframe class="preside-picker-iframe" frameborder="0"></iframe></div>'
		+   '<div class="preside-picker-footer">'
		+     '<button type="button" class="preside-picker-cancel"></button>'
		+     '<button type="button" class="preside-picker-ok" disabled></button>'
		+   '</div>'
		+ '</div>';
	document.body.appendChild( overlay );

	overlay.querySelector( ".preside-picker-title" ).textContent = opts.title || "";
	const iframe   = overlay.querySelector( ".preside-picker-iframe" );
	const okBtn    = overlay.querySelector( ".preside-picker-ok" );
	const cancelBtn = overlay.querySelector( ".preside-picker-cancel" );
	const closeBtn = overlay.querySelector( ".preside-picker-close" );

	okBtn.textContent     = t( "picker.ok" );
	cancelBtn.textContent = t( "picker.cancel" );
	closeBtn.setAttribute( "aria-label", t( "picker.close" ) );

	// A stand-in for CKEditor's dialog content element. The iframe behaviour files
	// write _config / _widgetConfig onto it and call dialog.commitContent().
	const iframeContentElement = { _config: null, _widgetConfig: null };

	let closed = false;
	function close() {
		if ( closed ) { return; }
		closed = true;
		overlay.remove();
	}

	// ---- The CKEditor-shaped dialog facade ----------------------------------
	const dialog = {
		_plugin: opts.plugin || null,
		_: { selectedElement: opts.selectedElement || null },
		enableButton: function( name ) { if ( name === "ok" ) { okBtn.disabled = false; } },
		disableButton: function( name ) { if ( name === "ok" ) { okBtn.disabled = true; } },
		getContentElement: function() { return iframeContentElement; },
		commitContent: function() {
			const value = iframeContentElement._config || iframeContentElement._widgetConfig;
			if ( value && typeof opts.onCommit === "function" ) { opts.onCommit( value ); }
		},
		hide: function() { close(); },
		getParentEditor: function() { return opts.editor || null; },
		click: function( name ) { if ( name === "ok" ) { doOk(); } }
	};

	function fire( name ) {
		const win = iframe.contentWindow;
		if ( win && typeof win.onDialogEvent === "function" ) {
			return win.onDialogEvent( { name: name, sender: dialog }, dialog );
		}
		return true;
	}

	function doOk() {
		// onDialogEvent 'ok': returning false keeps the dialog open (validation fail).
		const result = fire( "ok" );
		if ( result === false ) { return; }
		close();
	}
	function doCancel() { fire( "cancel" ); close(); }

	okBtn.addEventListener( "click", doOk );
	cancelBtn.addEventListener( "click", doCancel );
	closeBtn.addEventListener( "click", doCancel );
	overlay.addEventListener( "click", function( e ) { if ( e.target === overlay ) { doCancel(); } } );

	iframe.addEventListener( "load", function() {
		// Only fire once the real picker page is loaded (skip about:blank).
		if ( !iframe.src || iframe.src === "about:blank" ) { return; }
		fire( "load" );
	} );

	// ---- Load: stash prefill data (FlashRAM), then point the iframe at the page.
	function go() { iframe.src = opts.url; }
	if ( opts.prefillData && opts.storeUrl ) {
		postForm( opts.storeUrl, opts.prefillData ).then( go, go );
	} else {
		go();
	}

	return dialog;
}

// POST the (possibly complex) prefill data as form-encoded, mirroring the jQuery
// $.ajax the CKEditor dialogs use for ajaxhelper.temporarilyStoreData.
//
// Arrays are joined as a comma list: the stored data round-trips through CFML's
// rc into the picker page's `cfrequest` verbatim, and the picker JS expects
// e.g. `cfrequest.anchors` to be a comma string (it does `anchors.split(",")` -
// see core linkPickerFormBehaviour.js). JSON.stringify-ing here leaks brackets
// and quotes into the anchor dropdown items.
export function postForm( url, data ) {
	const body = new URLSearchParams();
	Object.keys( data || {} ).forEach( function( k ) {
		let v = data[ k ];
		if ( v === null || v === undefined ) { v = ""; }
		else if ( Array.isArray( v ) ) { v = v.join( "," ); }
		else if ( typeof v === "object" ) { v = JSON.stringify( v ); }
		body.append( k, v );
	} );
	return fetch( url, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: body.toString(), credentials: "same-origin" } );
}

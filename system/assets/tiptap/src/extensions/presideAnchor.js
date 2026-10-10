/**
 * PresideAnchor — named anchor (bookmark) matching CKEditor's anchor plugin.
 *
 * CKEditor's anchor dialog is a single "name" field that inserts an empty
 * `<a id="name" name="name"></a>` at the cursor (a link target). We reproduce that
 * as an inline atom node so it round-trips (existing anchors in stored content
 * would otherwise be dropped) and is visible + editable in the editor.
 *
 *   toolbar "PresideAnchor"  -> openPresideAnchorDialog (insert)
 *   double-click an anchor   -> edit its name in place
 *   the link picker "anchor" type lists these (see collectAnchors in presideLink)
 */
import { Node } from "@tiptap/core";
import { t } from "../i18n.js";

export function createPresideAnchor() {
	return Node.create( {
		name      : "presideAnchor",
		group     : "inline",
		inline    : true,
		atom      : true,
		selectable: true,

		addAttributes() {
			return { name: { default: null } };
		},

		parseHTML() {
			return [ {
				tag: "a",
				getAttrs: function( el ) {
					if ( el.getAttribute( "href" ) ) { return false; }                 // links are PresideLink
					const name = el.getAttribute( "name" ) || el.getAttribute( "data-cke-saved-name" ) || el.getAttribute( "id" );
					if ( !name ) { return false; }
					if ( el.textContent && el.textContent.trim().length ) { return false; } // content-bearing anchor: leave alone
					return { name: name };
				}
			} ];
		},

		renderHTML( { node } ) {
			const name = node.attrs.name || "";
			return [ "a", { id: name, name: name } ]; // <a id="name" name="name"></a>
		},

		addNodeView() {
			return ( { editor, node, getPos } ) => makeAnchorDom( node, editor, getPos );
		},

		addCommands() {
			return {
				insertPresideAnchor: ( name ) => ( { chain } ) =>
					chain().focus().insertContent( { type: "presideAnchor", attrs: { name: name } } ).run(),

				openPresideAnchorDialog: () => ( { editor } ) => { openAnchorDialog( editor ); return true; }
			};
		}
	} );
}

function makeAnchorDom( node, editor, getPos ) {
	const dom = document.createElement( "span" );
	dom.className = "preside-anchor";
	dom.setAttribute( "contenteditable", "false" );
	dom.title = t( "anchor.tooltip", { name: node.attrs.name || "" } );
	dom.textContent = "⚓"; // ⚓
	dom.addEventListener( "dblclick", function( e ) {
		e.preventDefault(); e.stopPropagation();
		if ( typeof getPos === "function" ) { editor.chain().setNodeSelection( getPos() ).run(); }
		openAnchorDialog( editor );
	} );
	return { dom: dom };
}

function openAnchorDialog( editor ) {
	const sel       = editor.state.selection;
	const isNodeSel = sel.node && sel.node.type && sel.node.type.name === "presideAnchor";
	const editing   = !!isNodeSel;
	const current   = isNodeSel ? ( sel.node.attrs.name || "" ) : "";

	const overlay = document.createElement( "div" );
	overlay.className = "preside-anchor-overlay";
	overlay.innerHTML =
		'<div class="preside-anchor-dialog" role="dialog" aria-modal="true">'
		+   '<div class="preside-anchor-head"></div>'
		+   '<input type="text" class="preside-anchor-input" />'
		+   '<div class="preside-anchor-foot"><button type="button" class="pa-cancel"></button><button type="button" class="pa-ok"></button></div>'
		+ '</div>';
	document.body.appendChild( overlay );

	overlay.querySelector( ".preside-anchor-head" ).textContent = t( "anchor.dialog.title" );
	overlay.querySelector( ".pa-cancel" ).textContent = t( "picker.cancel" );
	overlay.querySelector( ".pa-ok" ).textContent = t( "picker.ok" );

	const input = overlay.querySelector( ".preside-anchor-input" );
	input.setAttribute( "placeholder", t( "anchor.dialog.placeholder" ) );
	input.value = current;
	setTimeout( function() { input.focus(); input.select(); }, 0 );

	function close() { overlay.remove(); }
	function ok() {
		const name = input.value.trim();
		if ( !name ) { input.focus(); return; }
		if ( editing ) { editor.chain().focus().updateAttributes( "presideAnchor", { name: name } ).run(); }
		else { editor.commands.insertPresideAnchor( name ); }
		close();
	}

	overlay.querySelector( ".pa-ok" ).addEventListener( "click", ok );
	overlay.querySelector( ".pa-cancel" ).addEventListener( "click", close );
	overlay.addEventListener( "mousedown", function( e ) { if ( e.target === overlay ) { close(); } } );
	input.addEventListener( "keydown", function( e ) {
		if ( e.key === "Enter" ) { e.preventDefault(); ok(); }
		else if ( e.key === "Escape" ) { e.preventDefault(); close(); }
	} );
}

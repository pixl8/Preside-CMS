/**
 * Embed bubble — the floating toolbar over a SELECTED embed, and the placement it
 * shares with the image one.
 *
 * The image's bubble (src/imageTools.js) has align / size / edit / remove; widgets
 * and attachments have no geometry to offer, so theirs is just **Edit** and
 * **Remove**. Same chrome, same placement, same keyboard/pointer behaviour - because
 * it is literally the same code: `placeBubble()` and `bubbleButton()` live here and
 * imageTools imports them, so the two cannot drift apart.
 *
 * The placement rules are the ones the image bubble arrived at the hard way:
 *  - anchored to the embed's LEFT edge, then nudged to stay inside the editable.
 *    Centring it on the embed clipped half the buttons off the editor border on any
 *    small or left-floated one.
 *  - it prefers to sit ABOVE and flips BELOW (`.is-below`) when there is no room.
 *    An embed at the top of a field otherwise put the bubble over the toolbar, or
 *    outside the mount entirely, with none of its buttons reachable.
 *  - the room is measured against the mount's INTERSECTION WITH THE VIEWPORT, as the
 *    table bubble and the Modern selection bubble also do: inline the mount is
 *    page-height, so the raw rect answers the wrong question.
 */
import { ICONS } from "./icons.js";
import { focusEditable } from "./editorFocus.js";
import { t } from "./i18n.js";

/** A bubble button. Keeps the node selected - see the mousedown note below. */
export function bubbleButton( cls, icon, label, text ) {
	const b = document.createElement( "button" );
	b.type = "button";
	b.className = "tiptap-btn " + cls;
	b.title = label;
	b.setAttribute( "aria-label", label );
	if ( text ) { b.textContent = text; } else { b.innerHTML = icon; }
	// Keep focus (and the node selection) where it is: a focused button inside the
	// contenteditable=false wrapper collapses the NodeSelection, which hides the very
	// chrome that was just clicked. stopPropagation also keeps the click off the
	// embed's own select-me mousedown handler.
	b.addEventListener( "mousedown", e => { e.preventDefault(); e.stopPropagation(); } );
	return b;
}

/** Position `bubble` over `frame`: above unless there is no room, clamped inside. */
export function placeBubble( bubble, frame, editor ) {
	bubble.classList.remove( "is-below" );
	bubble.style.left = "0px";

	const mount = editor.view.dom.closest( ".tiptap-editor-mount" );
	const mRect = ( mount || editor.view.dom ).getBoundingClientRect();
	const fRect = frame.getBoundingClientRect();
	if ( fRect.top - Math.max( mRect.top, 0 ) < bubble.offsetHeight + 8 ) {
		bubble.classList.add( "is-below" );
	}

	const bounds = editor.view.dom.getBoundingClientRect();
	const box    = bubble.getBoundingClientRect();
	let dx = 0;
	if ( box.right > bounds.right ) { dx = bounds.right - box.right; }
	if ( box.left + dx < bounds.left ) { dx = bounds.left - box.left; }
	if ( dx ) { bubble.style.left = Math.round( dx ) + "px"; }
}

/**
 * Edit + Remove over one widget/attachment node view.
 *
 * ctx: { dom, frame, node, editor, getPos, openPicker }
 *
 * Returns the same hook shape imageTools does, so the node view treats both the
 * same: { update, previewLoaded, selectNode, deselectNode, ownsEvent, isSelected }.
 */
export function attachEmbedBubble( ctx ) {
	let node     = ctx.node;
	let selected = false;
	const editor = ctx.editor;

	const bubble = document.createElement( "div" );
	bubble.className = "tiptap-embed-bubble";

	const editBtn = bubbleButton( "tiptap-embed-edit", ICONS.Pencil, t( "embed.edit" ) );
	editBtn.addEventListener( "click", function() { ctx.openPicker(); } );
	bubble.appendChild( editBtn );

	const removeBtn = bubbleButton( "tiptap-embed-remove", ICONS.Trash, t( "embed.remove" ) );
	removeBtn.addEventListener( "click", function() {
		const pos = typeof ctx.getPos === "function" ? ctx.getPos() : null;
		if ( pos == null || pos < 0 ) { return; }
		focusEditable( editor ).chain().focus().deleteRange( { from: pos, to: pos + node.nodeSize } ).run();
	} );
	bubble.appendChild( removeBtn );

	ctx.frame.appendChild( bubble );

	return {
		// Nothing here depends on the token's contents, so an attribute change is never
		// "handled locally": returning false lets the node view re-request the preview
		// exactly as it did before this bubble existed.
		  update       : function( newNode ) { node = newNode; return false; }
		, previewLoaded: function() { if ( selected ) { placeBubble( bubble, ctx.frame, editor ); } }
		, selectNode   : function() {
			selected = true;
			ctx.dom.classList.add( "is-selected" );
			placeBubble( bubble, ctx.frame, editor );
		  }
		, deselectNode : function() {
			selected = false;
			ctx.dom.classList.remove( "is-selected" );
		  }
		, ownsEvent    : function( e ) {
			return !!( e.target && e.target.closest && e.target.closest( ".tiptap-embed-bubble" ) );
		  }
		, isSelected   : function() { return selected; }
	};
}

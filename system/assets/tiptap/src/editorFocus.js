/**
 * focusEditable( editor ) -> editor
 *
 * Give the editable DOM focus BEFORE a command chain is built. Call it at every
 * point where OUR chrome runs an editor command, and it returns the editor so it
 * reads inline: `focusEditable( editor ).chain().focus().toggleBold().run()`.
 *
 * WHY THIS EXISTS (Safari, and only Safari).
 *
 * Tiptap snapshots the transaction when a chain is created (`createChain()` does
 * `const tr = state.tr`) and dispatches that same transaction at `.run()`. Its
 * `focus` command contains a Safari-specific branch that focuses the DOM
 * SYNCHRONOUSLY, where every other engine gets it deferred to a
 * requestAnimationFrame:
 *
 *     if ( isSafari() && !isiOS() && !isAndroid() ) {
 *         view.dom.focus( { preventScroll: true } );
 *     }
 *
 * A DOM focus makes prosemirror-view re-read the document selection, and if it
 * differs from `state.selection` it dispatches a correcting transaction of its
 * own. So on Safari the state moves on in the middle of the chain, and `.run()`
 * then applies a transaction built from the state before it:
 *
 *     RangeError: Applying a mismatched transaction
 *
 * The whole chain is lost - so in Safari a toolbar button pressed while the
 * editable was not focused did nothing at all, the outline rail could not move
 * the caret, and core's frontendEditors.js (which calls `editor.focus()` from its
 * own instanceReady handler) threw on every frontend editor open, aborting the
 * rest of core's handler.
 *
 * The fix is the guard at the top of Tiptap's own focus command:
 *
 *     if ( view.hasFocus() && position === null ) { return true; }
 *
 * If the editable ALREADY has focus, `focus()` is a no-op, nothing is dispatched
 * synchronously, and the chain's transaction stays valid. So we take the DOM
 * focus first, outside any transaction, where it is free to trigger whatever
 * ProseMirror wants to dispatch.
 *
 * NOTE this does not help a chain that passes an explicit POSITION
 * (`chain().focus( pos )`) - that skips the guard by design, because it has to
 * move the caret. Those call sites set the selection on the chain instead
 * (`setTextSelection`), or accept the risk knowingly.
 */
export function focusEditable( editor ) {
	try {
		if ( editor && !editor.isDestroyed && editor.view && !editor.view.hasFocus() ) {
			editor.view.focus();
		}
	} catch ( e ) {}
	return editor;
}

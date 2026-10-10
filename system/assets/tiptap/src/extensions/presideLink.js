/**
 * PresideLink — Tiptap Mark replacing StarterKit's link, preserving Preside's link
 * token contract. Stores href verbatim (incl. {{link}}/{{asset}}/{{custom}} tokens)
 * plus target/rel/title/referrerpolicy, and opens the real Preside link-picker
 * iframe (reused unchanged) via PresidePickerModal.
 *
 * Commands:
 *   openPresideLinkPicker()  - open the link picker for the current selection
 *   applyPresideLink(data)   - apply link-form data to the selection
 *   unsetPresideLink()       - remove the link
 */
import { Mark, mergeAttributes } from "@tiptap/core";
import { Plugin } from "@tiptap/pm/state";
import { getLinkAttributes, parseLinkAttributes } from "../presideLinkSerialization.js";
import { openPickerModal } from "../presidePickerModal.js";
import { t } from "../i18n.js";

export function createPresideLink( deps ) {
	deps = deps || {};
	const $             = deps.$;
	const buildAdminLink = deps.buildAdminLink || window.buildAdminLink;

	return Mark.create( {
		name: "presideLink",
		priority: 1000,
		keepOnSplit: false,
		inclusive: false,

		addOptions() {
			return { linkPickerCategory: deps.linkPickerCategory || "" };
		},

		addAttributes() {
			return {
				  href          : { default: null }
				, target        : { default: null }
				, rel           : { default: null }
				, title         : { default: null }
				, referrerpolicy: { default: null }
			};
		},

		parseHTML() {
			return [ { tag: "a[href]" } ];
		},

		renderHTML( { HTMLAttributes } ) {
			// Emit only non-null attributes so getHTML() yields clean stored markup.
			const attrs = {};
			Object.keys( HTMLAttributes ).forEach( function( k ) {
				if ( HTMLAttributes[ k ] !== null && HTMLAttributes[ k ] !== undefined ) { attrs[ k ] = HTMLAttributes[ k ]; }
			} );
			return [ "a", mergeAttributes( attrs ), 0 ];
		},

		addProseMirrorPlugins() {
			const editor   = this.editor;
			const markName = this.name;
			return [ new Plugin( {
				props: {
					// Double-click a link → open the picker pre-populated for editing.
					handleDOMEvents: {
						dblclick: function() {
							// Defer so the browser/ProseMirror have set the selection first.
							setTimeout( function() {
								if ( editor.isActive( markName ) ) { editor.commands.openPresideLinkPicker(); }
							}, 0 );
							return false;
						}
					}
				}
			} ) ];
		},

		addCommands() {
			const markName = this.name;
			const options  = this.options;

			return {
				applyPresideLink: ( data ) => ( { editor, chain, state } ) => {
					const set   = getLinkAttributes( data ).set;
					const attrs = {
						  href          : set.href || null
						, target        : set.target || null
						, rel           : set.rel || null
						, title         : set.title || null
						, referrerpolicy: set.referrerpolicy || null
					};

					const empty = state.selection.empty;
					if ( empty ) {
						const text = data.defaultText || attrs.href || "";
						return chain().focus().insertContent( {
							type: "text", text: text, marks: [ { type: markName, attrs: attrs } ]
						} ).run();
					}
					return chain().focus().extendMarkRange( markName ).setMark( markName, attrs ).run();
				},

				unsetPresideLink: () => ( { chain } ) => {
					return chain().focus().extendMarkRange( markName ).unsetMark( markName ).run();
				},

				openPresideLinkPicker: () => ( { editor } ) => {
					openLinkPicker( editor, markName, options, { $: $, buildAdminLink: buildAdminLink } );
					return true;
				}
			};
		}
	} );
}

function collectAnchors( editor ) {
	const out = [];
	try {
		// Scan the document model - PresideAnchor renders a marker span in the DOM,
		// so the anchor names live on the nodes, not in editor.view.dom as <a name>.
		editor.state.doc.descendants( function( node ) {
			if ( node.type.name === "presideAnchor" && node.attrs.name && out.indexOf( node.attrs.name ) === -1 ) {
				out.push( node.attrs.name );
			}
		} );
	} catch ( e ) {}
	return out;
}

function openLinkPicker( editor, markName, options, deps ) {
	const buildAdminLink = deps.buildAdminLink;

	// Prefill from an existing link at the selection (edit) or start fresh (insert).
	const current  = editor.getAttributes( markName );
	const editing  = !!current.href;
	const data     = editing ? parseLinkAttributes( current ) : {};

	data.newAndEmptyLink = editor.state.selection.empty;
	data.anchors         = collectAnchors( editor );

	const plugin = {
		updateLink: function( formData /*, dialog */ ) {
			editor.commands.applyPresideLink( formData );
			return true;
		}
	};

	openPickerModal( {
		  title           : t( "picker.link.title" )
		, editor          : editor
		, url             : buildAdminLink( "linkpicker", "index", { linkPickerCategory: options.linkPickerCategory || "" } )
		, prefillData     : data
		, storeUrl        : buildAdminLink( "ajaxhelper.temporarilyStoreData" )
		, plugin          : plugin
		, selectedElement : editing ? current : null
	} );
}

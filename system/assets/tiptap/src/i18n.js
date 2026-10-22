/**
 * i18n for the Tiptap editor UI.
 *
 * CKEditor 4 shipped its own language packs and auto-detected the browser
 * locale, so the old editor chrome was localised "for free". This module is
 * the Tiptap equivalent: every user-facing string lives here (English
 * defaults), keyed to match the extension's i18n/tiptap.properties resource
 * bundle. The ckEditorJs.cfm view override translates each key server-side
 * (admin user locale) and ships the result as `cfrequest.tiptapI18n`, so
 * sites localise the editor the standard Preside way - properties files.
 *
 * Lookup order (first non-empty wins):
 *   1. window.cfrequest.tiptapI18n[ key ]   (server-translated, Preside)
 *   2. window.PresideTiptapI18n[ key ]      (manual override, harness/standalone)
 *   3. DEFAULTS[ key ]                      (built-in English)
 *   4. a registered plugin's i18nDefaults[ key ]  (an add-on's own English)
 *
 * A dependent extension adds SERVER-translated strings by appending to
 * `settings.tiptap.i18nKeys` in its own config (entries may name their own
 * resource bundle, "tiptapai:ai.button"); the JS key stays unprefixed, so
 * nothing here has to know which bundle a string came from. Its i18nDefaults
 * are the English fallback for when that key is missing from every bundle -
 * which is why they sit UNDER ours: a plugin can add keys, never silently
 * restate one of the editor's own.
 *
 * Strings are resolved at RENDER time, never at script-parse time - the
 * cfrequest data block may be emitted after this bundle executes.
 *
 * `t( key, subs )` substitutes `{name}` placeholders from subs.
 */

import { pluginI18nDefaults } from "./pluginHost.js";

export const DEFAULTS = {
	  "toolbar.bold"             : "Bold"
	, "toolbar.italic"           : "Italic"
	, "toolbar.underline"        : "Underline"
	, "toolbar.strike"           : "Strikethrough"
	, "toolbar.subscript"        : "Subscript"
	, "toolbar.superscript"      : "Superscript"
	, "toolbar.blockquote"       : "Blockquote"
	, "toolbar.numberedlist"     : "Numbered list"
	, "toolbar.bulletedlist"     : "Bulleted list"
	, "toolbar.outdent"          : "Outdent"
	, "toolbar.indent"           : "Indent"
	, "toolbar.justifyleft"      : "Align left"
	, "toolbar.justifycenter"    : "Align center"
	, "toolbar.justifyright"     : "Align right"
	, "toolbar.justifyblock"     : "Justify"
	, "toolbar.align"            : "Alignment"
	, "toolbar.horizontalrule"   : "Horizontal rule"
	, "toolbar.specialchar"      : "Insert Special Character"
	, "toolbar.find"             : "Find"
	, "toolbar.replace"          : "Replace"
	, "toolbar.bidiltr"          : "Text direction from left to right"
	, "toolbar.bidirtl"          : "Text direction from right to left"
	, "toolbar.table"            : "Table"
	, "toolbar.removeformat"     : "Remove format"
	, "toolbar.undo"             : "Undo"
	, "toolbar.redo"             : "Redo"
	, "toolbar.maximize"         : "Maximize"
	, "toolbar.presidelink"      : "Link"
	, "toolbar.presideunlink"    : "Unlink"
	, "toolbar.presideanchor"    : "Anchor"
	, "toolbar.widgets"          : "Widget"
	, "toolbar.imagepicker"      : "Image"
	, "toolbar.attachmentpicker" : "Attachment"
	, "toolbar.codesnippet"      : "Code snippet"
	, "toolbar.source"           : "Source"
	, "toolbar.theme.dark"       : "Switch to dark mode"
	, "toolbar.theme.light"      : "Switch to light mode"
	, "toolbar.format"           : "Format"
	, "toolbar.styles"           : "Styles"
	, "styles.none"              : "No styles available"
	// The three panel group titles, from CKEditor's lang.stylescombo.panelTitle1/2/3
	// (keyed on the style TYPE - see STYLE_TYPES in toolbar.js).
	, "styles.block"             : "Block Styles"
	, "styles.inline"            : "Inline Styles"
	, "styles.object"            : "Object Styles"
	// lang.format.panelTitle - the single group title over the Format menu.
	, "format.panelTitle"        : "Paragraph Format"
	, "format.p"                 : "Paragraph"
	, "format.h1"                : "Heading 1"
	, "format.h2"                : "Heading 2"
	, "format.h3"                : "Heading 3"
	, "format.h4"                : "Heading 4"
	, "format.h5"                : "Heading 5"
	, "format.h6"                : "Heading 6"
	, "format.pre"               : "Preformatted"
	, "format.div"               : "Normal (DIV)"
	, "picker.ok"                : "OK"
	, "picker.cancel"            : "Cancel"
	, "picker.close"             : "Close"
	, "picker.link.title"        : "Link"
	, "picker.image.title"       : "Image"
	, "picker.attachment.title"  : "Attachment"
	, "picker.widget.title"      : "Widget"
	, "anchor.dialog.title"      : "Anchor name"
	, "anchor.dialog.placeholder": "e.g. section-2"
	, "anchor.tooltip"           : "Anchor: {name} (double-click to edit)"
	, "embed.edithint"           : "Double-click to edit"
	, "embed.loading.image"      : "loading image..."
	, "embed.loading.attachment" : "loading attachment..."
	, "embed.error"              : "preview error"
	, "embed.edit"               : "Edit"
	, "embed.remove"             : "Remove"
	, "image.resize"             : "Drag to resize"
	, "image.align.left"         : "Align left"
	, "image.align.center"       : "Align center"
	, "image.align.right"        : "Align right"
	, "image.size.percent"       : "{count}% of the editor width"
	, "image.size.original"      : "Original size"
	, "image.refresh"            : "Preview is out of date - click to re-render"
	, "image.edit"               : "Edit image"
	, "image.remove"             : "Remove image"
	, "find.title"               : "Find and Replace"
	, "find.find"                : "Find"
	, "find.replace"             : "Replace"
	, "find.replaceall"          : "Replace All"
	, "find.findwhat"            : "Find what:"
	, "find.replacewith"         : "Replace with:"
	, "find.findoptions"         : "Find Options"
	, "find.matchcase"           : "Match case"
	, "find.matchword"           : "Match whole word"
	, "find.matchcyclic"         : "Match cyclic"
	, "find.notfound"            : "The specified text was not found."
	, "find.replaced"            : "{count} occurrence(s) replaced."
	, "specialchar.title"        : "Select Special Character"
	, "specialchar.options"      : "Special Character Options"
	, "table.insert"             : "Insert table"
	, "table.gridsize"           : "{rows} x {cols}"
	, "table.gridcell"           : "Insert a {rows} by {cols} table"
	, "table.withheaderrow"      : "With header row"
	, "table.column.before"      : "Insert column before"
	, "table.column.after"       : "Insert column after"
	, "table.column.delete"      : "Delete column"
	, "table.row.before"         : "Insert row above"
	, "table.row.after"          : "Insert row below"
	, "table.row.delete"         : "Delete row"
	, "table.cells.merge"        : "Merge cells"
	, "table.cells.split"        : "Split cell"
	, "table.headerrow"          : "Header row"
	, "table.headercolumn"       : "Header column"
	, "table.delete"             : "Delete table"
	, "draghandle.tooltip"       : "Drag to move, click to select"
	, "draghandle.insert"        : "Insert block below"
	, "slash.title"              : "Insert"
	, "slash.empty"              : "Nothing matches"
	, "slash.group.format"       : "Format"
	, "slash.group.block"        : "Blocks"
	, "slash.group.preside"      : "Content"
	, "slash.group.widget"       : "Widgets"
	, "slash.h1"                 : "Heading 1"
	, "slash.h1.hint"            : "Large section heading"
	, "slash.h2"                 : "Heading 2"
	, "slash.h2.hint"            : "Medium section heading"
	, "slash.h3"                 : "Heading 3"
	, "slash.h3.hint"            : "Small section heading"
	, "slash.paragraph"          : "Text"
	, "slash.paragraph.hint"     : "Plain paragraph"
	, "slash.bulletlist"         : "Bulleted list"
	, "slash.bulletlist.hint"    : "A simple bulleted list"
	, "slash.orderedlist"        : "Numbered list"
	, "slash.orderedlist.hint"   : "A list with numbering"
	, "slash.blockquote"         : "Quote"
	, "slash.blockquote.hint"    : "Capture a quotation"
	, "slash.codeblock"          : "Code"
	, "slash.codeblock.hint"     : "A preformatted code block"
	, "slash.hr"                 : "Divider"
	, "slash.hr.hint"            : "A horizontal rule"
	, "slash.table"              : "Table"
	, "slash.table.hint"         : "Insert a table"
	, "slash.image"              : "Image"
	, "slash.image.hint"         : "Pick an image from the asset manager"
	, "slash.attachment"         : "Attachment"
	, "slash.attachment.hint"    : "Pick a file from the asset manager"
	, "slash.widget"             : "Widget"
	, "slash.widget.hint"        : "Browse all available widgets"
	, "slash.link"               : "Link"
	, "slash.link.hint"          : "Link the selected text"
	, "slash.anchor"             : "Anchor"
	, "slash.anchor.hint"        : "Add a named anchor to link to"
	, "outline.title"            : "Document outline"
	, "outline.empty"            : "No headings yet"
	, "outline.untitled"         : "(untitled)"
	, "resize.tooltip"           : "Resize"
	, "footer.words"             : "{count} words"
	, "footer.chars"             : "{count} chars"
	, "footer.readingtime"       : "~{count} min read"
	, "editmode.trigger"         : "Quick edit"
	, "editmode.off"             : "Off"
	, "editmode.classic"         : "Classic"
	, "editmode.modern"          : "Modern"
	, "editmode.modern.unavailable": "Available when the page has exactly one rich content area"
	, "editmode.unsaved.confirm" : "You have unsaved changes. Save them as a draft before leaving edit mode? (Cancel discards them)"
	, "bubble.title"             : "Text formatting"
};

function overrides() {
	var cf = window.cfrequest || {};
	return cf.tiptapI18n || window.PresideTiptapI18n || {};
}

export function t( key, subs ) {
	var o = overrides();
	var s = ( o[ key ] !== undefined && o[ key ] !== null && String( o[ key ] ).length ) ? o[ key ] : DEFAULTS[ key ];
	if ( s === undefined || s === null ) { s = pluginI18nDefaults()[ key ]; }
	if ( s === undefined || s === null ) { return key; }
	s = String( s );
	if ( subs ) {
		Object.keys( subs ).forEach( function( k ) {
			s = s.split( "{" + k + "}" ).join( String( subs[ k ] ) );
		} );
	}
	return s;
}

/**
 * t(), but "" for a key that resolves nowhere.
 *
 * `t()` returns the KEY when it finds nothing, which is the right behaviour for
 * a string that must exist (it shows up in the UI and gets fixed). It is the
 * wrong behaviour for an OPTIONAL one - a plugin's "/" menu item with no hint
 * would render the literal text "slash.foo.hint" underneath its label.
 */
export function tIf( key, subs ) {
	var s = t( key, subs );
	return s === key ? "" : s;
}

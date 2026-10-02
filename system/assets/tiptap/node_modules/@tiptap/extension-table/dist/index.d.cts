import { ParentConfig, Node, JSONContent, MarkdownRendererHelpers, Extension } from '@tiptap/core';
import { Node as Node$1, DOMOutputSpec, Schema, Fragment } from '@tiptap/pm/model';
import { EditorView, NodeView, ViewMutationRecord } from '@tiptap/pm/view';

declare module '@tiptap/core' {
    interface NodeConfig<Options, Storage> {
        /**
         * A string or function to determine the role of the table.
         * @default 'table'
         * @example () => 'table'
         */
        tableRole?: string | ((this: {
            name: string;
            options: Options;
            storage: Storage;
            parent: ParentConfig<NodeConfig<Options>>['tableRole'];
        }) => string);
    }
}

interface TableCellOptions {
    /**
     * The HTML attributes for a table cell node.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}
/**
 * This extension allows you to create table cells.
 * @see https://www.tiptap.dev/api/nodes/table-cell
 */
declare const TableCell: Node<TableCellOptions, any>;

interface TableHeaderOptions {
    /**
     * The HTML attributes for a table header node.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}
/**
 * This extension allows you to create table headers.
 * @see https://www.tiptap.dev/api/nodes/table-header
 */
declare const TableHeader: Node<TableHeaderOptions, any>;

interface TableRowOptions {
    /**
     * The HTML attributes for a table row node.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}
/**
 * This extension allows you to create table rows.
 * @see https://www.tiptap.dev/api/nodes/table-row
 */
declare const TableRow: Node<TableRowOptions, any>;

interface TableOptions {
    /**
     * HTML attributes for the table element.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
    /**
     * Enables the resizing of tables.
     * @default false
     * @example true
     */
    resizable: boolean;
    /**
     * Controls whether the table should be wrapped in a div with class "tableWrapper" when rendered.
     * In editable mode with resizable tables, this wrapper is always present via TableView.
     * @default false
     * @example true
     */
    renderWrapper: boolean;
    /**
     * The width of the resize handle.
     * @default 5
     * @example 10
     */
    handleWidth: number;
    /**
     * The minimum width of a cell.
     * @default 25
     * @example 50
     */
    cellMinWidth: number;
    /**
     * The node view to render the table.
     * @default TableView
     */
    View: (new (node: Node$1, cellMinWidth: number, view: EditorView, HTMLAttributes?: Record<string, any>) => NodeView) | null;
    /**
     * Enables the resizing of the last column.
     * @default true
     * @example false
     */
    lastColumnResizable: boolean;
    /**
     * Allow table node selection.
     * @default false
     * @example true
     */
    allowTableNodeSelection: boolean;
}
declare module '@tiptap/core' {
    interface Commands<ReturnType> {
        table: {
            /**
             * Insert a table
             * @param options The table attributes
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.insertTable({ rows: 3, cols: 3, withHeaderRow: true })
             */
            insertTable: (options?: {
                rows?: number;
                cols?: number;
                withHeaderRow?: boolean;
            }) => ReturnType;
            /**
             * Add a column before the current column
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.addColumnBefore()
             */
            addColumnBefore: () => ReturnType;
            /**
             * Add a column after the current column
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.addColumnAfter()
             */
            addColumnAfter: () => ReturnType;
            /**
             * Delete the current column
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.deleteColumn()
             */
            deleteColumn: () => ReturnType;
            /**
             * Add a row before the current row
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.addRowBefore()
             */
            addRowBefore: () => ReturnType;
            /**
             * Add a row after the current row
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.addRowAfter()
             */
            addRowAfter: () => ReturnType;
            /**
             * Delete the current row
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.deleteRow()
             */
            deleteRow: () => ReturnType;
            /**
             * Delete the current table
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.deleteTable()
             */
            deleteTable: () => ReturnType;
            /**
             * Merge the currently selected cells
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.mergeCells()
             */
            mergeCells: () => ReturnType;
            /**
             * Split the currently selected cell
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.splitCell()
             */
            splitCell: () => ReturnType;
            /**
             * Toggle the header column
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.toggleHeaderColumn()
             */
            toggleHeaderColumn: () => ReturnType;
            /**
             * Toggle the header row
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.toggleHeaderRow()
             */
            toggleHeaderRow: () => ReturnType;
            /**
             * Toggle the header cell
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.toggleHeaderCell()
             */
            toggleHeaderCell: () => ReturnType;
            /**
             * Merge or split the currently selected cells
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.mergeOrSplit()
             */
            mergeOrSplit: () => ReturnType;
            /**
             * Set a cell attribute
             * @param name The attribute name
             * @param value The attribute value
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.setCellAttribute('align', 'right')
             */
            setCellAttribute: (name: string, value: any) => ReturnType;
            /**
             * Moves the selection to the next cell
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.goToNextCell()
             */
            goToNextCell: () => ReturnType;
            /**
             * Moves the selection to the previous cell
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.goToPreviousCell()
             */
            goToPreviousCell: () => ReturnType;
            /**
             * Try to fix the table structure if necessary
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.fixTables()
             */
            fixTables: () => ReturnType;
            /**
             * Set a cell selection inside the current table
             * @param position The cell position
             * @returns True if the command was successful, otherwise false
             * @example editor.commands.setCellSelection({ anchorCell: 1, headCell: 2 })
             */
            setCellSelection: (position: {
                anchorCell: number;
                headCell?: number;
            }) => ReturnType;
        };
    }
}
/**
 * This extension allows you to create tables.
 * @see https://www.tiptap.dev/api/nodes/table
 */
declare const Table: Node<TableOptions, any>;

type ColGroup = {
    colgroup: DOMOutputSpec;
    tableWidth: string;
    tableMinWidth: string;
} | Record<string, never>;
/**
 * Creates a colgroup element for a table node in ProseMirror.
 *
 * @param node - The ProseMirror node representing the table.
 * @param cellMinWidth - The minimum width of a cell in the table.
 * @param overrideCol - (Optional) The index of the column to override the width of.
 * @param overrideValue - (Optional) The width value to use for the overridden column.
 * @returns An object containing the colgroup element, the total width of the table, and the minimum width of the table.
 */
declare function createColGroup(node: Node$1, cellMinWidth: number): ColGroup;
declare function createColGroup(node: Node$1, cellMinWidth: number, overrideCol: number, overrideValue: number): ColGroup;

declare function createTable(schema: Schema, rowsCount: number, colsCount: number, withHeaderRow: boolean, cellContent?: Fragment | Node$1 | Array<Node$1>): Node$1;

declare const DEFAULT_CELL_LINE_SEPARATOR = "\u001F";
/**
 * Walk a single table-row line and escape any `|` characters that appear
 * inside backtick code spans so marked's cell splitter ignores them.
 * Backslash escape sequences outside code spans are passed through untouched.
 * If a backtick run has no matching closer on the same line it is emitted
 * as-is — no over-escaping for malformed input.
 */
declare function escapeTableCellPipes(line: string): string;
/**
 * Escape pipe characters inside backtick code spans on table-row lines.
 * marked's `splitCells` only recognises backslash-escaped pipes (`\|`) and
 * splits on every other `|`, so \`a || b\` in a table cell would be treated
 * as multiple column delimiters. Escaping them here lets `splitCells` skip
 * them; it already converts `\|` → `|` after splitting, so the cell content
 * is restored correctly.
 */
declare function preprocessTablePipes(src: string): string;
declare function renderTableToMarkdown(node: JSONContent, h: MarkdownRendererHelpers, options?: {
    cellLineSeparator?: string;
}): string;

interface TableKitOptions {
    /**
     * If set to false, the table extension will not be registered
     * @example table: false
     */
    table: Partial<TableOptions> | false;
    /**
     * If set to false, the table extension will not be registered
     * @example tableCell: false
     */
    tableCell: Partial<TableCellOptions> | false;
    /**
     * If set to false, the table extension will not be registered
     * @example tableHeader: false
     */
    tableHeader: Partial<TableHeaderOptions> | false;
    /**
     * If set to false, the table extension will not be registered
     * @example tableRow: false
     */
    tableRow: Partial<TableRowOptions> | false;
}
/**
 * The table kit is a collection of table editor extensions.
 *
 * It’s a good starting point for building your own table in Tiptap.
 */
declare const TableKit: Extension<TableKitOptions, any>;

declare function updateColumns(node: Node$1, colgroup: HTMLTableColElement, // <colgroup> has the same prototype as <col>
table: HTMLTableElement, cellMinWidth: number, overrideCol?: number, overrideValue?: number): void;
declare class TableView implements NodeView {
    node: Node$1;
    cellMinWidth: number;
    dom: HTMLDivElement;
    table: HTMLTableElement;
    colgroup: HTMLTableColElement;
    contentDOM: HTMLTableSectionElement;
    constructor(node: Node$1, cellMinWidth: number, _view?: EditorView, HTMLAttributes?: Record<string, any>);
    update(node: Node$1): boolean;
    ignoreMutation(mutation: ViewMutationRecord): boolean;
}

export { type ColGroup, DEFAULT_CELL_LINE_SEPARATOR, Table, TableCell, type TableCellOptions, TableHeader, type TableHeaderOptions, TableKit, type TableKitOptions, type TableOptions, TableRow, type TableRowOptions, TableView, createColGroup, createTable, escapeTableCellPipes, preprocessTablePipes, renderTableToMarkdown, updateColumns };

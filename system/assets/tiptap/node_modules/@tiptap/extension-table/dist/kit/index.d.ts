import { ParentConfig, Extension } from '@tiptap/core';
import { Node } from '@tiptap/pm/model';
import { EditorView, NodeView } from '@tiptap/pm/view';

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

interface TableHeaderOptions {
    /**
     * The HTML attributes for a table header node.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}

interface TableRowOptions {
    /**
     * The HTML attributes for a table row node.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}

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
    View: (new (node: Node, cellMinWidth: number, view: EditorView, HTMLAttributes?: Record<string, any>) => NodeView) | null;
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

export { TableKit, type TableKitOptions };

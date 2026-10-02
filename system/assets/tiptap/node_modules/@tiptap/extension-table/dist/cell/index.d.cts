import { ParentConfig, Node } from '@tiptap/core';

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

export { TableCell, type TableCellOptions };

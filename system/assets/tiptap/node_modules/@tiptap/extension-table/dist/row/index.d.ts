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

export { TableRow, type TableRowOptions };

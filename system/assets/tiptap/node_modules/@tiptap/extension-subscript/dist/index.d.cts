import { Mark } from '@tiptap/core';

interface SubscriptExtensionOptions {
    /**
     * HTML attributes to add to the subscript element.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}
declare module '@tiptap/core' {
    interface Commands<ReturnType> {
        subscript: {
            /**
             * Set a subscript mark
             * @example editor.commands.setSubscript()
             */
            setSubscript: () => ReturnType;
            /**
             * Toggle a subscript mark
             * @example editor.commands.toggleSubscript()
             */
            toggleSubscript: () => ReturnType;
            /**
             * Unset a subscript mark
             * @example editor.commands.unsetSubscript()
             */
            unsetSubscript: () => ReturnType;
        };
    }
}
/**
 * This extension allows you to create subscript text.
 * @see https://www.tiptap.dev/api/marks/subscript
 */
declare const Subscript: Mark<SubscriptExtensionOptions, any>;

export { Subscript, type SubscriptExtensionOptions, Subscript as default };

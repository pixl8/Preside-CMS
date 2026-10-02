import { Mark } from '@tiptap/core';

interface SuperscriptExtensionOptions {
    /**
     * HTML attributes to add to the superscript element.
     * @default {}
     * @example { class: 'foo' }
     */
    HTMLAttributes: Record<string, any>;
}
declare module '@tiptap/core' {
    interface Commands<ReturnType> {
        superscript: {
            /**
             * Set a superscript mark
             * @example editor.commands.setSuperscript()
             */
            setSuperscript: () => ReturnType;
            /**
             * Toggle a superscript mark
             * @example editor.commands.toggleSuperscript()
             */
            toggleSuperscript: () => ReturnType;
            /**
             * Unset a superscript mark
             *  @example editor.commands.unsetSuperscript()
             */
            unsetSuperscript: () => ReturnType;
        };
    }
}
/**
 * This extension allows you to create superscript text.
 * @see https://www.tiptap.dev/api/marks/superscript
 */
declare const Superscript: Mark<SuperscriptExtensionOptions, any>;

export { Superscript, type SuperscriptExtensionOptions, Superscript as default };

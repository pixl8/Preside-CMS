"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.ts
var index_exports = {};
__export(index_exports, {
  Superscript: () => Superscript,
  default: () => index_default
});
module.exports = __toCommonJS(index_exports);

// src/superscript.ts
var import_core = require("@tiptap/core");
var Superscript = import_core.Mark.create({
  name: "superscript",
  addOptions() {
    return {
      HTMLAttributes: {}
    };
  },
  parseHTML() {
    return [
      {
        tag: "sup"
      },
      {
        style: "vertical-align",
        getAttrs(value) {
          if (value !== "super") {
            return false;
          }
          return null;
        }
      }
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return ["sup", (0, import_core.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
  addCommands() {
    return {
      setSuperscript: () => ({ commands }) => {
        return commands.setMark(this.name);
      },
      toggleSuperscript: () => ({ commands }) => {
        return commands.toggleMark(this.name);
      },
      unsetSuperscript: () => ({ commands }) => {
        return commands.unsetMark(this.name);
      }
    };
  },
  addKeyboardShortcuts() {
    return {
      "Mod-.": () => this.editor.commands.toggleSuperscript()
    };
  }
});

// src/index.ts
var index_default = Superscript;
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  Superscript
});
//# sourceMappingURL=index.cjs.map
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
  Subscript: () => Subscript,
  default: () => index_default
});
module.exports = __toCommonJS(index_exports);

// src/subscript.ts
var import_core = require("@tiptap/core");
var Subscript = import_core.Mark.create({
  name: "subscript",
  addOptions() {
    return {
      HTMLAttributes: {}
    };
  },
  parseHTML() {
    return [
      {
        tag: "sub"
      },
      {
        style: "vertical-align",
        getAttrs(value) {
          if (value !== "sub") {
            return false;
          }
          return null;
        }
      }
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return ["sub", (0, import_core.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
  addCommands() {
    return {
      setSubscript: () => ({ commands }) => {
        return commands.setMark(this.name);
      },
      toggleSubscript: () => ({ commands }) => {
        return commands.toggleMark(this.name);
      },
      unsetSubscript: () => ({ commands }) => {
        return commands.unsetMark(this.name);
      }
    };
  },
  addKeyboardShortcuts() {
    return {
      "Mod-,": () => this.editor.commands.toggleSubscript()
    };
  }
});

// src/index.ts
var index_default = Subscript;
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  Subscript
});
//# sourceMappingURL=index.cjs.map
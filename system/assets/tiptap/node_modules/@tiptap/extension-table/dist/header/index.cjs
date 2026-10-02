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

// src/header/index.ts
var index_exports = {};
__export(index_exports, {
  TableHeader: () => TableHeader
});
module.exports = __toCommonJS(index_exports);

// src/header/table-header.ts
var import_core = require("@tiptap/core");

// src/utils/parseAlign.ts
function normalizeTableCellAlign(value) {
  if (value === "left" /* Left */ || value === "right" /* Right */ || value === "center" /* Center */) {
    return value;
  }
  return null;
}
function parseAlign(element) {
  const styleAlign = (element.style.textAlign || "").trim().toLowerCase();
  const attrAlign = (element.getAttribute("align") || "").trim().toLowerCase();
  const align = styleAlign || attrAlign;
  return normalizeTableCellAlign(align);
}
function createAlignAttribute() {
  return {
    default: null,
    parseHTML: (element) => parseAlign(element),
    renderHTML: (attributes) => {
      if (!attributes.align) {
        return {};
      }
      return {
        style: `text-align: ${attributes.align}`
      };
    }
  };
}

// src/utils/parseColwidth.ts
function parseColgroupWidth(element) {
  var _a;
  const row = element.parentElement;
  const table = element.closest("table");
  if (!row || !table) {
    return null;
  }
  const cellIndex = Array.from(row.children).indexOf(element);
  const width = (_a = table.querySelectorAll("colgroup > col")[cellIndex]) == null ? void 0 : _a.getAttribute("width");
  return width ? [parseInt(width, 10)] : null;
}
function parseColwidth(element) {
  const colwidth = element.getAttribute("colwidth");
  if (colwidth) {
    return colwidth.split(",").map((width) => parseInt(width, 10));
  }
  return parseColgroupWidth(element);
}

// src/utils/fillEmptyCellContent.ts
var COLLAPSIBLE_WHITESPACE = /[ \t\r\n\f]+/g;
function isEmptyCellElement(element) {
  var _a;
  if (element.children.length > 0) {
    return false;
  }
  return ((_a = element.textContent) != null ? _a : "").replace(COLLAPSIBLE_WHITESPACE, "") === "";
}
function fillEmptyCellContent(cellType) {
  const filled = cellType.createAndFill();
  if (!filled) {
    throw new Error(`[tiptap error]: "${cellType.name}" has no default content to backfill.`);
  }
  return filled.content;
}

// src/header/table-header.ts
var TableHeader = import_core.Node.create({
  name: "tableHeader",
  addOptions() {
    return {
      HTMLAttributes: {}
    };
  },
  content: "block+",
  addAttributes() {
    return {
      colspan: {
        default: 1
      },
      rowspan: {
        default: 1
      },
      colwidth: {
        default: null,
        parseHTML: parseColwidth
      },
      align: createAlignAttribute()
    };
  },
  tableRole: "header_cell",
  isolating: true,
  parseHTML() {
    return [
      {
        // Backfill empty cells; non-empty cells fall through to the rule below.
        tag: "th",
        getAttrs: (node) => isEmptyCellElement(node) ? {} : false,
        getContent: (_node, schema) => fillEmptyCellContent(schema.nodes[this.name])
      },
      { tag: "th" }
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return ["th", (0, import_core.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes), 0];
  }
});
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  TableHeader
});
//# sourceMappingURL=index.cjs.map
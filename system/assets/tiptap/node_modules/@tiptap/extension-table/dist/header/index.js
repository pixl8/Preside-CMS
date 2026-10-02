// src/header/table-header.ts
import { mergeAttributes, Node } from "@tiptap/core";

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
var TableHeader = Node.create({
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
    return ["th", mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  }
});
export {
  TableHeader
};
//# sourceMappingURL=index.js.map
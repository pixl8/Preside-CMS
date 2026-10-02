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

// src/kit/index.ts
var index_exports = {};
__export(index_exports, {
  TableKit: () => TableKit
});
module.exports = __toCommonJS(index_exports);
var import_core6 = require("@tiptap/core");

// src/cell/table-cell.ts
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
function normalizeTableCellAlignFromAttributes(attributes) {
  return normalizeTableCellAlign(attributes == null ? void 0 : attributes.align);
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

// src/cell/table-cell.ts
var TableCell = import_core.Node.create({
  name: "tableCell",
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
  tableRole: "cell",
  isolating: true,
  parseHTML() {
    return [
      {
        // Backfill empty cells; non-empty cells fall through to the rule below.
        tag: "td",
        getAttrs: (node) => isEmptyCellElement(node) ? {} : false,
        getContent: (_node, schema) => fillEmptyCellContent(schema.nodes[this.name])
      },
      { tag: "td" }
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return ["td", (0, import_core.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes), 0];
  }
});

// src/header/table-header.ts
var import_core2 = require("@tiptap/core");
var TableHeader = import_core2.Node.create({
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
    return ["th", (0, import_core2.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes), 0];
  }
});

// src/row/table-row.ts
var import_core3 = require("@tiptap/core");
var TableRow = import_core3.Node.create({
  name: "tableRow",
  addOptions() {
    return {
      HTMLAttributes: {}
    };
  },
  content: "(tableCell | tableHeader)*",
  tableRole: "row",
  parseHTML() {
    return [{ tag: "tr" }];
  },
  renderHTML({ HTMLAttributes }) {
    return ["tr", (0, import_core3.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes), 0];
  }
});

// src/table/table.ts
var import_core5 = require("@tiptap/core");
var import_state = require("@tiptap/pm/state");
var import_tables2 = require("@tiptap/pm/tables");

// src/table/utilities/colStyle.ts
function getColStyleDeclaration(minWidth, width) {
  if (width) {
    return ["width", `${Math.max(width, minWidth)}px`];
  }
  return ["min-width", `${minWidth}px`];
}

// src/table/TableView.ts
function updateColumns(node, colgroup, table, cellMinWidth, overrideCol, overrideValue) {
  var _a;
  let totalWidth = 0;
  let fixedWidth = true;
  let nextDOM = colgroup.firstChild;
  const row = node.firstChild;
  if (row !== null) {
    for (let i = 0, col = 0; i < row.childCount; i += 1) {
      const { colspan, colwidth } = row.child(i).attrs;
      for (let j = 0; j < colspan; j += 1, col += 1) {
        const hasWidth = overrideCol === col ? overrideValue : colwidth && colwidth[j];
        const cssWidth = hasWidth ? `${hasWidth}px` : "";
        totalWidth += hasWidth || cellMinWidth;
        if (!hasWidth) {
          fixedWidth = false;
        }
        if (!nextDOM) {
          const colElement = document.createElement("col");
          const [propertyKey, propertyValue] = getColStyleDeclaration(cellMinWidth, hasWidth);
          colElement.style.setProperty(propertyKey, propertyValue);
          colgroup.appendChild(colElement);
        } else {
          if (nextDOM.style.width !== cssWidth) {
            const [propertyKey, propertyValue] = getColStyleDeclaration(cellMinWidth, hasWidth);
            nextDOM.style.setProperty(propertyKey, propertyValue);
          }
          nextDOM = nextDOM.nextSibling;
        }
      }
    }
  }
  while (nextDOM) {
    const after = nextDOM.nextSibling;
    (_a = nextDOM.parentNode) == null ? void 0 : _a.removeChild(nextDOM);
    nextDOM = after;
  }
  const hasUserWidth = node.attrs.style && typeof node.attrs.style === "string" && /\bwidth\s*:/i.test(node.attrs.style);
  if (fixedWidth && !hasUserWidth) {
    table.style.width = `${totalWidth}px`;
    table.style.minWidth = "";
  } else {
    table.style.width = "";
    table.style.minWidth = `${totalWidth}px`;
  }
}
var TableView = class {
  constructor(node, cellMinWidth, _view, HTMLAttributes = {}) {
    this.node = node;
    this.cellMinWidth = cellMinWidth;
    this.dom = document.createElement("div");
    this.dom.className = "tableWrapper";
    this.table = this.dom.appendChild(document.createElement("table"));
    for (const [key, value] of Object.entries(HTMLAttributes)) {
      if (value !== void 0 && value !== null) {
        if (key === "style") {
          this.table.style.cssText = String(value);
        } else {
          this.table.setAttribute(key, String(value));
        }
      }
    }
    if (node.attrs.style) {
      this.table.style.cssText = node.attrs.style;
    }
    this.colgroup = this.table.appendChild(document.createElement("colgroup"));
    updateColumns(node, this.colgroup, this.table, cellMinWidth);
    this.contentDOM = this.table.appendChild(document.createElement("tbody"));
  }
  update(node) {
    if (node.type !== this.node.type) {
      return false;
    }
    this.node = node;
    updateColumns(node, this.colgroup, this.table, this.cellMinWidth);
    return true;
  }
  ignoreMutation(mutation) {
    const target = mutation.target;
    const isInsideWrapper = this.dom.contains(target);
    const isInsideContent = this.contentDOM.contains(target);
    if (isInsideWrapper && !isInsideContent) {
      if (mutation.type === "attributes" || mutation.type === "childList" || mutation.type === "characterData") {
        return true;
      }
    }
    return false;
  }
};

// src/table/utilities/createColGroup.ts
function createColGroup(node, cellMinWidth, overrideCol, overrideValue) {
  let totalWidth = 0;
  let fixedWidth = true;
  const cols = [];
  const row = node.firstChild;
  if (!row) {
    return {};
  }
  for (let i = 0, col = 0; i < row.childCount; i += 1) {
    const { colspan, colwidth } = row.child(i).attrs;
    for (let j = 0; j < colspan; j += 1, col += 1) {
      const hasWidth = overrideCol === col ? overrideValue : colwidth && colwidth[j];
      totalWidth += hasWidth || cellMinWidth;
      if (!hasWidth) {
        fixedWidth = false;
      }
      const [property, value] = getColStyleDeclaration(cellMinWidth, hasWidth);
      cols.push(["col", { style: `${property}: ${value}` }]);
    }
  }
  const tableWidth = fixedWidth ? `${totalWidth}px` : "";
  const tableMinWidth = fixedWidth ? "" : `${totalWidth}px`;
  const colgroup = ["colgroup", {}, ...cols];
  return { colgroup, tableWidth, tableMinWidth };
}

// src/table/utilities/createCell.ts
function createCell(cellType, cellContent) {
  if (cellContent) {
    return cellType.createChecked(null, cellContent);
  }
  return cellType.createAndFill();
}

// src/table/utilities/getTableNodeTypes.ts
function getTableNodeTypes(schema) {
  if (schema.cached.tableNodeTypes) {
    return schema.cached.tableNodeTypes;
  }
  const roles = {};
  Object.keys(schema.nodes).forEach((type) => {
    const nodeType = schema.nodes[type];
    if (nodeType.spec.tableRole) {
      roles[nodeType.spec.tableRole] = nodeType;
    }
  });
  schema.cached.tableNodeTypes = roles;
  return roles;
}

// src/table/utilities/createTable.ts
function createTable(schema, rowsCount, colsCount, withHeaderRow, cellContent) {
  const types = getTableNodeTypes(schema);
  const headerCells = [];
  const cells = [];
  for (let index = 0; index < colsCount; index += 1) {
    const cell = createCell(types.cell, cellContent);
    if (cell) {
      cells.push(cell);
    }
    if (withHeaderRow) {
      const headerCell = createCell(types.header_cell, cellContent);
      if (headerCell) {
        headerCells.push(headerCell);
      }
    }
  }
  const rows = [];
  for (let index = 0; index < rowsCount; index += 1) {
    rows.push(types.row.createChecked(null, withHeaderRow && index === 0 ? headerCells : cells));
  }
  return types.table.createChecked(null, rows);
}

// src/table/utilities/deleteTableWhenAllCellsSelected.ts
var import_core4 = require("@tiptap/core");

// src/table/utilities/isCellSelection.ts
var import_tables = require("@tiptap/pm/tables");
function isCellSelection(value) {
  return value instanceof import_tables.CellSelection;
}

// src/table/utilities/deleteTableWhenAllCellsSelected.ts
var deleteTableWhenAllCellsSelected = ({ editor }) => {
  const { selection } = editor.state;
  if (!isCellSelection(selection)) {
    return false;
  }
  let cellCount = 0;
  const table = (0, import_core4.findParentNodeClosestToPos)(selection.ranges[0].$from, (node) => {
    return node.type.name === "table";
  });
  table == null ? void 0 : table.node.descendants((node) => {
    if (node.type.name === "table") {
      return false;
    }
    if (["tableCell", "tableHeader"].includes(node.type.name)) {
      cellCount += 1;
    }
  });
  const allCellsSelected = cellCount === selection.ranges.length;
  if (!allCellsSelected) {
    return false;
  }
  editor.commands.deleteTable();
  return true;
};

// src/table/utilities/markdown.ts
var DEFAULT_CELL_LINE_SEPARATOR = "";
function escapeTableCellPipes(line) {
  let result = "";
  let i = 0;
  while (i < line.length) {
    if (line[i] === "\\" && i + 1 < line.length) {
      result += line[i] + line[i + 1];
      i += 2;
      continue;
    }
    if (line[i] !== "`") {
      result += line[i++];
      continue;
    }
    let runLen = 0;
    while (i + runLen < line.length && line[i + runLen] === "`") runLen += 1;
    let j = i + runLen;
    let found = false;
    while (j < line.length) {
      if (line[j] !== "`") {
        j += 1;
        continue;
      }
      let closeLen = 0;
      while (j + closeLen < line.length && line[j + closeLen] === "`") closeLen += 1;
      if (closeLen === runLen) {
        const spanContent = line.slice(i + runLen, j);
        result += line.slice(i, i + runLen) + spanContent.replace(/(?<!\\)\|/g, "\\|") + line.slice(j, j + runLen);
        i = j + runLen;
        found = true;
        break;
      }
      j += closeLen;
    }
    if (!found) {
      result += line.slice(i, i + runLen);
      i += runLen;
    }
  }
  return result;
}
function preprocessTablePipes(src) {
  return src.split("\n").map((line) => {
    if (!line.includes("|") || !line.includes("`")) return line;
    return escapeTableCellPipes(line);
  }).join("\n");
}
function collapseWhitespace(s) {
  return (s || "").replace(/\s+/g, " ").trim();
}
function renderTableToMarkdown(node, h, options = {}) {
  var _a;
  const cellSep = (_a = options.cellLineSeparator) != null ? _a : DEFAULT_CELL_LINE_SEPARATOR;
  if (!node || !node.content || node.content.length === 0) {
    return "";
  }
  const rows = [];
  node.content.forEach((rowNode) => {
    const cells = [];
    if (rowNode.content) {
      rowNode.content.forEach((cellNode) => {
        let raw = "";
        if (cellNode.content && Array.isArray(cellNode.content) && cellNode.content.length > 1) {
          const parts = cellNode.content.map(
            (child) => h.renderChildren(child)
          );
          raw = parts.join(cellSep);
        } else {
          raw = cellNode.content ? h.renderChildren(cellNode.content) : "";
        }
        const text = collapseWhitespace(
          raw.split(cellSep).join("\n").replace(/[ \t]*\r?\n[ \t]*/g, "<br>")
        );
        const isHeader = cellNode.type === "tableHeader";
        const align = normalizeTableCellAlignFromAttributes(cellNode.attrs);
        cells.push({ text, isHeader, align });
      });
    }
    rows.push(cells);
  });
  const columnCount = rows.reduce((max, r) => Math.max(max, r.length), 0);
  if (columnCount === 0) {
    return "";
  }
  const colWidths = Array.from({ length: columnCount }).fill(0);
  rows.forEach((r) => {
    var _a2;
    for (let i = 0; i < columnCount; i += 1) {
      const cell = ((_a2 = r[i]) == null ? void 0 : _a2.text) || "";
      const len = cell.length;
      if (len > colWidths[i]) {
        colWidths[i] = len;
      }
      if (colWidths[i] < 3) {
        colWidths[i] = 3;
      }
    }
  });
  const pad = (s, width) => s + " ".repeat(Math.max(0, width - s.length));
  const headerRow = rows[0];
  const hasHeader = headerRow.some((c) => c.isHeader);
  const colAlignments = Array.from({
    length: columnCount
  }).fill(null);
  rows.forEach((r) => {
    var _a2;
    for (let i = 0; i < columnCount; i += 1) {
      if (!colAlignments[i] && ((_a2 = r[i]) == null ? void 0 : _a2.align)) {
        colAlignments[i] = r[i].align;
      }
    }
  });
  let out = "\n";
  const headerTexts = Array.from({ length: columnCount }).map(
    (_, i) => hasHeader ? headerRow[i] && headerRow[i].text || "" : ""
  );
  out += `| ${headerTexts.map((t, i) => pad(t, colWidths[i])).join(" | ")} |
`;
  out += `| ${colWidths.map((w, index) => {
    const dashCount = Math.max(3, w);
    const alignment = colAlignments[index];
    if (alignment === "left" /* Left */) {
      return `:${"-".repeat(dashCount)}`;
    }
    if (alignment === "right" /* Right */) {
      return `${"-".repeat(dashCount)}:`;
    }
    if (alignment === "center" /* Center */) {
      return `:${"-".repeat(dashCount)}:`;
    }
    return "-".repeat(dashCount);
  }).join(" | ")} |
`;
  const body = hasHeader ? rows.slice(1) : rows;
  body.forEach((r) => {
    out += `| ${Array.from({ length: columnCount }).fill(0).map((_, i) => pad(r[i] && r[i].text || "", colWidths[i])).join(" | ")} |
`;
  });
  return out;
}
var markdown_default = renderTableToMarkdown;

// src/table/table.ts
var Table = import_core5.Node.create({
  name: "table",
  // @ts-ignore
  addOptions() {
    return {
      HTMLAttributes: {},
      resizable: false,
      renderWrapper: false,
      handleWidth: 5,
      cellMinWidth: 25,
      // TODO: fix
      View: TableView,
      lastColumnResizable: true,
      allowTableNodeSelection: false
    };
  },
  content: "tableRow+",
  tableRole: "table",
  isolating: true,
  group: "block",
  parseHTML() {
    return [{ tag: "table" }];
  },
  renderHTML({ node, HTMLAttributes }) {
    const { colgroup, tableWidth, tableMinWidth } = createColGroup(node, this.options.cellMinWidth);
    const userStyles = HTMLAttributes.style;
    function getTableStyle() {
      if (userStyles) {
        return userStyles;
      }
      return tableWidth ? `width: ${tableWidth}` : `min-width: ${tableMinWidth}`;
    }
    const table = [
      "table",
      (0, import_core5.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes, {
        style: getTableStyle()
      }),
      colgroup,
      ["tbody", 0]
    ];
    return this.options.renderWrapper ? ["div", { class: "tableWrapper" }, table] : table;
  },
  parseMarkdown: (token, h) => {
    const rows = [];
    const alignments = Array.isArray(token.align) ? token.align : [];
    if (token.header) {
      const headerCells = [];
      token.header.forEach((cell, index) => {
        var _a;
        const align = normalizeTableCellAlign((_a = alignments[index]) != null ? _a : cell.align);
        const attrs = align ? { align } : {};
        headerCells.push(
          h.createNode("tableHeader", attrs, [
            { type: "paragraph", content: h.parseInline(cell.tokens) }
          ])
        );
      });
      rows.push(h.createNode("tableRow", {}, headerCells));
    }
    if (token.rows) {
      token.rows.forEach((row) => {
        const bodyCells = [];
        row.forEach((cell, index) => {
          var _a;
          const align = normalizeTableCellAlign((_a = alignments[index]) != null ? _a : cell.align);
          const attrs = align ? { align } : {};
          bodyCells.push(
            h.createNode("tableCell", attrs, [
              { type: "paragraph", content: h.parseInline(cell.tokens) }
            ])
          );
        });
        rows.push(h.createNode("tableRow", {}, bodyCells));
      });
    }
    return h.createNode("table", void 0, rows);
  },
  renderMarkdown: (node, h) => {
    return markdown_default(node, h);
  },
  markdownTokenizer: {
    name: "table",
    level: "block",
    start: (src) => {
      const lines = src.split("\n");
      if (lines.length < 2) return -1;
      const sep = lines[1];
      if (!/^[ \t|:]*-[ \t|:-]*$/.test(sep) || !sep.includes("|")) return -1;
      return lines[0].includes("|") ? 0 : -1;
    },
    tokenize(src, _tokens, helper) {
      const blankLineIndex = src.indexOf("\n\n");
      const candidate = blankLineIndex >= 0 ? src.slice(0, blankLineIndex) : src;
      const candidateLines = candidate.split("\n");
      if (candidateLines.length < 2) return void 0;
      const sep = candidateLines[1];
      if (!/^[ \t|:]*-[ \t|:-]*$/.test(sep) || !sep.includes("|")) return void 0;
      const preprocessed = preprocessTablePipes(candidate);
      if (preprocessed === candidate) return void 0;
      const block = helper.blockTokens(preprocessed);
      const tableToken = block[0];
      if ((tableToken == null ? void 0 : tableToken.type) !== "table" || !tableToken.raw) return void 0;
      const lineCount = tableToken.raw.split("\n").length;
      const raw = src.split("\n").slice(0, lineCount).join("\n");
      return { ...tableToken, raw };
    }
  },
  addCommands() {
    return {
      insertTable: ({ rows = 3, cols = 3, withHeaderRow = true } = {}) => ({ tr, dispatch, editor }) => {
        const node = createTable(editor.schema, rows, cols, withHeaderRow);
        if (dispatch) {
          const offset = tr.selection.from + 1;
          tr.replaceSelectionWith(node).scrollIntoView().setSelection(import_state.TextSelection.near(tr.doc.resolve(offset)));
        }
        return true;
      },
      addColumnBefore: () => ({ state, dispatch }) => {
        return (0, import_tables2.addColumnBefore)(state, dispatch);
      },
      addColumnAfter: () => ({ state, dispatch }) => {
        return (0, import_tables2.addColumnAfter)(state, dispatch);
      },
      deleteColumn: () => ({ state, dispatch }) => {
        return (0, import_tables2.deleteColumn)(state, dispatch);
      },
      addRowBefore: () => ({ state, dispatch }) => {
        return (0, import_tables2.addRowBefore)(state, dispatch);
      },
      addRowAfter: () => ({ state, dispatch }) => {
        return (0, import_tables2.addRowAfter)(state, dispatch);
      },
      deleteRow: () => ({ state, dispatch }) => {
        return (0, import_tables2.deleteRow)(state, dispatch);
      },
      deleteTable: () => ({ state, dispatch }) => {
        return (0, import_tables2.deleteTable)(state, dispatch);
      },
      mergeCells: () => ({ state, dispatch }) => {
        return (0, import_tables2.mergeCells)(state, dispatch);
      },
      splitCell: () => ({ state, dispatch }) => {
        return (0, import_tables2.splitCell)(state, dispatch);
      },
      toggleHeaderColumn: () => ({ state, dispatch }) => {
        return (0, import_tables2.toggleHeader)("column")(state, dispatch);
      },
      toggleHeaderRow: () => ({ state, dispatch }) => {
        return (0, import_tables2.toggleHeader)("row")(state, dispatch);
      },
      toggleHeaderCell: () => ({ state, dispatch }) => {
        return (0, import_tables2.toggleHeaderCell)(state, dispatch);
      },
      mergeOrSplit: () => ({ state, dispatch }) => {
        if ((0, import_tables2.mergeCells)(state, dispatch)) {
          return true;
        }
        return (0, import_tables2.splitCell)(state, dispatch);
      },
      setCellAttribute: (name, value) => ({ state, dispatch }) => {
        return (0, import_tables2.setCellAttr)(name, value)(state, dispatch);
      },
      goToNextCell: () => ({ state, dispatch }) => {
        return (0, import_tables2.goToNextCell)(1)(state, dispatch);
      },
      goToPreviousCell: () => ({ state, dispatch }) => {
        return (0, import_tables2.goToNextCell)(-1)(state, dispatch);
      },
      fixTables: () => ({ state, dispatch }) => {
        if (dispatch) {
          (0, import_tables2.fixTables)(state);
        }
        return true;
      },
      setCellSelection: (position) => ({ tr, dispatch }) => {
        if (dispatch) {
          const selection = import_tables2.CellSelection.create(tr.doc, position.anchorCell, position.headCell);
          tr.setSelection(selection);
        }
        return true;
      }
    };
  },
  addKeyboardShortcuts() {
    return {
      Tab: () => {
        if (this.editor.commands.goToNextCell()) {
          return true;
        }
        if (!this.editor.can().addRowAfter()) {
          return false;
        }
        return this.editor.chain().addRowAfter().goToNextCell().run();
      },
      "Shift-Tab": () => this.editor.commands.goToPreviousCell(),
      Backspace: deleteTableWhenAllCellsSelected,
      "Mod-Backspace": deleteTableWhenAllCellsSelected,
      Delete: deleteTableWhenAllCellsSelected,
      "Mod-Delete": deleteTableWhenAllCellsSelected
    };
  },
  addProseMirrorPlugins() {
    const isResizable = this.options.resizable && this.editor.isEditable;
    return [
      ...isResizable ? [
        (0, import_tables2.columnResizing)({
          handleWidth: this.options.handleWidth,
          cellMinWidth: this.options.cellMinWidth,
          defaultCellMinWidth: this.options.cellMinWidth,
          View: this.options.View,
          lastColumnResizable: this.options.lastColumnResizable
        })
      ] : [],
      (0, import_tables2.tableEditing)({
        allowTableNodeSelection: this.options.allowTableNodeSelection
      })
    ];
  },
  addNodeView() {
    const isResizable = this.options.resizable && this.editor.isEditable;
    const View = this.options.View;
    if (isResizable || !View) {
      return null;
    }
    return ({ node, view, HTMLAttributes }) => {
      const mergedAttributes = (0, import_core5.mergeAttributes)(this.options.HTMLAttributes, HTMLAttributes);
      return new View(node, this.options.cellMinWidth, view, mergedAttributes);
    };
  },
  extendNodeSchema(extension) {
    const context = {
      name: extension.name,
      options: extension.options,
      storage: extension.storage
    };
    return {
      tableRole: (0, import_core5.callOrReturn)((0, import_core5.getExtensionField)(extension, "tableRole", context))
    };
  }
});

// src/kit/index.ts
var TableKit = import_core6.Extension.create({
  name: "tableKit",
  addExtensions() {
    const extensions = [];
    if (this.options.table !== false) {
      extensions.push(Table.configure(this.options.table));
    }
    if (this.options.tableCell !== false) {
      extensions.push(TableCell.configure(this.options.tableCell));
    }
    if (this.options.tableHeader !== false) {
      extensions.push(TableHeader.configure(this.options.tableHeader));
    }
    if (this.options.tableRow !== false) {
      extensions.push(TableRow.configure(this.options.tableRow));
    }
    return extensions;
  }
});
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  TableKit
});
//# sourceMappingURL=index.cjs.map
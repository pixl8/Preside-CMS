// src/link.ts
import { Mark, markPasteRule as markPasteRule2, mergeAttributes } from "@tiptap/core";
import { find as find2, registerCustomProtocol, reset } from "linkifyjs";

// src/helpers/autolink.ts
import {
  combineTransactionSteps,
  findChildrenInRange,
  getChangedRanges,
  getMarksBetween
} from "@tiptap/core";
import { Plugin, PluginKey } from "@tiptap/pm/state";
import { tokenize } from "linkifyjs";

// src/helpers/whitespace.ts
var UNICODE_WHITESPACE_PATTERN = "[\0- \xA0\u1680\u180E\u2000-\u2029\u205F\u3000]";
var UNICODE_WHITESPACE_REGEX = new RegExp(UNICODE_WHITESPACE_PATTERN);
var UNICODE_WHITESPACE_REGEX_END = new RegExp(`${UNICODE_WHITESPACE_PATTERN}$`);
var UNICODE_WHITESPACE_REGEX_GLOBAL = new RegExp(UNICODE_WHITESPACE_PATTERN, "g");

// src/helpers/autolink.ts
function isValidLinkStructure(tokens) {
  if (tokens.length === 1) {
    return tokens[0].isLink;
  }
  if (tokens.length === 3 && tokens[1].isLink) {
    return ["()", "[]"].includes(tokens[0].value + tokens[2].value);
  }
  return false;
}
function autolink(options) {
  return new Plugin({
    key: new PluginKey("autolink"),
    appendTransaction: (transactions, oldState, newState) => {
      const docChanges = transactions.some((transaction) => transaction.docChanged) && !oldState.doc.eq(newState.doc);
      const preventAutolink = transactions.some(
        (transaction) => transaction.getMeta("preventAutolink")
      );
      if (!docChanges || preventAutolink) {
        return;
      }
      const { tr } = newState;
      const transform = combineTransactionSteps(oldState.doc, [...transactions]);
      const changes = getChangedRanges(transform);
      changes.forEach(({ newRange }) => {
        const nodesInChangedRanges = findChildrenInRange(
          newState.doc,
          newRange,
          (node) => node.isTextblock
        );
        let textBlock;
        let textBeforeWhitespace;
        if (nodesInChangedRanges.length > 1) {
          textBlock = nodesInChangedRanges[0];
          textBeforeWhitespace = newState.doc.textBetween(
            textBlock.pos,
            textBlock.pos + textBlock.node.nodeSize,
            void 0,
            " "
          );
        } else if (nodesInChangedRanges.length) {
          const endText = newState.doc.textBetween(newRange.from, newRange.to, " ", " ");
          if (!UNICODE_WHITESPACE_REGEX_END.test(endText)) {
            return;
          }
          textBlock = nodesInChangedRanges[0];
          textBeforeWhitespace = newState.doc.textBetween(
            textBlock.pos,
            newRange.to,
            void 0,
            " "
          );
        }
        if (textBlock && textBeforeWhitespace) {
          const wordsBeforeWhitespace = textBeforeWhitespace.split(UNICODE_WHITESPACE_REGEX).filter(Boolean);
          if (wordsBeforeWhitespace.length <= 0) {
            return false;
          }
          const lastWordBeforeSpace = wordsBeforeWhitespace[wordsBeforeWhitespace.length - 1];
          const lastWordAndBlockOffset = textBlock.pos + textBeforeWhitespace.lastIndexOf(lastWordBeforeSpace);
          if (!lastWordBeforeSpace) {
            return false;
          }
          const linksBeforeSpace = tokenize(lastWordBeforeSpace).map(
            (t) => t.toObject(options.defaultProtocol)
          );
          if (!isValidLinkStructure(linksBeforeSpace)) {
            return false;
          }
          linksBeforeSpace.filter((link) => link.isLink).map((link) => ({
            ...link,
            from: lastWordAndBlockOffset + link.start + 1,
            to: lastWordAndBlockOffset + link.end + 1
          })).filter((link) => {
            if (!newState.schema.marks.code) {
              return true;
            }
            return !newState.doc.rangeHasMark(link.from, link.to, newState.schema.marks.code);
          }).filter((link) => options.validate(link.value)).filter((link) => options.shouldAutoLink(link.value)).forEach((link) => {
            if (getMarksBetween(link.from, link.to, newState.doc).some(
              (item) => item.mark.type === options.type
            )) {
              return;
            }
            tr.addMark(
              link.from,
              link.to,
              options.type.create({
                href: link.href
              })
            );
          });
        }
      });
      if (!tr.steps.length) {
        return;
      }
      return tr;
    }
  });
}

// src/helpers/clickHandler.ts
import { getAttributes } from "@tiptap/core";
import { Plugin as Plugin2, PluginKey as PluginKey2 } from "@tiptap/pm/state";
function clickHandler(options) {
  return new Plugin2({
    key: new PluginKey2("handleClickLink"),
    props: {
      handleClick: (view, pos, event) => {
        var _a, _b;
        if (event.button !== 0) {
          return false;
        }
        if (!view.editable) {
          return false;
        }
        let link = null;
        if (event.target instanceof HTMLAnchorElement) {
          link = event.target;
        } else {
          const target = event.target;
          if (!target) {
            return false;
          }
          const root = options.editor.view.dom;
          link = target.closest("a");
          if (link && !root.contains(link)) {
            link = null;
          }
        }
        if (!link) {
          return false;
        }
        let handled = false;
        if (options.enableClickSelection) {
          const commandResult = options.editor.commands.extendMarkRange(options.type.name);
          handled = commandResult;
        }
        if (options.openOnClick) {
          const attrs = getAttributes(view.state, options.type.name);
          const href = (_a = link.href) != null ? _a : attrs.href;
          const target = (_b = link.target) != null ? _b : attrs.target;
          if (href) {
            window.open(href, target);
            handled = true;
          }
        }
        return handled;
      }
    }
  });
}

// src/helpers/markdownLink.ts
import { InputRule, markInputRule, markPasteRule, PasteRule } from "@tiptap/core";
var MARKDOWN_LINK_INPUT_REGEX = /\[([^[\]]+)\]\(((?:[^\s()]|\([^\s()]*\))+)(?:\s+(?:(["'])(.*?)\3|“(.*?)”|‘(.*?)’))?\)$/;
var MARKDOWN_LINK_PASTE_REGEX = /\[([^[\]]+)\]\(((?:[^\s()]|\([^\s()]*\))+)(?:\s+(?:(["'])(.*?)\3|“(.*?)”|‘(.*?)’))?\)/g;
function isEscaped(text, index) {
  let backslashes = 0;
  for (let position = index - 1; position >= 0 && text[position] === "\\"; position -= 1) {
    backslashes += 1;
  }
  return backslashes % 2 === 1;
}
function isInsideCodeSpan(text, matchIndex) {
  let openRunLength = 0;
  let index = 0;
  while (index < matchIndex) {
    if (text[index] !== "`") {
      index += 1;
      continue;
    }
    if (openRunLength === 0 && isEscaped(text, index)) {
      index += 1;
      continue;
    }
    let runLength = 0;
    while (index < matchIndex && text[index] === "`") {
      runLength += 1;
      index += 1;
    }
    if (openRunLength === 0) {
      openRunLength = runLength;
    } else if (runLength === openRunLength) {
      openRunLength = 0;
    }
  }
  return openRunLength > 0;
}
function isConvertibleLink(text, match, isAllowedHref) {
  var _a, _b;
  const [, linkText, href] = match;
  const characterBefore = match.index ? text[match.index - 1] : void 0;
  if (characterBefore === "!" || isEscaped(text, (_a = match.index) != null ? _a : 0)) {
    return false;
  }
  if (isInsideCodeSpan(text, (_b = match.index) != null ? _b : 0)) {
    return false;
  }
  return !!linkText.trim() && isAllowedHref(href);
}
function toRuleMatch(match) {
  var _a, _b;
  const [linkSyntax, linkText, href, , straightQuotedTitle, curlyDoubleTitle, curlySingleTitle] = match;
  const title = (_a = straightQuotedTitle != null ? straightQuotedTitle : curlyDoubleTitle) != null ? _a : curlySingleTitle;
  return {
    index: (_b = match.index) != null ? _b : 0,
    text: linkSyntax,
    replaceWith: linkText,
    data: {
      href,
      // an empty title ("") counts as no title, as in CommonMark
      title: title || null,
      markdown: true
    }
  };
}
function matchesOverlap(a, b) {
  return a.index < b.index + b.text.length && b.index < a.index + a.text.length;
}
function getMarkdownLinkAttributes(match) {
  var _a, _b, _c;
  return {
    href: (_a = match.data) == null ? void 0 : _a.href,
    title: (_c = (_b = match.data) == null ? void 0 : _b.title) != null ? _c : null
  };
}
function markdownLinkInputRule(config) {
  const rule = markInputRule({
    find: (text) => {
      const match = MARKDOWN_LINK_INPUT_REGEX.exec(text);
      if (!match || !isConvertibleLink(text, match, config.isAllowedHref)) {
        return null;
      }
      return toRuleMatch(match);
    },
    type: config.type,
    getAttributes: getMarkdownLinkAttributes
  });
  return new InputRule({
    find: rule.find,
    handler: (props) => {
      const result = rule.handler(props);
      if (result !== null && props.state.tr.steps.length) {
        props.state.tr.setMeta("preventAutolink", true);
      }
      return result;
    }
  });
}
function markdownLinkPasteRule(config) {
  const rule = markPasteRule({
    find: (text) => {
      var _a, _b;
      const markdownMatches = [];
      for (const match of text.matchAll(MARKDOWN_LINK_PASTE_REGEX)) {
        if (isConvertibleLink(text, match, config.isAllowedHref)) {
          markdownMatches.push(toRuleMatch(match));
        }
      }
      const plainUrlMatches = ((_b = (_a = config.findPlainUrls) == null ? void 0 : _a.call(config, text)) != null ? _b : []).filter(
        (urlMatch) => !markdownMatches.some((markdownMatch) => matchesOverlap(markdownMatch, urlMatch))
      );
      return [...markdownMatches, ...plainUrlMatches];
    },
    type: config.type,
    getAttributes: getMarkdownLinkAttributes
  });
  return new PasteRule({
    find: rule.find,
    handler: (props) => {
      var _a;
      const result = rule.handler(props);
      if (result !== null && props.state.tr.steps.length && ((_a = props.match.data) == null ? void 0 : _a.markdown)) {
        props.state.tr.setMeta("preventAutolink", true);
      }
      return result;
    }
  });
}

// src/helpers/pasteHandler.ts
import { Plugin as Plugin3, PluginKey as PluginKey3 } from "@tiptap/pm/state";
import { find } from "linkifyjs";
function pasteHandler(options) {
  return new Plugin3({
    key: new PluginKey3("handlePasteLink"),
    props: {
      handlePaste: (view, _event, slice) => {
        const { shouldAutoLink } = options;
        const { state } = view;
        const { selection } = state;
        const { empty } = selection;
        if (empty) {
          return false;
        }
        let textContent = "";
        slice.content.forEach((node) => {
          textContent += node.textContent;
        });
        const link = find(textContent, { defaultProtocol: options.defaultProtocol }).find(
          (item) => item.isLink && item.value === textContent
        );
        if (!textContent || !link || shouldAutoLink !== void 0 && !shouldAutoLink(link.value)) {
          return false;
        }
        return options.editor.commands.setMark(options.type, {
          href: link.href
        });
      }
    }
  });
}

// src/link.ts
var pasteRegex = /https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z]{2,}\b(?:[-a-zA-Z0-9@:%._+~#=?!&/]*)(?:[-a-zA-Z0-9@:%._+~#=?!&/]*)/gi;
function isAllowedUri(uri, protocols) {
  const allowedProtocols = [
    "http",
    "https",
    "ftp",
    "ftps",
    "mailto",
    "tel",
    "callto",
    "sms",
    "cid",
    "xmpp"
  ];
  if (protocols) {
    protocols.forEach((protocol) => {
      const nextProtocol = typeof protocol === "string" ? protocol : protocol.scheme;
      if (nextProtocol) {
        allowedProtocols.push(nextProtocol);
      }
    });
  }
  return !uri || uri.replace(UNICODE_WHITESPACE_REGEX_GLOBAL, "").match(
    new RegExp(
      `^(?:(?:${allowedProtocols.map((protocol) => protocol.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")).join("|")}):|[^a-z]|[a-z0-9+.\\-]+(?:[^a-z+.\\-:]|$))`,
      "i"
    )
  );
}
var Link = Mark.create({
  name: "link",
  priority: 1e3,
  keepOnSplit: false,
  exitable: true,
  onCreate() {
    if (this.options.validate && !this.options.shouldAutoLink) {
      this.options.shouldAutoLink = this.options.validate;
      console.warn(
        "The `validate` option is deprecated. Rename to the `shouldAutoLink` option instead."
      );
    }
    this.options.protocols.forEach((protocol) => {
      if (typeof protocol === "string") {
        registerCustomProtocol(protocol);
        return;
      }
      registerCustomProtocol(protocol.scheme, protocol.optionalSlashes);
    });
  },
  onDestroy() {
    reset();
  },
  inclusive() {
    return this.options.autolink;
  },
  addOptions() {
    return {
      openOnClick: true,
      enableClickSelection: false,
      linkOnPaste: true,
      markdownLinks: false,
      // TODO (major) - default to true on next major version
      autolink: true,
      protocols: [],
      defaultProtocol: "http",
      HTMLAttributes: {
        target: "_blank",
        rel: "noopener noreferrer nofollow",
        class: null
      },
      isAllowedUri: (url, ctx) => !!isAllowedUri(url, ctx.protocols),
      validate: (url) => !!url,
      shouldAutoLink: (url) => {
        const hasProtocol = /^[a-z][a-z0-9+.-]*:\/\//i.test(url);
        const hasMaybeProtocol = /^[a-z][a-z0-9+.-]*:/i.test(url);
        if (hasProtocol || hasMaybeProtocol && !url.includes("@")) {
          return true;
        }
        const urlWithoutUserinfo = url.includes("@") ? url.split("@").pop() : url;
        const hostname = urlWithoutUserinfo.split(/[/?#:]/)[0];
        if (/^\d{1,3}(\.\d{1,3}){3}$/.test(hostname)) {
          return false;
        }
        if (!/\./.test(hostname)) {
          return false;
        }
        return true;
      }
    };
  },
  addAttributes() {
    var _a, _b, _c;
    return {
      href: {
        default: null,
        parseHTML(element) {
          return element.getAttribute("href");
        }
      },
      target: {
        // Coerce `undefined` to `null` because `undefined` is an invalid attribute value
        default: (_a = this.options.HTMLAttributes.target) != null ? _a : null
      },
      rel: {
        // Coerce `undefined` to `null` because `undefined` is an invalid attribute value
        default: (_b = this.options.HTMLAttributes.rel) != null ? _b : null
      },
      class: {
        // Coerce `undefined` to `null` because `undefined` is an invalid attribute value
        default: (_c = this.options.HTMLAttributes.class) != null ? _c : null
      },
      title: {
        default: null
      }
    };
  },
  parseHTML() {
    return [
      {
        tag: "a[href]",
        getAttrs: (dom) => {
          const href = dom.getAttribute("href");
          if (!href || !this.options.isAllowedUri(href, {
            defaultValidate: (url) => !!isAllowedUri(url, this.options.protocols),
            protocols: this.options.protocols,
            defaultProtocol: this.options.defaultProtocol
          })) {
            return false;
          }
          return null;
        }
      }
    ];
  },
  renderHTML({ HTMLAttributes }) {
    if (!this.options.isAllowedUri(HTMLAttributes.href, {
      defaultValidate: (href) => !!isAllowedUri(href, this.options.protocols),
      protocols: this.options.protocols,
      defaultProtocol: this.options.defaultProtocol
    })) {
      return ["a", mergeAttributes(this.options.HTMLAttributes, { ...HTMLAttributes, href: "" }), 0];
    }
    return ["a", mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
  markdownTokenName: "link",
  parseMarkdown: (token, helpers) => {
    return helpers.applyMark("link", helpers.parseInline(token.tokens || []), {
      href: token.href,
      title: token.title || null
    });
  },
  renderMarkdown: (node, h) => {
    var _a, _b, _c, _d;
    const href = (_b = (_a = node.attrs) == null ? void 0 : _a.href) != null ? _b : "";
    const title = (_d = (_c = node.attrs) == null ? void 0 : _c.title) != null ? _d : "";
    const text = h.renderChildren(node);
    return title ? `[${text}](${href} "${title}")` : `[${text}](${href})`;
  },
  addCommands() {
    return {
      setLink: (attributes) => ({ chain }) => {
        const { href } = attributes;
        if (!this.options.isAllowedUri(href, {
          defaultValidate: (url) => !!isAllowedUri(url, this.options.protocols),
          protocols: this.options.protocols,
          defaultProtocol: this.options.defaultProtocol
        })) {
          return false;
        }
        return chain().setMark(this.name, attributes).setMeta("preventAutolink", true).run();
      },
      toggleLink: (attributes) => ({ chain }) => {
        const { href } = attributes || {};
        if (href && !this.options.isAllowedUri(href, {
          defaultValidate: (url) => !!isAllowedUri(url, this.options.protocols),
          protocols: this.options.protocols,
          defaultProtocol: this.options.defaultProtocol
        })) {
          return false;
        }
        return chain().toggleMark(this.name, attributes, { extendEmptyMarkRange: true }).setMeta("preventAutolink", true).run();
      },
      unsetLink: () => ({ chain }) => {
        return chain().unsetMark(this.name, { extendEmptyMarkRange: true }).setMeta("preventAutolink", true).run();
      }
    };
  },
  addInputRules() {
    if (!this.options.markdownLinks) {
      return [];
    }
    return [
      markdownLinkInputRule({
        type: this.type,
        isAllowedHref: (href) => this.options.isAllowedUri(href, {
          defaultValidate: (url) => !!isAllowedUri(url, this.options.protocols),
          protocols: this.options.protocols,
          defaultProtocol: this.options.defaultProtocol
        })
      })
    ];
  },
  addPasteRules() {
    const findPlainUrls = (text) => {
      const foundLinks = [];
      if (text) {
        const { protocols, defaultProtocol } = this.options;
        const links = find2(text).filter(
          (item) => item.isLink && this.options.isAllowedUri(item.value, {
            defaultValidate: (href) => !!isAllowedUri(href, protocols),
            protocols,
            defaultProtocol
          })
        );
        links.forEach((link) => {
          if (!this.options.shouldAutoLink(link.value)) {
            return;
          }
          foundLinks.push({
            text: link.value,
            data: {
              href: link.href
            },
            index: link.start
          });
        });
      }
      return foundLinks;
    };
    if (this.options.markdownLinks) {
      return [
        markdownLinkPasteRule({
          type: this.type,
          isAllowedHref: (href) => this.options.isAllowedUri(href, {
            defaultValidate: (url) => !!isAllowedUri(url, this.options.protocols),
            protocols: this.options.protocols,
            defaultProtocol: this.options.defaultProtocol
          }),
          findPlainUrls
        })
      ];
    }
    return [
      markPasteRule2({
        find: findPlainUrls,
        type: this.type,
        getAttributes: (match) => {
          var _a;
          return {
            href: (_a = match.data) == null ? void 0 : _a.href
          };
        }
      })
    ];
  },
  addProseMirrorPlugins() {
    const plugins = [];
    const { protocols, defaultProtocol } = this.options;
    if (this.options.autolink) {
      plugins.push(
        autolink({
          type: this.type,
          defaultProtocol: this.options.defaultProtocol,
          validate: (url) => this.options.isAllowedUri(url, {
            defaultValidate: (href) => !!isAllowedUri(href, protocols),
            protocols,
            defaultProtocol
          }),
          shouldAutoLink: this.options.shouldAutoLink
        })
      );
    }
    plugins.push(
      clickHandler({
        type: this.type,
        editor: this.editor,
        openOnClick: this.options.openOnClick === "whenNotEditable" ? true : this.options.openOnClick,
        enableClickSelection: this.options.enableClickSelection
      })
    );
    if (this.options.linkOnPaste) {
      plugins.push(
        pasteHandler({
          editor: this.editor,
          defaultProtocol: this.options.defaultProtocol,
          type: this.type,
          shouldAutoLink: this.options.shouldAutoLink
        })
      );
    }
    return plugins;
  }
});

// src/index.ts
var index_default = Link;
export {
  Link,
  index_default as default,
  isAllowedUri,
  pasteRegex
};
//# sourceMappingURL=index.js.map
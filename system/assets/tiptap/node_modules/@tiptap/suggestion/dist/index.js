// src/suggestion.ts
import { Plugin, PluginKey } from "@tiptap/pm/state";

// src/findSuggestionMatch.ts
import { escapeForRegEx } from "@tiptap/core";
function findSuggestionMatch(config) {
  var _a;
  const {
    char,
    allowSpaces: allowSpacesOption,
    allowToIncludeChar,
    allowedPrefixes,
    startOfLine,
    $position
  } = config;
  const allowSpaces = allowSpacesOption && !allowToIncludeChar;
  const escapedChar = escapeForRegEx(char);
  const suffix = new RegExp(`\\s${escapedChar}$`);
  const prefix = startOfLine ? "^" : "";
  const finalEscapedChar = allowToIncludeChar ? "" : escapedChar;
  const regexp = allowSpaces ? new RegExp(`${prefix}${escapedChar}.*?(?=\\s${finalEscapedChar}|$)`, "gm") : new RegExp(`${prefix}(?:^)?${escapedChar}[^\\s${finalEscapedChar}]*`, "gm");
  const text = ((_a = $position.nodeBefore) == null ? void 0 : _a.isText) && $position.nodeBefore.text;
  if (!text) {
    return null;
  }
  const textFrom = $position.pos - text.length;
  const match = Array.from(text.matchAll(regexp)).pop();
  if (!match || match.input === void 0 || match.index === void 0) {
    return null;
  }
  const matchPrefix = match.input.slice(Math.max(0, match.index - 1), match.index);
  const matchPrefixIsAllowed = new RegExp(`^[${allowedPrefixes == null ? void 0 : allowedPrefixes.join("")}\0]?$`).test(matchPrefix);
  if (allowedPrefixes !== null && !matchPrefixIsAllowed) {
    return null;
  }
  const from = textFrom + match.index;
  let to = from + match[0].length;
  if (allowSpaces && suffix.test(text.slice(to - 1, to + 1))) {
    match[0] += " ";
    to += 1;
  }
  if (from < $position.pos && to >= $position.pos) {
    return {
      range: {
        from,
        to
      },
      query: match[0].slice(char.length),
      text: match[0]
    };
  }
  return null;
}

// src/helpers.ts
function hasInsertedWhitespace(transaction) {
  if (!transaction.docChanged) {
    return false;
  }
  return transaction.steps.some((step) => {
    const slice = step.slice;
    if (!(slice == null ? void 0 : slice.content)) {
      return false;
    }
    const inserted = slice.content.textBetween(0, slice.content.size, "\n");
    return /\s/.test(inserted);
  });
}
function getAnchorClientRect(editor) {
  return () => {
    const pos = editor.state.selection.$anchor.pos;
    const coords = editor.view.coordsAtPos(pos);
    const { top, right, bottom, left } = coords;
    try {
      return new DOMRect(left, top, right - left, bottom - top);
    } catch {
      return null;
    }
  };
}
function clientRectFor(editor, view, decorationNode, pluginKey) {
  if (!decorationNode) {
    return getAnchorClientRect(editor);
  }
  return () => {
    const state = pluginKey.getState(editor.state);
    const decorationId = state == null ? void 0 : state.decorationId;
    const currentDecorationNode = view.dom.querySelector(`[data-decoration-id="${decorationId}"]`);
    return (currentDecorationNode == null ? void 0 : currentDecorationNode.getBoundingClientRect()) || null;
  };
}
function shouldKeepDismissed({
  match,
  dismissedRange,
  state,
  transaction,
  editor,
  shouldResetDismissed,
  effectiveAllowSpaces
}) {
  if (shouldResetDismissed == null ? void 0 : shouldResetDismissed({
    editor,
    state,
    range: dismissedRange,
    match,
    transaction,
    allowSpaces: effectiveAllowSpaces
  })) {
    return false;
  }
  if (effectiveAllowSpaces) {
    return match.range.from === dismissedRange.from;
  }
  return match.range.from === dismissedRange.from && !hasInsertedWhitespace(transaction);
}
function dispatchExit({
  view,
  pluginKeyRef
}) {
  const tr = view.state.tr.setMeta(pluginKeyRef, { exit: true });
  view.dispatch(tr);
}

// src/plugin/props.ts
import { Decoration, DecorationSet } from "@tiptap/pm/view";
function createSuggestionProps({
  pluginKey,
  decorationTag,
  decorationClass,
  decorationContent,
  decorationEmptyClass,
  renderer,
  dispatchExit: dispatchExit2
}) {
  return {
    /**
     * Call the keydown hook if suggestion is active.
     */
    handleKeyDown(view, event) {
      var _a, _b;
      const state = pluginKey.getState(view.state);
      if (!state.active) {
        return false;
      }
      if (event.key === "Escape" || event.key === "Esc") {
        (_a = renderer == null ? void 0 : renderer.onKeyDown) == null ? void 0 : _a.call(renderer, { view, event, range: state.range });
        dispatchExit2(view);
        return true;
      }
      const handled = ((_b = renderer == null ? void 0 : renderer.onKeyDown) == null ? void 0 : _b.call(renderer, { view, event, range: state.range })) || false;
      return handled;
    },
    /**
     * Setup decorator on the currently active suggestion.
     */
    decorations(state) {
      const pluginState = pluginKey.getState(state);
      const { active, range, decorationId, query } = pluginState;
      if (!active) {
        return null;
      }
      const isEmpty = !(query == null ? void 0 : query.length);
      const classNames = [decorationClass];
      if (isEmpty) {
        classNames.push(decorationEmptyClass);
      }
      return DecorationSet.create(state.doc, [
        Decoration.inline(range.from, range.to, {
          nodeName: decorationTag,
          class: classNames.join(" "),
          "data-decoration-id": decorationId || void 0,
          "data-decoration-content": decorationContent
        })
      ]);
    }
  };
}

// src/plugin/state.ts
function createSuggestionState({
  editor,
  char,
  effectiveAllowSpaces,
  allowToIncludeChar,
  allowedPrefixes,
  startOfLine,
  findSuggestionMatch: findSuggestionMatch2,
  allow,
  shouldShow,
  shouldKeepDismissed: shouldKeepDismissed2,
  pluginKey
}) {
  return {
    /**
     * Initialize the plugin's internal state.
     */
    init() {
      return {
        active: false,
        range: { from: 0, to: 0 },
        query: null,
        text: null,
        composing: false,
        dismissedRange: null
      };
    },
    /**
     * Apply changes to the plugin state from a view transaction.
     */
    apply(transaction, prev, _oldState, state) {
      const { isEditable } = editor;
      const { composing } = editor.view;
      const { selection } = transaction;
      const { empty, from } = selection;
      const next = { ...prev };
      const meta = transaction.getMeta(pluginKey);
      if (meta && meta.exit) {
        next.active = false;
        next.decorationId = null;
        next.range = { from: 0, to: 0 };
        next.query = null;
        next.text = null;
        next.dismissedRange = prev.active ? { ...prev.range } : prev.dismissedRange;
        return next;
      }
      next.composing = composing;
      if (transaction.docChanged && next.dismissedRange !== null) {
        next.dismissedRange = {
          from: transaction.mapping.map(next.dismissedRange.from),
          to: transaction.mapping.map(next.dismissedRange.to)
        };
      }
      if (isEditable && (empty || editor.view.composing)) {
        if ((from < prev.range.from || from > prev.range.to) && !composing && !prev.composing) {
          next.active = false;
        }
        const match = findSuggestionMatch2({
          char,
          allowSpaces: effectiveAllowSpaces,
          allowToIncludeChar,
          allowedPrefixes,
          startOfLine,
          $position: selection.$from
        });
        const decorationId = `id_${Math.floor(Math.random() * 4294967295)}`;
        if (match && allow({
          editor,
          state,
          range: match.range,
          isActive: prev.active
        }) && (!shouldShow || shouldShow({
          editor,
          range: match.range,
          query: match.query,
          text: match.text,
          transaction
        }))) {
          if (next.dismissedRange !== null && !shouldKeepDismissed2({
            match,
            dismissedRange: next.dismissedRange,
            state,
            transaction
          })) {
            next.dismissedRange = null;
          }
          if (next.dismissedRange === null) {
            next.active = true;
            next.decorationId = prev.decorationId || decorationId;
            next.range = match.range;
            next.query = match.query;
            next.text = match.text;
          } else {
            next.active = false;
          }
        } else {
          if (!match) {
            next.dismissedRange = null;
          }
          next.active = false;
        }
      } else {
        next.active = false;
      }
      if (!next.active) {
        next.decorationId = null;
        next.range = { from: 0, to: 0 };
        next.query = null;
        next.text = null;
      }
      return next;
    }
  };
}

// src/plugin/async.ts
function createSuggestionAsyncRequestManager({
  editor,
  items
}) {
  let abortController = null;
  let debounceTimer = null;
  let debounceResolve = null;
  const clearDebounceTimer = () => {
    if (debounceTimer !== null) {
      clearTimeout(debounceTimer);
      debounceTimer = null;
    }
    debounceResolve == null ? void 0 : debounceResolve();
    debounceResolve = null;
  };
  const waitForDebounce = (delay) => {
    return new Promise((resolve) => {
      debounceResolve = resolve;
      debounceTimer = setTimeout(() => {
        debounceTimer = null;
        const pendingResolve = debounceResolve;
        debounceResolve = null;
        pendingResolve == null ? void 0 : pendingResolve();
      }, delay);
    });
  };
  const abort = () => {
    abortController == null ? void 0 : abortController.abort();
    clearDebounceTimer();
    abortController = null;
  };
  const fetch = async (query, debounce) => {
    abort();
    abortController = new AbortController();
    const controller = abortController;
    if (debounce > 0) {
      await waitForDebounce(debounce);
    }
    if (abortController !== controller || controller.signal.aborted) {
      return { status: "aborted" };
    }
    try {
      const result = await items({
        editor,
        query,
        signal: controller.signal
      });
      if (abortController !== controller || controller.signal.aborted) {
        return { status: "aborted" };
      }
      return { status: "resolved", items: result };
    } catch {
      if (abortController !== controller || controller.signal.aborted) {
        return { status: "aborted" };
      }
      return { status: "error" };
    }
  };
  return {
    abort,
    fetch
  };
}

// src/plugin/floating-ui.ts
import {
  autoUpdate,
  computePosition,
  flip as floatingUiFlip,
  offset as floatingUiOffset
} from "@floating-ui/dom";
function createSuggestionFloatingUiConfig({
  placement,
  offset,
  flip,
  floatingUi
}) {
  var _a, _b, _c, _d;
  const middleware = [
    floatingUiOffset({
      mainAxis: (_a = offset.mainAxis) != null ? _a : 4,
      crossAxis: (_b = offset.crossAxis) != null ? _b : 0
    })
  ];
  if (flip) {
    middleware.push(floatingUiFlip());
  }
  if ((_c = floatingUi == null ? void 0 : floatingUi.middleware) == null ? void 0 : _c.length) {
    middleware.push(...floatingUi.middleware);
  }
  return {
    placement,
    strategy: (_d = floatingUi == null ? void 0 : floatingUi.strategy) != null ? _d : "absolute",
    middleware
  };
}
function resolveContainer(container) {
  if (container instanceof HTMLElement) {
    return container;
  }
  if (typeof container === "string") {
    try {
      const found = document.querySelector(container);
      if (found) {
        return found;
      }
    } catch {
      return document.body;
    }
  }
  return document.body;
}
function createMount({
  getReferenceRect,
  contextElement,
  config,
  container,
  dismissOnOutsideClick,
  dismiss
}) {
  return (element, options = {}) => {
    const reference = {
      getBoundingClientRect: () => {
        var _a;
        return (_a = getReferenceRect()) != null ? _a : new DOMRect();
      },
      contextElement
    };
    let positioned = false;
    const mountedByUs = !element.isConnected;
    if (mountedByUs) {
      resolveContainer(container).appendChild(element);
    }
    if (!options.onPosition) {
      element.style.visibility = "hidden";
      element.style.width = "max-content";
    }
    const update = () => {
      computePosition(reference, element, {
        placement: config.placement,
        strategy: config.strategy,
        middleware: config.middleware
      }).then(({ x, y, placement, strategy }) => {
        if (options.onPosition) {
          options.onPosition({ x, y, placement, strategy });
          return;
        }
        Object.assign(element.style, {
          position: strategy,
          left: `${x}px`,
          top: `${y}px`
        });
        if (!positioned) {
          positioned = true;
          element.style.visibility = "";
        }
      });
    };
    const cleanupAutoUpdate = autoUpdate(reference, element, update, options.autoUpdate);
    let onOutsidePointerDown;
    if (dismissOnOutsideClick) {
      onOutsidePointerDown = (event) => {
        const target = event.target;
        if (!(target instanceof Node) || element.contains(target) || contextElement.contains(target)) {
          return;
        }
        dismiss();
      };
      document.addEventListener("pointerdown", onOutsidePointerDown, true);
    }
    return () => {
      cleanupAutoUpdate();
      if (onOutsidePointerDown) {
        document.removeEventListener("pointerdown", onOutsidePointerDown, true);
      }
      if (mountedByUs) {
        element.remove();
      }
    };
  };
}

// src/plugin/view.ts
function createSuggestionView({
  editor,
  pluginKey,
  items,
  renderer,
  minQueryLength,
  debounce,
  initialItems,
  placement,
  offset: offsetOption,
  container,
  flip,
  floatingUi,
  dismissOnOutsideClick,
  command,
  clientRectFor: clientRectFor2,
  dispatchExit: dispatchExit2
}) {
  let props;
  const asyncRequest = createSuggestionAsyncRequestManager({
    editor,
    items
  });
  const floatingUiConfig = createSuggestionFloatingUiConfig({
    placement,
    offset: offsetOption,
    flip,
    floatingUi
  });
  function dispatchStateUpdate(state, dispatchProps) {
    var _a, _b, _c;
    switch (state) {
      case "started":
        (_a = renderer == null ? void 0 : renderer.onStart) == null ? void 0 : _a.call(renderer, dispatchProps);
        break;
      case "updated":
        (_b = renderer == null ? void 0 : renderer.onUpdate) == null ? void 0 : _b.call(renderer, dispatchProps);
        break;
      case "stopped":
        (_c = renderer == null ? void 0 : renderer.onExit) == null ? void 0 : _c.call(renderer, dispatchProps);
        break;
      default:
        break;
    }
  }
  return {
    update: async (view, prevState) => {
      var _a, _b, _c, _d;
      const prev = pluginKey.getState(prevState);
      const next = pluginKey.getState(view.state);
      if (!prev || !next) {
        return;
      }
      let currentState = null;
      const queryChanged = prev.query !== next.query;
      const textChanged = prev.text !== next.text;
      const rangeChanged = prev.range.from !== next.range.from || prev.range.to !== next.range.to;
      const effectiveQueryChanged = queryChanged || textChanged || rangeChanged;
      if (!prev.active && next.active) {
        currentState = "started";
      } else if (prev.active && !next.active) {
        currentState = "stopped";
      } else if (next.active && effectiveQueryChanged) {
        currentState = "updated";
      } else {
        return;
      }
      const state = currentState === "stopped" ? prev : next;
      const decorationNode = view.dom.querySelector(`[data-decoration-id="${state.decorationId}"]`);
      const clientRect = clientRectFor2(view, decorationNode);
      const exceedsMinQueryLength = minQueryLength === 0 || (state.query ? state.query.length >= minQueryLength : false);
      const willFetch = (currentState === "started" || currentState === "updated") && exceedsMinQueryLength;
      props = {
        editor,
        range: state.range,
        query: state.query || "",
        text: state.text || "",
        items: initialItems != null ? initialItems : [],
        command: (commandProps) => {
          return command({
            editor,
            range: state.range,
            props: commandProps
          });
        },
        decorationNode,
        clientRect,
        loading: willFetch,
        placement,
        offset: { mainAxis: (_a = offsetOption.mainAxis) != null ? _a : 4, crossAxis: (_b = offsetOption.crossAxis) != null ? _b : 0 },
        container,
        flip,
        floatingUi: floatingUiConfig,
        mount: createMount({
          getReferenceRect: clientRect,
          contextElement: view.dom,
          config: floatingUiConfig,
          container,
          dismissOnOutsideClick,
          dismiss: () => dispatchExit2(editor.view)
        })
      };
      if (currentState === "started") {
        (_c = renderer == null ? void 0 : renderer.onBeforeStart) == null ? void 0 : _c.call(renderer, props);
      }
      if (currentState === "updated") {
        (_d = renderer == null ? void 0 : renderer.onBeforeUpdate) == null ? void 0 : _d.call(renderer, props);
      }
      if (currentState === "started") {
        dispatchStateUpdate(currentState, props);
      }
      if (currentState === "started" || currentState === "updated") {
        if (!willFetch) {
          asyncRequest.abort();
          props = { ...props, items: initialItems != null ? initialItems : [], loading: false };
        } else {
          props = { ...props, items: initialItems != null ? initialItems : [], loading: true };
          currentState = "updated";
          dispatchStateUpdate(currentState, props);
          const result = await asyncRequest.fetch(state.query || "", debounce);
          if (result.status === "aborted") {
            return;
          }
          const currentPluginState = pluginKey.getState(view.state);
          if (!(currentPluginState == null ? void 0 : currentPluginState.active)) {
            asyncRequest.abort();
            return;
          }
          props = result.status === "resolved" ? {
            ...props,
            items: result.items,
            loading: false
          } : {
            ...props,
            loading: false
          };
        }
      }
      if (currentState === "stopped") {
        asyncRequest.abort();
        dispatchStateUpdate(currentState, props);
        props = void 0;
        return;
      }
      if (currentState === "updated") {
        dispatchStateUpdate(currentState, props);
      }
    },
    destroy: () => {
      var _a;
      asyncRequest.abort();
      if (!props) {
        return;
      }
      (_a = renderer == null ? void 0 : renderer.onExit) == null ? void 0 : _a.call(renderer, props);
    }
  };
}

// src/suggestion.ts
var SuggestionPluginKey = new PluginKey("suggestion");
function Suggestion({
  pluginKey = SuggestionPluginKey,
  editor,
  char = "@",
  allowSpaces = false,
  allowToIncludeChar = false,
  allowedPrefixes = [" "],
  startOfLine = false,
  decorationTag = "span",
  decorationClass = "suggestion",
  decorationContent = "",
  decorationEmptyClass = "is-empty",
  command = () => null,
  items = () => [],
  minQueryLength = 0,
  debounce = 0,
  initialItems,
  placement = "bottom-start",
  offset: offsetOption = {},
  container,
  flip = true,
  floatingUi,
  dismissOnOutsideClick = true,
  render = () => ({}),
  allow = () => true,
  findSuggestionMatch: findSuggestionMatch2 = findSuggestionMatch,
  shouldShow,
  shouldResetDismissed
}) {
  const renderer = render == null ? void 0 : render();
  const effectiveAllowSpaces = allowSpaces && !allowToIncludeChar;
  const clientRectFor2 = (view, decorationNode) => clientRectFor(editor, view, decorationNode, pluginKey);
  function shouldKeepDismissed2(props) {
    return shouldKeepDismissed({
      ...props,
      editor,
      shouldResetDismissed,
      effectiveAllowSpaces
    });
  }
  const dispatchExit2 = (view) => dispatchExit({
    view,
    pluginKeyRef: pluginKey
  });
  return new Plugin({
    key: pluginKey,
    view: () => createSuggestionView({
      editor,
      pluginKey,
      items,
      renderer,
      minQueryLength,
      debounce,
      initialItems,
      placement,
      offset: offsetOption,
      container,
      flip,
      floatingUi,
      dismissOnOutsideClick,
      command,
      clientRectFor: clientRectFor2,
      dispatchExit: dispatchExit2
    }),
    state: createSuggestionState({
      editor,
      char,
      effectiveAllowSpaces,
      allowToIncludeChar,
      allowedPrefixes,
      startOfLine,
      findSuggestionMatch: findSuggestionMatch2,
      allow,
      shouldShow,
      shouldKeepDismissed: shouldKeepDismissed2,
      pluginKey
    }),
    props: createSuggestionProps({
      pluginKey,
      decorationTag,
      decorationClass,
      decorationContent,
      decorationEmptyClass,
      renderer,
      dispatchExit: dispatchExit2
    })
  });
}
function exitSuggestion(view, pluginKeyRef = SuggestionPluginKey) {
  const tr = view.state.tr.setMeta(pluginKeyRef, { exit: true });
  view.dispatch(tr);
}

// src/index.ts
var index_default = Suggestion;
export {
  Suggestion,
  SuggestionPluginKey,
  index_default as default,
  exitSuggestion,
  findSuggestionMatch
};
//# sourceMappingURL=index.js.map
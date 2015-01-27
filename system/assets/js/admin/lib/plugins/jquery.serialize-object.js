/**
 * jQuery serializeObject
 * @copyright 2014, macek <paulmacek@gmail.com>
 * @link https://github.com/macek/jquery-serialize-object
 * @license BSD
 * @version 2.2.0
 *
 * Slightly modified for use in Preside, May 2014. Using safe presideJQuery global namespace instead of jQuery + detecting CKEditor textareas
 */
(function(root, factory) {

  // AMD
  if (typeof define === "function" && define.amd) {
    define(["presideJQuery", "exports"], function($, exports) {
      factory(root, exports, $);
    });
  }

  // CommonJS
  else if (typeof exports !== "undefined") {
    var $ = require("presideJQuery");
    factory(root, exports, $);
  }

  // Browser
  else {
    root.FormSerializer = factory(root, {}, (root.presideJQuery || root.Zepto || root.ender || root.$));
  }

}(this, function(root, exports, $) {

  var FormSerializer = exports.FormSerializer = function FormSerializer(helper) {

    // private variables
    var data     = {},
        pushes   = {};

    // private API
    function build(base, key, value) {
      base[key] = value;
      return base;
    }

    function makeObject(root, value) {

      var keys = root.match(FormSerializer.patterns.key), k;

      // nest, nest, ..., nest
      while ((k = keys.pop()) !== undefined) {
        // foo[]
        if (FormSerializer.patterns.push.test(k)) {
          var idx = incrementPush(root.replace(/\[\]$/, ''));
          value = build([], idx, value);
        }

        // foo[n]
        else if (FormSerializer.patterns.fixed.test(k)) {
          value = build([], k, value);
        }

        // foo; foo[bar]
        else if (FormSerializer.patterns.named.test(k)) {
          value = build({}, k, value);
        }
      }

      return value;
    }

    function incrementPush(key) {
      if (pushes[key] === undefined) {
        pushes[key] = 0;
      }
      return pushes[key]++;
    }

    function addPair(pair) {
      if (!FormSerializer.patterns.validate.test(pair.name)) return this;
      var obj = makeObject(pair.name, pair.value);
      data = helper.extend(true, data, obj);
      return this;
    }

    function addPairs(pairs) {
      if (!helper.isArray(pairs)) {
        throw new Error("formSerializer.addPairs expects an Array");
      }
      for (var i=0, len=pairs.length; i<len; i++) {
        this.addPair(pairs[i]);
      }
      return this;
    }

    function addCKEditorFields( $form ){
      $form.find( 'textarea.ckeditor,textarea.richeditor' ).each( function(){
        var $editor = $(this)
          , name    = $editor.attr( 'name' );
        if ( name && CKEDITOR && CKEDITOR.instances && name in CKEDITOR.instances  ) {
          addPair( {
              name  : name
            , value : CKEDITOR.instances[ name ].getData()
          } );
        }
      } );
      return this;
    }

    function serialize() {
      return data;
    }

    function serializeJSON() {
      return JSON.stringify(serialize());
    }

    // public API
    this.addPair = addPair;
    this.addPairs = addPairs;
    this.serialize = serialize;
    this.serializeJSON = serializeJSON;
    this.addCKEditorFields = addCKEditorFields;
  };

  FormSerializer.patterns = {
    validate: /^[a-z][a-z0-9_]*(?:\[(?:\d*|[a-z0-9_]+)\])*$/i,
    key:      /[a-z0-9_]+|(?=\[\])/gi,
    push:     /^$/,
    fixed:    /^\d+$/,
    named:    /^[a-z0-9_]+$/i
  };

  FormSerializer.serializeObject = function serializeObject() {
    if (this.length > 1) {
      return new Error("jquery-serialize-object can only serialize one form at a time");
    }
    return new FormSerializer($).
      addPairs(this.serializeArray()).
      addCKEditorFields(this).
      serialize();
  };

  FormSerializer.serializeJSON = function serializeJSON() {
    if (this.length > 1) {
      return new Error("jquery-serialize-object can only serialize one form at a time");
    }
    return new FormSerializer($).
      addPairs(this.serializeArray()).
      addCKEditorFields(this).
      serializeJSON();
  };

  if (typeof $.fn !== "undefined") {
    $.fn.serializeObject = FormSerializer.serializeObject;
    $.fn.serializeJSON   = FormSerializer.serializeJSON;
  }

  return FormSerializer;
}));

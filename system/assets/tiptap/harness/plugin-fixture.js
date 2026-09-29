/**
 * A dummy dependent extension - "one of everything" against the plugin API.
 *
 * Stands in for what a real `preside-ext-tiptap-*` bundle does: it is loaded
 * AFTER facade.min.js (Sticker's `.dependsOn("tiptap-facade").after(...)`
 * ordering) and registers at its own PARSE time, before any editor is mounted.
 * Everything it observes is recorded on `window.__demo` so test-plugin-api.html
 * can assert on it.
 *
 * Deliberately touches the DOCUMENT only when a command is actually run - the
 * whole point of T29's byte-fidelity assertion is that a registered but idle
 * plugin changes getData() by nothing at all.
 */
( function() {
	"use strict";

	var T = window.PresideTiptap;

	// Everything the harness asserts on.
	var demo = window.__demo = {
		  ctxs         : { beforeExtensions: null, toolbarReady: null, instanceReady: null, beforeDestroy: null }
		, order        : []      // lifecycle events, in the order they fired
		, cleanupsAtDestroy: null // instance._cleanups length seen by beforeDestroy
		, chromeCalls  : 0
		, teardowns    : 0
		, runs         : 0
		, active       : false
		, extName      : "harnessDemoExtension"
	};

	// A one-off inline SVG, so the harness can tell a plugin icon from ours.
	var ICON = '<svg viewBox="0 0 24 24" width="16" height="16" data-demo-icon="1">'
		+ '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/></svg>';

	T.plugins.register( {
		  name: "harnessdemo"

		// The conventional opt-out: defaultConfigs.<name> === false. A field that
		// sets it must look EXACTLY as if this plugin had never registered.
		, enabled: function( cfg ) { return cfg.defaultConfigs.harnessdemo !== false; }

		// Called during construction, before the editor exists.
		, tiptapExtensions: function( ctx ) {
			demo.order.push( "tiptapExtensions" );
			demo.ctxs.tiptapExtensions = ctx;
			return [ T.Extension.create( { name: demo.extName } ) ];
		  }

		, commands: {
			HarnessDemo: {
				  label : "Demo"
				, icon  : ICON
				// Deliberately does NOT touch the document: the test asserts that the
				// seam is fidelity-neutral, and a command that edited would muddy it.
				// It does take the editor and the field cfg, which is the contract.
				, run   : function( editor, cfg ) {
					demo.runs++;
					demo.lastRunCfg = cfg || null;
					demo.active = !demo.active;
					return true;
				  }
				, active: function() { return demo.active; }
			}
		  }

		, slashItems: function( ctx ) {
			demo.slashCtx = ctx;
			return [
				  {
					  key     : "demoblock"
					, label   : "Demo block"
					, hint    : "Inserted by the harness plugin"
					, icon    : ICON
					, group   : "demo"
					, keywords: "demo fixture plugin"
					, run     : function( editor ) { editor.chain().focus().insertContent( "<p>demo</p>" ).run(); }
				  }
				// Its command does not exist anywhere, so the menu must DROP it rather
				// than offer an entry that would throw when picked.
				, { key: "demomissing", label: "Demo missing", cmd: "NoSuchCommandAtAll", group: "demo" }
			];
		  }

		, bubble: { HarnessDemo: function() { return true; } }

		// After mount, with the editor live. The returned teardown must run on
		// destroy() - a plugin's chrome must not outlive the editor.
		, chrome: function( ctx ) {
			demo.chromeCalls++;
			demo.ctxs.chrome = ctx;
			var marker = document.createElement( "span" );
			marker.className = "demo-plugin-marker";
			marker.setAttribute( "data-editor-live", ctx.editor && !ctx.editor.isDestroyed ? "1" : "0" );
			ctx.container.appendChild( marker );
			return function() { demo.teardowns++; marker.remove(); };
		  }

		, i18nDefaults: {
			  "toolbar.harnessdemo": "Harness demo"
			, "demo.hello"         : "Hello from the plugin"
		  }
	} );

	// The lifecycle bus. `beforeExtensions` can only be observed here (no instance
	// exists yet); the other three also fire on the facade instance's own
	// CKEditor-shaped bus, which the harness checks separately.
	[ "beforeExtensions", "toolbarReady", "instanceReady", "beforeDestroy" ].forEach( function( evt ) {
		T.plugins.on( evt, function( ctx ) {
			demo.order.push( evt );
			demo.ctxs[ evt ] = ctx;
			if ( evt === "beforeDestroy" ) {
				// Must be BEFORE _cleanups run, i.e. they are all still registered.
				demo.cleanupsAtDestroy = ctx && ctx.instance && ctx.instance._cleanups
					? ctx.instance._cleanups.length : -1;
				demo.editorAliveAtDestroy = !!( ctx && ctx.editor && !ctx.editor.isDestroyed );
			}
		} );
	} );
} )();

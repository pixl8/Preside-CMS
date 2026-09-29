/**
 * Preside server-side dependency mocks, shared by both editor harness pages.
 * Must load AFTER jQuery (needs window.presideJQuery) and BEFORE the editor scripts.
 */
( function() {
	// Preside uses a dedicated jQuery handle.
	window.presideJQuery = window.presideJQuery || window.jQuery;

	// cfrequest - normally populated by ckEditorJs.cfm's includeData.
	window.cfrequest = Object.assign( {
		  ajaxEndpoint            : "/mock/ajax"
		, adminBaseUrl            : "/mock/admin/"
		, siteId                  : ""
		, ckeditorConfig          : "/ckeditorExtensions/config.js"
		, ckeditorDefaultToolbar  : ""
		, ckeditorDefaultWidth    : "auto"
		, ckeditorDefaultMinHeight: 150
		, ckeditorDefaultMaxHeight: 420
		, ckeditorAutoParagraph   : true
		// This CKEditor build ONLY ships the "bootstrapck" skin (no moono-lisa),
		// so we must set it or the skin CSS 404s. removePlugins mirrors Preside's
		// default (iframe,wsc,scayt need network / aren't wanted).
		, ckeditorDefaultConfigs  : {
			  skin                 : "bootstrapck"
			, removePlugins        : "iframe,wsc,scayt"
			, autoGrow_onStartup   : true
			, pasteFromWordDisallow: [ "span", "*(*)", "*{*}" ]
			, format_tags          : "p;h1;h2;h3;h4;h5;h6;pre;div"
		  }
		, widgetCategories        : ""
		, linkPickerCategory      : ""
		// tiptapWidgets - the "/" menu's by-name widget list, emitted server-side by
		// ckEditorJs.cfm from widgetsService.getWidgets(). Mirrors that shape: already
		// translated + site-template-filtered, carrying `categories` so the client can
		// filter per field. "gallery" here is deliberately in a non-default category,
		// to exercise that filtering.
		, tiptapWidgets           : [
			  { id: "featurednews", title: "Featured news", description: "A list of recent news articles", categories: [] }
			, { id: "calltoaction", title: "Call to action", description: "A prominent button with a heading", categories: [ "default" ] }
			, { id: "gallery"     , title: "Image gallery" , description: "A grid of images from a folder" , categories: [ "richcontent" ] }
		  ]
	}, window.cfrequest || {} );

	// URL builders (reimplemented to point at the mock server; the produced shape
	// matches Preside's preside.url.builder.js closely enough for the plugins).
	function qs( options ) {
		var parts = [];
		for ( var k in ( options || {} ) ) {
			if ( options[ k ] === undefined || options[ k ] === null ) { continue; }
			parts.push( encodeURIComponent( k ) + "=" + encodeURIComponent( options[ k ] ) );
		}
		return parts.length ? "?" + parts.join( "&" ) : "";
	}
	window.buildAjaxLink = function( action, options ) {
		return cfrequest.ajaxEndpoint + "?action=" + encodeURIComponent( action ) +
			( qs( options ).replace( /^\?/, "&" ) );
	};
	window.buildAdminLink = function( handler, action, options ) {
		// handler may be dotted ("ajaxhelper.temporarilyStoreData") or handler+action.
		var seg = String( handler ).replace( /\./g, "/" );
		if ( action ) { seg += "/" + action; }
		return cfrequest.adminBaseUrl + seg + "/" + qs( options );
	};
	window.buildLink = function( handler, action, options ) {
		return window.buildAdminLink( handler, action, options );
	};

	// i18n - plugins call i18n.translateResource for placeholder / widget labels.
	window.i18n = window.i18n || {
		translateResource: function( key, opts ) {
			if ( opts && typeof opts === "object" && opts.defaultValue ) { return opts.defaultValue; }
			return String( key ).split( ":" ).pop();
		}
	};
} )();

/**
 * @fileOverview The "widgets" plugin.
 *
 */

'use strict';

( function( $ ) {
	var widgetsReplaceRegex = /{{widget:([a-z\$_][a-z0-9\$_]*):(.*?):widget}}/gi;

	CKEDITOR.plugins.add( 'widgets', {
		requires: 'iframedialog',
		lang: 'en',
		icons: 'widgets',

		onLoad: function() {
			CKEDITOR.addCss( '.widget-placeholder{background:#eee url(' + this.path + 'icons/widgets.png) 6px 9px no-repeat;padding:6px 10px 6px 26px;border:1px solid #ccc;border-radius:5px;display:inline-block;margin:2px;}' );
			CKEDITOR.addCss( '.widget-placeholder .config-summary { color:#888; font-style:italic; }' );
		},

		init: function( editor ) {
			var lang = editor.lang.widgets;

			CKEDITOR.dialog.add( 'widgets', this.path + 'dialogs/widgets.js' );

			editor.ui.addButton && editor.ui.addButton( 'Widgets', {
				label: lang.toolbar,
				command: 'widgets',
				toolbar: 'insert,5',
				icon: 'widgets'
			} );

			editor.widgets.add( 'widgets', {
				  dialog   : 'widgets'
				, pathName : 'widgets'
				, template : '<div class="widget-placeholder">&nbsp;</div>'
				, init: function() {
					this.setData( 'raw', this.element.getAttribute( 'data-raw' ) );
				  }
				, downcast: function() {return new CKEDITOR.htmlParser.text( this.data.raw ); }
				, data : function(){
					var widget = this;

					if ( widget.data.raw !== null && ( !widget._previousRaw || widget._previousRaw !== widget.data.raw ) ) {
						widget._previousRaw    = widget.data.raw;

						widget.data.widgetId   = widget.data.raw.replace( widgetsReplaceRegex, "$1");
						widget.data.configJson = widget.data.raw.replace( widgetsReplaceRegex, "$2");

						widget.element.setText( i18n.translateResource( "widgets." + widget.data.widgetId + ":title", { defaultValue : widget.data.widgetId } ) );
						widget.element.addClass( "loading" );
						widget.element.setAttribute( "data-raw", widget.data.raw );

						$.ajax({
							  url     : buildAjaxLink( "widgets.renderWidgetPlaceholder" )
							, method  : "POST"
							, data    : { widgetId: widget.data.widgetId, data : widget.data.configJson }
							, success : function( data ) {
								widget.element.removeClass( "loading" );
								widget.element.setHtml( data );
							  }
							, error : function(){
								widget.element.removeClass( "loading" );
								widget.element.addClass( "error" );
							}
						});
					}
				}
			} );

			editor.setKeystroke( CKEDITOR.ALT + 87 /* W */, 'widgets' );
		},

		afterInit: function( editor ) {
			editor.dataProcessor.dataFilter.addRules( {
				text: function( text ) {
					return text.replace( widgetsReplaceRegex, function( match ) {
						var widgetWrapper = null
						  , innerElement  = new CKEDITOR.htmlParser.element( 'div', {
								  'class'    : 'widget-placeholder'
								, 'data-raw' : match
							} );

						widgetWrapper = editor.widgets.wrapElement( innerElement, 'widgets' );

						return widgetWrapper.getOuterHtml();
					} );
				}
			} );
		}
	} );

} )( presideJQuery );
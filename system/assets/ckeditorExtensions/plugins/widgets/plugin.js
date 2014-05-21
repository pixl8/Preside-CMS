/**
 * @fileOverview The "widgets" plugin.
 *
 */

'use strict';

( function() {
	var widgetsReplaceRegex = /{{widget:([a-z\$_][a-z0-9\$_]*):(.*?):widget}}/gi;

	CKEDITOR.plugins.add( 'widgets', {
		requires: 'iframedialog',
		lang: 'en',
		icons: 'widgets',

		onLoad: function() {
			CKEDITOR.addCss( '.widget-placeholder{background:#eee url(' + this.path + 'icons/widgets.png) 6px center no-repeat;padding:6px 10px 6px 26px;border:1px solid #ccc;border-radius:5px;display:inline-block;margin:2px;}' );
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
					if ( this.data.raw !== null && ( !this._previousRaw || this._previousRaw !== this.data.raw ) ) {
						this._previousRaw    = this.data.raw;

						this.data.widgetId       = this.data.raw.replace( widgetsReplaceRegex, "$1");
						this.data.configJson = this.data.raw.replace( widgetsReplaceRegex, "$2");

						this.element.setText( i18n.translateResource( "widgets." + this.data.widgetId + ":title", { defaultValue : this.data.widgetId } ) );
						this.element.setAttribute( "data-raw", this.data.raw );
					}
				}
			} );

			editor.setKeystroke( CKEDITOR.ALT + 65 /* A */, 'widgets' );
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

} )();
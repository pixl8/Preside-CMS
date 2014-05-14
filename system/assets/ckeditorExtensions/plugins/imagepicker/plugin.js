/**
 * @fileOverview The "imagepicker" plugin.
 *
 */

'use strict';

( function( $ ) {
	var imageReplaceRegex = /{{image:(.*?):image}}/gi;

	CKEDITOR.plugins.add( 'imagepicker', {
		requires: 'iframedialog',
		lang: 'en',
		icons: 'imagepicker',

		init: function( editor ) {
			var lang = editor.lang.imagepicker;

			CKEDITOR.dialog.add( 'imagepicker', this.path + 'dialogs/imagepicker.js' );

			editor.ui.addButton && editor.ui.addButton( 'imagepicker', {
				label: lang.toolbar,
				command: 'imagepicker',
				toolbar: 'insert,6',
				icon: 'imagepicker'
			} );

			editor.widgets.add( 'imagepicker', {
				  dialog   : 'imagepicker'
				, pathName : 'imagepicker'
				, template : '<span class="img-placeholder"></span>'
				, init: function() {
					this.setData( 'raw', this.element.getAttribute( 'data-raw' ) );
				  }
				, downcast : function() { return new CKEDITOR.htmlParser.text( this.data.raw ); }
				, upcast   : function( el ){ return el.name == 'span' && el.hasClass( 'asset-placeholder' ); }
				, data     : function(){
					var imgWidget = this;

					if ( this.data.raw !== null && ( !this._previousRaw || this._previousRaw !== this.data.raw ) ) {
						this._previousRaw = this.data.raw;
						this.data.configJson = this.data.raw.replace( imageReplaceRegex, "$1");
						this.element.setAttribute( "data-raw", this.data.raw );

						$.ajax({
							  url     : buildAjaxLink( "assetManager.renderEmbeddedImageForEditor" )
							, method  : "POST"
							, data    : { embeddedImage : this.data.raw }
							, success : function( data ) {
								imgWidget.element.setHtml( data );
							  }
							, error : function(){
								imgWidget.element.setText( "ERROR LOADING IMAGE" );
							}
						});
					}
				}
			} );

			editor.setKeystroke( CKEDITOR.ALT + 65 /* A */, 'imagepicker' );
		},

		afterInit: function( editor ) {
			editor.dataProcessor.dataFilter.addRules( {
				text: function( text ) {
					return text.replace( imageReplaceRegex, function( match ) {
						var imageWrapper = null
						  , innerElement  = new CKEDITOR.htmlParser.element( 'span', {
								  'class'    : 'img-placeholder'
								, 'data-raw' : match
							} );

						imageWrapper = editor.widgets.wrapElement( innerElement, 'imagepicker' );

						return imageWrapper.getOuterHtml();
					} );
				}
			} );
		}
	} );

} )( presideJQuery );
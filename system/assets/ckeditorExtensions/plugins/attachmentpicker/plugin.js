/**
 * @fileOverview The "attachmentpicker" plugin.
 *
 */

'use strict';

( function( $ ) {
	var attachmentReplaceRegex = /{{attachment:(.*?):attachment}}/gi
	  , addEmbeddedAttachmentStylesToWidgetWrapper;

	CKEDITOR.plugins.add( 'attachmentpicker', {
		requires: 'iframedialog',
		lang: 'en',
		icons: 'attachmentpicker',

		onLoad: function() {
			CKEDITOR.addCss( '.attachment-placeholder{ display : inline-block; } .attachment-placeholder.error{ padding: 2px; color : red; } .attachment-placeholder.loading { padding: 2px; color: #999; }' );
		},

		init: function( editor ) {
			var lang = editor.lang.attachmentpicker;

			CKEDITOR.dialog.add( 'attachmentpicker', this.path + 'dialogs/attachmentpicker.js' );

			editor.ui.addButton && editor.ui.addButton( 'AttachmentPicker', {
				label: lang.toolbar,
				command: 'attachmentpicker',
				toolbar: 'insert,6',
				icon: 'attachmentpicker'
			} );


			editor.widgets.add( 'attachmentpicker', {
				  dialog   : 'attachmentpicker'
				, pathName : 'attachmentpicker'
				, template : '<div class="attachment-placeholder"></div>'
				, allowedContent: '*[*]{*}(*)'
				, init: function() {
					this.setData( 'raw', this.element.getAttribute( 'data-raw' ) );
				  }
				, downcast : function() { return new CKEDITOR.htmlParser.text( this.data.raw ); }
				, upcast   : function( el ){ return el.name == 'div' && el.hasClass( 'asset-placeholder' ); }
				, data     : function(){
					var attachmentWidget = this;

					if ( this.data.raw !== null && ( !this._previousRaw || this._previousRaw !== this.data.raw ) ) {
						this._previousRaw = this.data.raw;
						this.data.configJson = this.data.raw.replace( attachmentReplaceRegex, "$1");
						this.element.setAttribute( "data-raw", this.data.raw );
						this.element.setText( i18n.translateResource( "cms:ckeditor.attachmentpicker.attachment.loading" ) );
						this.element.addClass( "loading" );

						$.ajax({
							  url     : buildAjaxLink( "assetManager.renderEmbeddedAttachmentForEditor" )
							, method  : "POST"
							, data    : { embeddedAttachment : this.data.raw }
							, success : function( data ) {
								attachmentWidget.element.removeClass( "loading" );
								attachmentWidget.element.setHtml( data );

								addEmbeddedAttachmentStylesToWidgetWrapper( attachmentWidget );
							  }
							, error : function(){
								attachmentWidget.element.removeClass( "loading" );
								attachmentWidget.element.addClass( "error" );
								attachmentWidget.element.setText( i18n.translateResource( "cms:ckeditor.attachmentpicker.attachment.loading.error" ) );
							}
						});
					}
				}
			} );

			editor.setKeystroke( CKEDITOR.ALT + 65 /* A */, 'attachmentpicker' );
		},

		afterInit: function( editor ) {
			editor.dataProcessor.dataFilter.addRules( {
				text: function( text ) {
					return text.replace( attachmentReplaceRegex, function( match ) {
						var attachmentWrapper = null
						  , innerElement  = new CKEDITOR.htmlParser.element( 'div', {
								  'class'    : 'attachment-placeholder'
								, 'data-raw' : match
							} );

						attachmentWrapper = editor.widgets.wrapElement( innerElement, 'attachmentpicker' );

						return attachmentWrapper.getOuterHtml();
					} );
				}
			} );
		}
	} );

	addEmbeddedAttachmentStylesToWidgetWrapper = function( widget ){
		var $firstchild = $( widget.element.$ ).children().first()
		  , wrapper = widget.wrapper
		  , styles, classes, i;

		if ( $firstchild.length ) {
			if ( $firstchild.attr( "style" ) ) {
				styles = $firstchild.attr( "style" ).split( ";" );
				for( i=0; i < styles.length; i++ ){
					styles[i] = styles[i].split( ":");
					if ( styles[i].length === 2 ) {
						wrapper.setStyle( styles[i][0], styles[i][1] );
					}
				}
			}

			if ( $firstchild.attr( "class" ) && $firstchild.attr( "class" ).length ) {
				classes = $firstchild.attr( "class" ).split( /\s+/ );
				for( i=0; i < classes.length; i++ ){
					wrapper.addClass( classes[i] );
				}
			}
		}
	};

} )( presideJQuery );
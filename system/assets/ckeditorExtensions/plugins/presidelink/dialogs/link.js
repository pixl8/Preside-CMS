/**
 * @license Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

'use strict';

( function( $ ) {
	CKEDITOR.dialog.add( 'link', function( editor ) {
		var plugin     = CKEDITOR.plugins.presidelink
		  , commonLang = editor.lang.common
		  , linkLang   = editor.lang.presidelink
		  , dialog, initializeIframe, setupIFrameListeners;

		initializeIframe = function() {
			var selection = editor.getSelection()
			  , element = null
			  , data;

			// Fill in all the relevant fields if there's already one link selected.
			if ( ( element = plugin.getSelectedLink( editor ) ) && element.hasAttribute( 'href' ) ) {
				// Don't change selection if some element is already selected.
				// For example - don't destroy fake selection.
				if ( !selection.getSelectedElement() ) {
					selection.selectElement( element );
				}
			} else {
				element = null;
			}

			data = plugin.parseLinkAttributes( editor, element );

			// Record down the selected element in the dialog.
			dialog._.selectedElement = element;

			// little trick to send long / complex data to the server
			// ready for the subsequent iFrame request
			// uses ColdBox FlashRAM to store the data which is then picked
			// up by next request
			$.ajax({
				  url    : buildAdminLink( "ajaxhelper.temporarilyStoreData" )
				, method : "POST"
				, data   : data
				, success: function(){
					dialog.getContentElement('iframe').getElement().$.src = buildAdminLink( "linkpicker", "index" );
				 }
			});
		};

		setupIFrameListeners = function() {
			var element     = this.getElement()
			  , childWindow = element.$.contentWindow
			  , notifyEvent = function( e ) {
					editor.fire( 'saveSnapshot' );
					setTimeout( function() { editor.fire( 'saveSnapshot' ); }, 0 );

					if ( childWindow.onDialogEvent.call( this, e, dialog ) === false ){
						e.data.hide = false;
					}
				};

			if ( childWindow.onDialogEvent ) {
				dialog.on( 'ok'    , notifyEvent );
				dialog.on( 'cancel', notifyEvent );
				dialog.on( 'resize', notifyEvent );
				dialog.on( 'hide', function( e ) {
					dialog.removeListener( 'ok'    , notifyEvent );
					dialog.removeListener( 'cancel', notifyEvent );
					dialog.removeListener( 'resize', notifyEvent );

					e.removeListener();
				} );

				childWindow.onDialogEvent.call( this, {
					name: 'load',
					sender: this,
					editor: dialog._.editor
				}, dialog );
			}
		};


		return {
			title: linkLang.title,
			minWidth: 900,
			minHeight: 350,
			onShow: function(){
				dialog = this;
				initializeIframe();
			},
			onOk: function() {
				// TODO!
			},
			contents: [
				{
					id: 'iframe',
					label: linkLang.title,
					title: linkLang.title,
					elements: [{
						type          : 'iframe',
						src           : "",
						width         : '900px',
						height        : '350px',
						onContentLoad : setupIFrameListeners
					} ]
				}
			]
		};
	} );
} )( presideJQuery );
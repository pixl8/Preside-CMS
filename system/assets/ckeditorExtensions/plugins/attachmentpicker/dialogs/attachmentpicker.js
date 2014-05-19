/**
 * @fileOverview Definition for attachmentpicker plugin dialog.
 *
 */

'use strict';

( function( $ ) {
	CKEDITOR.dialog.add( 'attachmentpicker', function( editor ) {
		var lang = editor.lang.attachmentpicker
		  , associatedWidget;

		return {
			title: lang.title,
			minWidth: 900,
			minHeight: 500,
			onShow:function(){
				this.disableButton( "ok" );
			},
			contents: [
				{
					id: 'iframe',
					label: lang.title,
					title: lang.title,
					elements: [{
						type   : 'iframe',
						src    : "",
						width  : '900px',
						height : '500px',
						setup  : function( widget ) {
							var params = {}
							  , dlg    = this;

							associatedWidget = widget;
							if ( widget.data.configJson ) {
								params.configJson = widget.data.configJson;
								// little trick to send long / complex data to the server
								// ready for the subsequent iFrame request
								// uses ColdBox FlashRAM to store the data which is then picked
								// up by next request
								$.ajax({
									  url    : buildAdminLink( "ajaxhelper.temporarilyStoreData" )
									, method : "POST"
									, data   : params
									, success: function(){
										dlg.getElement().$.src = buildAdminLink( "assetmanager", "pickerForEditorDialog", { type:"attachment" } );
									 }
								});
							} else {
								dlg.getElement().$.src = buildAdminLink( "assetmanager", "pickerForEditorDialog", { type:"attachment" } );
							}
						},
						commit : function() {
							if ( associatedWidget && this._config ) {
								associatedWidget.setData( 'raw', this._config );
							}
						},
						onContentLoad : function() {
							var element     = this.getElement()
							  , childWindow = element.$.contentWindow
							  , dialog      = this.getDialog()
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
						}
					} ]
				}
			]
		};
	} );
} )( presideJQuery );
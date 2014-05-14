/**
 * @fileOverview Definition for imagepicker plugin dialog.
 *
 */

'use strict';

CKEDITOR.dialog.add( 'imagepicker', function( editor ) {
	var lang = editor.lang.imagepicker
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
					src    : buildAdminLink( "assetmanager", "imagePickerForEditorDialog" ),
					width  : '900px',
					height : '500px',
					setup  : function( widget ) {
						var params = {};

						associatedWidget = widget;
						if ( widget.data.configJson ) {
							params.configJson = widget.data.configJson;
						}

						this.getElement().$.src = buildAdminLink( "assetmanager", "imagePickerForEditorDialog", params );
					},
					commit : function() {
						if ( associatedWidget && this._imgConfig ) {
							associatedWidget.setData( 'raw', this._imgConfig );
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
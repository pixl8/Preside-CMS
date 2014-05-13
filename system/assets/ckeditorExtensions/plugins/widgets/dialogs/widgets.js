/**
 * @fileOverview Definition for widgets plugin dialog.
 *
 */

'use strict';

CKEDITOR.dialog.add( 'widgets', function( editor ) {
	var lang = editor.lang.widgets
	  , associatedWidget;

	return {
		title: lang.title,
		minWidth: 800,
		minHeight: 400,
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
					src    : buildAdminLink( "widgets", "dialog" ),
					width  : '800px',
					height : '400px',
					setup  : function( widget ) {
						var params = {};

						associatedWidget = widget;

						if ( widget.data.widgetId ) {
							params.widget = widget.data.widgetId;

							if ( widget.data.configJson ) {
								params.configJson = widget.data.configJson;
							}
						}

						this.getElement().$.src = buildAdminLink( "widgets", "dialog", params );
					},
					commit : function() {
						if ( associatedWidget && this._widgetConfig ) {
							associatedWidget.setData( 'raw', this._widgetConfig );
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
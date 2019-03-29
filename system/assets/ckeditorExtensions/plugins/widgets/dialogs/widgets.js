/**
 * @fileOverview Definition for widgets plugin dialog.
 *
 */

'use strict';
( function( $ ){

	var $window      = $( window )
	  , dialogWidth  = $window.width()  - 100
	  , dialogHeight = $window.height() - 200;

	if ( dialogWidth  < 800 ) { dialogWidth  = 800; }
	if ( dialogHeight < 300 ) { dialogHeight = 300; }

	CKEDITOR.dialog.add( 'widgets', function( editor ) {
		var lang             = editor.lang.widgets
		  , widgetCategories = ( editor.config.widgetCategories || "" )
		  , linkPickerCategory = ( editor.config.linkPickerCategory || "" )
		  , associatedWidget;

		return {
			title: lang.title,
			minWidth: dialogWidth,
			minHeight: dialogHeight,
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
						src    : '',
						width  : dialogWidth  + 'px',
						height : dialogHeight + 'px',
						setup  : function( widget ) {
							var params    = {}
							  , iframeQs  = { widgetCategories : widgetCategories, linkPickerCategory : linkPickerCategory, cacheBuster : Math.random().toString(36).substring(7) }
							  , iframeSrc = buildAdminLink( "widgets", "dialog", iframeQs )
							  , dlg       = this;

							associatedWidget = widget;

							if ( widget.data.widgetId ) {
								params.widget = widget.data.widgetId;

								if ( widget.data.configJson ) {
									params.configJson = widget.data.configJson;
								}

								// little trick to send long / complex data to the server
								// ready for the subsequent iFrame request
								// uses ColdBox FlashRAM to store the data which is then picked
								// up by next request
								$.ajax({
									  url    : buildAdminLink( "ajaxhelper.temporarilyStoreData" )
									, method : "POST"
									, data   : params
									, success: function(){
										dlg.getElement().$.src = iframeSrc;
									 }
								});
							} else {
								dlg.getElement().$.src = iframeSrc;
							}
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

} )( presideJQuery );
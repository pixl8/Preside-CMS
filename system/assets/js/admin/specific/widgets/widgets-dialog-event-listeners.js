var onDialogEvent = ( function( $ ){

	var listener, saveConfig, hasConfigJustBeenSaved, returnSavedConfigToParent, triggerDialogOk, parentDialog, $configForm;

	listener = function( e, dialog ){
		var eventName = e.name || "";

		switch( e.name || "" ){
			case "ok":
				return saveConfig( dialog );
			break;

			case "load":
				parentDialog = dialog;
				if ( hasConfigJustBeenSaved() ) {
					returnSavedConfigToParent( dialog );
				}
				if ( pageHasSaveableForm() ) {
					dialog.enableButton( "ok" );
				} else {
					dialog.disableButton( "ok" );
				}

			break;
		}

		return true;
	};

	saveConfig = function( dialog ){
		if ( !pageHasSaveableForm() ) {
			return true; // nothing selected, just close the dialog
		}

		dialog.disableButton( "ok" );
		setTimeout( function() {
			getConfigForm().submit();
			dialog.enableButton( "ok" ); // if submit failed, i.e. validation errors
		}, 2 ); /* submit the form in a couple of milliseconds time *after* we've returned false to the dialog event handler to prevent it from closing*/

		return false; /* do not close the dialog until form is saved */
	};

	hasConfigJustBeenSaved = function(){
		return ( typeof cfrequest.widgetSavedConfig ) !== "undefined";
	};
	returnSavedConfigToParent = function( dialog ){
		dialog.getContentElement( "iframe" )._widgetConfig = cfrequest.widgetSavedConfig;
		dialog.commitContent();
		dialog.hide();
	};

	pageHasSaveableForm = function(){
		return getConfigForm().length;
	};

	getConfigForm = function(){
		return $( "form[ data-widget-config-form=true ]:first" );
	};

	// Triggering dialog events
	triggerDialogOk = function( e ){
		e.preventDefault();
		if ( parentDialog ) {
			parentDialog.click( "ok" );
		}
	};

	$('body').keydown( 'esc', function( e ){
		if ( parentDialog ) {
			parentDialog.hide();
		}
	} );
	$configForm = getConfigForm();
	if ( $configForm.length ) {
		$configForm.find( 'input,select,textarea' ).keydown( "ctrl+return", triggerDialogOk );
	}



	return listener;

} )( presideJQuery );
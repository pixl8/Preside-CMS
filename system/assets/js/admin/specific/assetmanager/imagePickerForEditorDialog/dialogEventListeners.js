var onDialogEvent = ( function( $ ){

	var listener, saveConfig, triggerDialogOk, parentDialog, $configForm;

	listener = function( e, dialog ){
		var eventName = e.name || "";

		switch( e.name || "" ){
			case "ok":
				return saveConfig( dialog );
			break;

			case "load":
				parentDialog = dialog;
				dialog.enableButton( "ok" );
			break;
		}

		return true;
	};

	saveConfig = function( dialog ){
		var config = encodeURIComponent( JSON.stringify( $configForm.serialize() ) );

		dialog.getContentElement( "iframe" )._imgConfig = "{{image:" + config + ":image}}";
		dialog.commitContent();

		return true;
	};

	// Triggering dialog events
	triggerDialogOk = function( e ){
		e.preventDefault();
		if ( parentDialog ) {
			parentDialog.click( "ok" );
		}
	};

	$( 'body' ).keydown( 'esc', function( e ){
		if ( parentDialog ) {
			parentDialog.hide();
		}
	} );

	$configForm = $( "#image-config-form" );
	if ( $configForm.length ) {
		$configForm.find( 'input,select,textarea' ).keydown( "ctrl+return", triggerDialogOk );
	}

	return listener;

} )( presideJQuery );
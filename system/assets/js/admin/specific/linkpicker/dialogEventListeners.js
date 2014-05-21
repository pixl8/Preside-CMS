var onDialogEvent = ( function( $ ){

	var listener, saveLink, triggerDialogOk, parentDialog, $linkForm, assetType;

	listener = function( e, dialog ){
		var eventName = e.name || "";

		switch( e.name || "" ){
			case "ok":
				return saveLink( dialog );
			break;

			case "load":
				parentDialog = dialog;
				dialog.enableButton( "ok" );
			break;
		}

		return true;
	};

	saveLink = function( dialog ){
		if ( $linkForm.valid() ) {
			dialog._plugin.updateLink( $linkForm.serializeObject(), dialog )

			return true;
		}

		return false;
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

	$linkForm = $( "#link-picker-form" );

	if ( $linkForm.length ) {
		$linkForm.find( 'input,select,textarea' ).keydown( "ctrl+return", triggerDialogOk );
	}

	return listener;

} )( presideJQuery );
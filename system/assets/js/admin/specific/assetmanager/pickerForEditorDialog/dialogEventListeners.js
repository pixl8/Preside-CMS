var onDialogEvent = ( function( $ ){

	var listener, saveConfig, triggerDialogOk, parentDialog, $configForm, assetType;

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
		if ( $configForm.valid() ) {
			var config = encodeURIComponent( $configForm.serializeJSON() );

			dialog.getContentElement( "iframe" )._config = "{{" + assetType + ":" + config + ":" + assetType + "}}";
			dialog.commitContent();

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

	$configForm = $( "#asset-config-form" );
	assetType   = $configForm.data( "assetType" ) || "image";

	if ( $configForm.length ) {
		$configForm.find( 'input,select,textarea' ).keydown( "ctrl+return", triggerDialogOk );
	}

	return listener;

} )( presideJQuery );
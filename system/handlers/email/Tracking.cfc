/**
 * Handler used for tracking email opens, clicks, etc.
 *
 */
component {

	property name="emailLoggingService" inject="emailLoggingService";

	_transparentPixelPng = ToBinary( "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAoMBgDTD2qgAAAAASUVORK5CYII=" );

	public void function open( event, rc, prc ) {
		var messageId = Trim( rc.mid ?: "" );

		if ( messageId.len() ) {
			try {
				emailLoggingService.markAsOpened( messageId );
			} catch( any e ) {
				logError( e );
			}
		}

		content type="image/png" variable="#_transparentPixelPng#";abort;
	}

}
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
				// ignore errors that will be due to original email log no longer existing
			}
		}

		content type="image/png" variable="#_transparentPixelPng#";abort;
	}

	public void function click( event, rc, prc ) {
		var messageId         = Trim( rc.mid  ?: "" );
		var link              = Trim( rc.link ?: "" );
		var ignoreLinkPattern = "/e/t/[co]/"; // ignore email tracking links for reporting (i.e. we may have a double encoded link somehow)

		try {
			link = ReplaceNoCase( ToString( ToBinary( link ) ), "&amp;", "&", "all" );
		} catch( any e ) {
			logError( e );
			event.notFound();
		}

		if ( messageId.len() && !ReFindNoCase( ignoreLinkPattern, link ) ) {
			try {
				emailLoggingService.recordClick( id=messageId, link=link );
			} catch( any e ) {
				// ignore errors that will be due to original email log no longer existing
			}
		}

		setNextEvent( url=link );
	}

}
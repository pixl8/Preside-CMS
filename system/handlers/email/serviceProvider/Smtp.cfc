/**
 * SMTP Service provider for email sending with plain SMTP.
 *
 */
component {

	private boolean function send( struct sendArgs={}, struct settings={} ) {
		var m          = new Mail();
		var mailServer = settings.server   ?: "";
		var port       = settings.port     ?: "";
		var username   = settings.username ?: "";
		var password   = settings.password ?: "";

		m.setTo( sendArgs.to.toList( ";" ) );
		m.setFrom( sendArgs.from );
		m.setSubject( sendArgs.subject );

		if ( sendArgs.cc.len()  ) {
			m.setCc( sendArgs.cc.toList( ";" ) );
		}
		if ( sendArgs.bcc.len() ) {
			m.setBCc( sendArgs.bcc.toList( ";" ) );
		}
		if ( Len( Trim( sendArgs.textBody ) ) ) {
			m.addPart( type='text', body=Trim( sendArgs.textBody ) );
		}
		if ( Len( Trim( sendArgs.htmlBody ) ) ) {
			m.addPart( type='html', body=Trim( sendArgs.htmlBody ) );
		}
		if ( Len( Trim( mailServer ) ) ) {
			m.setServer( mailServer );
		}
		if ( Len( Trim( port ) ) ) {
			m.setPort( port );
		}
		if ( Len( Trim( username ) ) ) {
			m.setUsername( username );
		}
		if ( Len( Trim( password ) ) ) {
			m.setPassword( password );
		}

		for( var param in sendArgs.params ){
			m.addParam( argumentCollection=sendArgs.params[ param ] );
		}

		sendArgs.messageId = sendArgs.messageId ?: CreateUUId();

		m.addParam( name="X-Mailer", value="PresideCMS" );
		m.addParam( name="Message-ID", value=sendArgs.messageId );
		m.send();

		return true;
	}

}
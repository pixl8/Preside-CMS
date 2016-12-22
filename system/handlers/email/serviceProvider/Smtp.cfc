/**
 * SMTP Service provider for email sending with plain SMTP.
 *
 */
component {
	property name="emailService" inject="emailService";

	private boolean function send( struct sendArgs={}, struct settings={} ) {
		var m           = new Mail();
		var mailServer  = settings.server      ?: "";
		var port        = settings.port        ?: "";
		var username    = settings.username    ?: "";
		var password    = settings.password    ?: "";
		var params      = sendArgs.params      ?: {};
		var attachments = sendArgs.attachments ?: [];

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

		for( var param in params ){
			m.addParam( argumentCollection=sendArgs.params[ param ] );
		}
		for( var attachment in attachments ) {
			var md5sum   = Hash( attachment.binary );
			var tmpDir   = getTempDirectory() & "/" & md5sum & "/";
			var filePath = tmpDir & attachment.name
			var remove   = IsBoolean( attachment.removeAfterSend ?: "" ) ? attachment.removeAfterSend : true;

			if ( !FileExists( filePath ) ) {
				DirectoryCreate( tmpDir, true, true );
				FileWrite( filePath, attachment.binary );
			}

			m.addParam( disposition="attachment", file=filePath, remove=remove );
		}

		sendArgs.messageId = sendArgs.messageId ?: CreateUUId();

		m.addParam( name="X-Mailer", value="PresideCMS" );
		m.addParam( name="X-Message-ID", value=sendArgs.messageId );
		m.send();

		return true;
	}

	private any function validateSettings( required struct settings, required any validationResult ) {
		if ( IsTrue( settings.check_connection ?: "" ) ) {
			var errorMessage = emailService.validateConnectionSettings(
				  host     = arguments.settings.server    ?: ""
				, port     = Val( arguments.settings.port ?: "" )
				, username = arguments.settings.username  ?: ""
				, password = arguments.settings.password  ?: ""
			);

			if ( Len( Trim( errorMessage ) ) ) {
				if ( errorMessage == "authentication failure" ) {
					validationResult.addError( "username", "email.serviceProvider.smtp:validation.server.authentication.failure" );
				} else {
					validationResult.addError( "server", "email.serviceProvider.smtp:validation.server.details.invalid", [ errorMessage ] );
				}
			}
		}

		return validationResult;
	}
}
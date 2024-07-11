/**
 * Handler used for tracking email opens, clicks, etc.
 *
 * @feature emailCenter
 */
component {

	property name="emailLoggingService" inject="emailLoggingService";

	_transparentPixelPng = ToBinary( "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAoMBgDTD2qgAAAAASUVORK5CYII=" );

	public void function open( event, rc, prc ) {
		var messageId = Trim( rc.mid ?: "" );

		if ( messageId.len() ) {
			try {
				emailLoggingService.processOpenEvent(
					  messageId = messageId
					, userAgent = event.getUserAgent()
					, ipAddress = event.getClientIp()
				);
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
		var getLinkFromDb     = isFeatureEnabled( "emailLinkShortener" ) && ReFindNoCase( "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}", link );

		if ( getLinkFromDb ) {
			link = getModel( dsl="presidecms:object:email_template_shortened_link" ).selectData( id=link );

			if ( link.recordCount ) {
				if ( messageId.len() && !ReFindNoCase( ignoreLinkPattern, link.href ) ) {
					try {
						emailLoggingService.processClickEvent(
							  messageId = messageId
							, link      = link.href
							, linkTitle = link.title
							, linkBody  = link.body
							, userAgent = event.getUserAgent()
							, ipAddress = event.getClientIp()
						);
					} catch( any e ) {
						// ignore errors that will be due to original email log no longer existing
					}
				}

				setNextEvent( url=link.href );
			} else {
				event.notFound();
			}
		}

		try {
			link = ReplaceNoCase( ToString( ToBinary( link ) ), "&amp;", "&", "all" );
		} catch( any e ) {
			logError( e );
			event.notFound();
		}

		if ( !emailLoggingService.clickLinkIsValid( link, messageId ) ) {
			event.notFound();
		}

		if ( messageId.len() && !ReFindNoCase( ignoreLinkPattern, link ) ) {
			try {
				emailLoggingService.processClickEvent(
					  messageId = messageId
					, link      = link
					, userAgent = event.getUserAgent()
					, ipAddress = event.getClientIp()
				);
			} catch( any e ) {
				// ignore errors that will be due to original email log no longer existing
			}
		}

		setNextEvent( url=link );
	}

	public void function honeyPot( event, rc, prc ) {
		emailLoggingService.recordHoneyPotHit(
			  messageId = ( rc.mid  ?: "" )
			, userAgent = event.getUserAgent()
			, ipAddress = event.getClientIp()
		);

		setNextEvent( url="/" );
	}


// PRIVATE BACKGROUND THREAD HANDLERS
	private function processOpenEventWithBotDetection( event, rc, prc, args={}, task={} ) {
		emailLoggingService.processOpenEventWithBotDetection( argumentCollection=args, eventDate=task.dateCreated ?: Now() );
	}
	private function processClickEventWithBotDetection( event, rc, prc, args={}, task={} ) {
		emailLoggingService.processClickEventWithBotDetection( argumentCollection=args, eventDate=task.dateCreated ?: Now() );
	}
}
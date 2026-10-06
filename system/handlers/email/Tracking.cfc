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

		if ( messageId.len() && emailLoggingService.sendLogExists( messageId ) ) {
			try {
				emailLoggingService.processOpenEvent(
					  messageId   = messageId
					, userAgent   = event.getUserAgent()
					, ipAddress   = event.getClientIp()
					, requestMeta = _trackingRequestMeta()
				);
			} catch( any e ) {
				logError( e );
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
				if ( messageId.len() && !emailLoggingService.sendLogExists( messageId ) ) {
					event.notFound();
				}

				if ( messageId.len() && !ReFindNoCase( ignoreLinkPattern, link.href ) ) {
					try {
						emailLoggingService.processClickEvent(
							  messageId   = messageId
							, link        = link.href
							, linkTitle   = link.title
							, linkBody    = link.body
							, userAgent   = event.getUserAgent()
							, ipAddress   = event.getClientIp()
							, requestMeta = _trackingRequestMeta()
						);
					} catch( any e ) {
						logError( e );
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

		if ( messageId.len() && !emailLoggingService.sendLogExists( messageId ) ) {
			event.notFound();
		}

		if ( messageId.len() && !ReFindNoCase( ignoreLinkPattern, link ) ) {
			try {
				emailLoggingService.processClickEvent(
					  messageId   = messageId
					, link        = link
					, userAgent   = event.getUserAgent()
					, ipAddress   = event.getClientIp()
					, requestMeta = _trackingRequestMeta()
				);
			} catch( any e ) {
				logError( e );
			}
		}

		setNextEvent( url=link );
	}

	public void function honeyPot( event, rc, prc ) {
		var messageId = Trim( rc.mid ?: "" );

		if ( messageId.len() && emailLoggingService.sendLogExists( messageId ) ) {
			try {
				emailLoggingService.recordHoneyPotHit(
					  messageId = messageId
					, userAgent = event.getUserAgent()
					, ipAddress = event.getClientIp()
				);
			} catch( any e ) {
				logError( e );
			}
		}

		setNextEvent( url="/" );
	}

	private struct function _trackingRequestMeta() {
		return {
			  accept_language = cgi.http_accept_language ?: ""
			, cf_bot_score    = cgi.http_cf_bot_score    ?: ""
			, cf_verified_bot = cgi.http_cf_verified_bot ?: ""
		};
	}


// PRIVATE BACKGROUND THREAD HANDLERS
	private function processOpenEventWithBotDetection( event, rc, prc, args={}, task={} ) {
		emailLoggingService.processOpenEventWithBotDetection( argumentCollection=args, eventDate=task.dateCreated ?: Now() );
	}
	private function processClickEventWithBotDetection( event, rc, prc, args={}, task={} ) {
		emailLoggingService.processClickEventWithBotDetection( argumentCollection=args, eventDate=task.dateCreated ?: Now() );
	}
}
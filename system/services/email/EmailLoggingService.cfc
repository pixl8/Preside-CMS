/**
 * Service that provides logic for logging email sends and updates to email delivery status
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 * @feature        emailCenter
 */
component {

	variables._lib   = [];
	variables._jsoup = "";

// CONSTRUCTOR
	/**
	 * @recipientTypeService.inject     emailRecipientTypeService
	 * @emailTemplateService.inject     emailTemplateService
	 * @sqlRunner.inject                sqlRunner
	 * @emailStatsService.inject        emailStatsService
	 * @emailBotDetectionService.inject emailBotDetectionService
	 *
	 */
	public any function init(
		  required any   recipientTypeService
		, required any   emailTemplateService
		, required any   sqlRunner
		, required any   emailStatsService
		, required any   emailBotDetectionService
	) {
		_setRecipientTypeService( arguments.recipientTypeService );
		_setEmailTemplateService( arguments.emailTemplateService );
		_setSqlRunner( arguments.sqlRunner );
		_setEmailStatsService( arguments.emailStatsService );
		_setEmailBotDetectionService( arguments.emailBotDetectionService );

		_jsoup = _new( "org.jsoup.Jsoup" );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Creates an email log entry and returns its ID (useful for future
	 * status updates to email delivery)
	 *
	 * @autodoc            true
	 * @template.hint      ID of the email template that is being sent
	 * @recipientType.hint ID of the recipient type configured for the template
	 * @recipient.hint     email address of the recipient
	 * @sender.hint        email address of the sender
	 * @subject.hint       Subject line of the email
	 * @sendArgs.hint      Structure of args that were original sent to the email send() method
	 */
	public string function createEmailLog(
		  required string template
		, required string recipientType
		, required string recipientId
		, required string recipient
		, required string sender
		, required string subject
		,          string resendOf = ""
		,          struct sendArgs = {}
		,          string layoutOverride = ""
		,          string customLayout   = ""
	) {
		var data = {
			  email_template  = arguments.template
			, recipient       = arguments.recipient
			, sender          = arguments.sender
			, subject         = arguments.subject
			, resend_of       = arguments.resendOf
			, send_args       = SerializeJson( arguments.sendArgs )
			, layout_override = arguments.layoutOverride
			, custom_layout   = arguments.customLayout
		};

		if ( Len( Trim( arguments.recipientType ) ) ) {
			data.append( _getAdditionalDataForRecipientType( arguments.recipientType, arguments.recipientId, arguments.sendArgs ) );
		}

		return $getPresideObject( "email_template_send_log" ).insertData( data );
	}

	/**
	 * Saves the email content of a sent email, to be used to view exact content
	 * sent, and for resending the original email
	 *
	 * @autodoc            true
	 * @template.hint      ID of the email template
	 * @id.hint            ID of the email template log record
	 * @htmlBody.hint      HTML content of the email
	 * @textBody.hint      Plain-text content of the email
	 */
	public void function logEmailContent(
		  required string template
		, required string id
		, required string htmlBody
		, required string textBody
	) {
		if ( !$isFeatureEnabled( "emailCenterResend" ) ) {
			return;
		}
		if ( !_getEmailTemplateService().shouldSaveContentForTemplate( arguments.template ) ) {
			return;
		}

		var contentExpiry = _getEmailTemplateService().getSavedContentExpiry( arguments.template );
		if ( contentExpiry <= 0 ) {
			return;
		}

		var expires       = now().add( "d", contentExpiry );
		var contentId     = $getPresideObject( "email_template_send_log_content" ).insertData( {
			  html_body = arguments.htmlBody
			, text_body = arguments.textBody
			, expires   = expires
		} );

		$getPresideObject( "email_template_send_log" ).updateData( id=arguments.id, data={
			content = contentId
		} );
	}

	/**
	 * Marks the given email as sent
	 *
	 * @autodoc         true
	 * @id.hint         ID of the email to mark as sent
	 * @templateId.hint ID of the email template
	 *
	 */
	public void function markAsSent(
		  required string id
		,          string templateId = ""
	) {
		var now     = _getNow();
		var updated = $getPresideObject( "email_template_send_log" ).updateData( id=arguments.id, data={
			  sent      = true
			, sent_date = now
		} );

		if ( updated ) {
			if ( !$helpers.isEmptyString( arguments.templateId ) && _getEmailTemplateService().templateExists( id=arguments.templateId ) ) {
				_getEmailTemplateService().updateLastSentDate( templateId=arguments.templateId, lastSentDate=now );
			}

			recordActivity(
				  messageId = arguments.id
				, activity  = "send"
			);
		}
	}

	/**
	 * Marks the given email as failed
	 *
	 * @autodoc     true
	 * @id.hint     ID of the email to mark as failed
	 * @reason.hint Failure reason to record
	 * @code.hint   Failure code to record
	 *
	 */
	public void function markAsFailed( required string id, required string reason, string code="" ) {
		var errorCode = Len( Trim( arguments.code ) ) ? Val( arguments.code ) : "";
		var updated = $getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( failed is null or failed = :failed ) and ( delivered is null or delivered = :delivered )"
			, filterParams = { id=arguments.id, failed=false, delivered=false }
			, data={
				  failed        = true
				, failed_date   = _getNow()
				, failed_reason = arguments.reason
				, failed_code   = errorCode
			  }
		);

		recordActivity(
			  messageId = arguments.id
			, activity  = "fail"
			, extraData = { reason=arguments.reason, code=errorCode }
		);
	}


	/**
	 * Marks the given email as 'marked as spam'
	 *
	 * @autodoc     true
	 * @id.hint     ID of the email to mark as marked as spam
	 *
	 */
	public void function markAsMarkedAsSpam( required string id ) {
		var updated = $getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( marked_as_spam is null or marked_as_spam = :marked_as_spam )"
			, filterParams = { id=arguments.id, marked_as_spam=false }
			, data={
				  marked_as_spam      = true
				, marked_as_spam_date = _getNow()
			  }
		);

		if ( updated ) {
			recordActivity(
				  messageId = arguments.id
				, activity  = "markasspam"
			);
		}
	}

	/**
	 * Marks the given email as 'unsubscribed'
	 *
	 * @autodoc     true
	 * @id.hint     ID of the email to mark as unsubsribed
	 *
	 */
	public void function markAsUnsubscribed( required string id ) {
		var updated = $getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( unsubscribed is null or unsubscribed = :unsubscribed )"
			, filterParams = { id=arguments.id, unsubscribed=false }
			, data={
				  unsubscribed      = true
				, unsubscribed_date = _getNow()
			  }
		);

		if ( updated ) {
			recordActivity(
				  messageId = arguments.id
				, activity  = "unsubscribe"
			);
		}
	}

	/**
	 * Marks the given email as hard bounced (cannot deliver due to address unkown)
	 *
	 * @autodoc     true
	 * @id.hint     ID of the email to mark as failed
	 * @reason.hint Failure reason to record
	 * @code.hint   Failure code to record
	 *
	 */
	public void function markAsHardBounced( required string id, required string reason, string code="" ) {
		var updated = $getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( hard_bounced is null or hard_bounced = :hard_bounced ) and ( opened is null or opened = :opened )"
			, filterParams = { id=arguments.id, hard_bounced=false, opened=false }
			, data={
				  hard_bounced      = true
				, hard_bounced_date = _getNow()
			  }
		);

		if ( updated ) {
			markAsFailed(
				  id     = arguments.id
				, reason = arguments.reason
				, code   = arguments.code
			);
		}
	}

	/**
	 * Marks the given email as delivered
	 *
	 * @autodoc       true
	 * @id.hint       ID of the email to mark as delivered
	 * @softMark.hint Used when some other action has occurred that indicates that the message was therefore delivered. i.e. we may not know *when* but we do now know that it *was* delivered.
	 */
	public void function markAsDelivered( required string id, boolean softMark=false ) {
		var data = {
			  delivered         = true
			, hard_bounced      = false
			, hard_bounced_date = ""
			, failed            = false
			, failed_date       = ""
			, failed_reason     = ""
			, failed_code       = ""
		};

		if ( !arguments.softMark ) {
			data.delivered_date = _getNow();
		}

		var updated = $getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( delivered is null or delivered = :delivered )"
			, filterParams = { id=arguments.id, delivered=false }
			, data         = data
		);

		if ( updated ) {
			recordActivity(
				  messageId = arguments.id
				, activity  = "deliver"
			);
		}

	}

	public void function processOpenEvent(
		  required string messageId
		, required string userAgent
		, required string ipAddress
		,          struct requestMeta = {}
	) {
		if ( !$isFeatureEnabled( "emailTrackingBotDetection" ) ) {
			markAsOpened(
				  id        = arguments.messageId
				, userAgent = arguments.userAgent
				, ipAddress = arguments.ipAddress
			);
			return;
		}

		recordActivity(
			  messageId             = arguments.messageId
			, activity              = "open"
			, userIp                = arguments.ipAddress
			, userAgent             = arguments.userAgent
			, eventDate             = _getNow()
			, extraData             = arguments.requestMeta
			, classification        = "tentative"
			, recordStats           = false
			, announceInterception  = false
		);
	}

	public void function recordBotOpen(
		  required string id
		,          string userAgent = ""
		,          string ipAddress = ""
		,          date   eventDate
	) {
		if ( !StructKeyExists( arguments, "eventDate" ) || !IsDate( arguments.eventDate ) ) {
			arguments.eventDate = _getNow();
		}

		recordActivity(
			  messageId = arguments.id
			, activity  = "bot_open"
			, userIp    = arguments.ipAddress
			, userAgent = arguments.userAgent
			, eventDate = arguments.eventDate
		);
	}

	public void function processOpenEventWithBotDetection(
		  required string messageId
		, required string userAgent
		, required string ipAddress
		, required date   eventDate
	) {
		if ( _getEmailBotDetectionService().isBot( argumentCollection=arguments ) ) {
			recordBotOpen(
				  id        = arguments.messageId
				, userAgent = arguments.userAgent
				, ipAddress = arguments.ipAddress
				, eventDate = arguments.eventDate
			);
		} else {
			markAsOpened( argumentCollection=arguments, id=arguments.messageId );
		}
	}

	/**
	 * Marks the given email as opened
	 *
	 * @autodoc       true
	 * @id.hint       ID of the email to mark as opened
	 * @softMark.hint Used when some other action has occurred that indicates that the message was therefore opened. i.e. we may not know *when* but we do now know that it *was* opened.
	 *
	 */
	public void function markAsOpened(
		  required string  id
		,          boolean softMark    = false
		,          boolean skipActivity = false
		,          string  userAgent    = cgi.http_user_agent
		,          string  ipAddress    = cgi.remote_addr
		,          date    eventDate
	) {
		if ( !StructKeyExists( arguments, "eventDate" ) || !IsDate( arguments.eventDate ) ) {
			arguments.eventDate = _getNow();
		}

		var data = { opened=true };

		if ( !arguments.softMark ) {
			data.opened_date = arguments.eventDate;
			data.open_count  = 1;
		}

		var dao     = $getPresideObject( "email_template_send_log" );
		var updated = dao.updateData(
			  filter       = "id = :id and ( opened is null or opened = :opened )"
			, filterParams = { id=arguments.id, opened=false }
			, data         = data
		);

		if ( !updated && !arguments.softMark ) {
			_getSqlRunner().runSql(
				  dsn        = dao.getDsn()
				, sql        = _getRecordOpenSql()
				, params     = _getRecordOpenParams( arguments.id )
				, returnType = "info"
			);
		}

		markAsDelivered( arguments.id, true );

		if ( !arguments.softMark ) {
			if ( arguments.skipActivity ) {
				_processEventForStatsTables(
					  message  = arguments.id
					, activity = "open"
					, first    = ( updated > 0 )
					, hitDate  = arguments.eventDate
				);
			} else {
				recordActivity(
					  messageId = arguments.id
					, activity  = "open"
					, first     = ( updated > 0 )
					, userIp    = arguments.ipAddress
					, userAgent = arguments.userAgent
					, eventDate = arguments.eventDate
				);
			}
		}
	}

	/**
	 * Records a "click" to a "honeypot" link for bot detection
	 */
	public void function recordHoneyPotHit(
		  required string messageId
		,          string userAgent = cgi.http_user_agent
		,          string ipAddress = cgi.remote_addr
	) {
		recordActivity(
			  messageId = arguments.messageId
			, activity  = "honeypotclick"
			, userIp    = arguments.ipAddress
			, userAgent = arguments.userAgent
		);

		if ( $isFeatureEnabled( "emailTrackingBotDetection" ) ) {
			classifyMessageTracking( arguments.messageId, true );
		}
	}

	public void function processClickEvent(
		  required string messageId
		, required string link
		,          string linkTitle = ""
		,          string linkBody  = ""
		,          string userAgent = cgi.http_user_agent
		,          string ipAddress = cgi.remote_addr
		,          struct requestMeta = {}
	) {
		if ( !$isFeatureEnabled( "emailTrackingBotDetection" ) ) {
			recordClick(
				  id        = arguments.messageId
				, link      = arguments.link
				, linkTitle = arguments.linkTitle
				, linkBody  = arguments.linkBody
				, userAgent = arguments.userAgent
				, ipAddress = arguments.ipAddress
			);
			return;
		}

		var extra = Duplicate( arguments.requestMeta );
		extra.link       = arguments.link;
		extra.link_title = arguments.linkTitle;
		extra.link_body  = arguments.linkBody;

		recordActivity(
			  messageId            = arguments.messageId
			, activity             = "click"
			, extraData            = extra
			, userIp               = arguments.ipAddress
			, userAgent            = arguments.userAgent
			, eventDate            = _getNow()
			, classification       = "tentative"
			, recordStats          = false
			, announceInterception = false
		);
	}

	public void function recordBotClick(
		  required string id
		,          string link      = ""
		,          string linkTitle = ""
		,          string linkBody  = ""
		,          string userAgent = ""
		,          string ipAddress = ""
		,          date   eventDate
	) {
		if ( !StructKeyExists( arguments, "eventDate" ) || !IsDate( arguments.eventDate ) ) {
			arguments.eventDate = _getNow();
		}

		recordActivity(
			  messageId = arguments.id
			, activity  = "bot_click"
			, extraData = { link=arguments.link, link_title=arguments.linkTitle, link_body=arguments.linkBody }
			, userIp    = arguments.ipAddress
			, userAgent = arguments.userAgent
			, eventDate = arguments.eventDate
		);
	}

	public void function processClickEventWithBotDetection(
		  required string messageId
		, required string link
		, required date   eventDate
		,          string linkTitle = ""
		,          string linkBody  = ""
		,          string userAgent = cgi.http_user_agent
		,          string ipAddress = cgi.remote_addr
	) {
		if ( _getEmailBotDetectionService().isBot( argumentCollection=arguments ) ) {
			recordBotClick(
				  id        = arguments.messageId
				, link      = arguments.link
				, linkTitle = arguments.linkTitle
				, linkBody  = arguments.linkBody
				, userAgent = arguments.userAgent
				, ipAddress = arguments.ipAddress
				, eventDate = arguments.eventDate
			);
		} else {
			recordClick( argumentCollection=arguments, id=arguments.messageId );
		}
	}

	/**
	 * Records a link click for an email
	 *
	 */
	public void function recordClick(
		  required string id
		, required string link
		,          string linkTitle = ""
		,          string linkBody  = ""
		,          date    eventDate    = Now()
		,          string  userAgent    = cgi.http_user_agent
		,          string  ipAddress    = cgi.remote_addr
		,          boolean skipActivity = false
	) {
		var dao           = $getPresideObject( "email_template_send_log" );
		var updated       = false;
		var wasFirstClick = updated = dao.updateData(
			  filter = { id=arguments.id, click_count=0 }
			, data   = { clicked=true, click_count=1 }
		);

		if ( !updated ) {
			updated = _getSqlRunner().runSql(
				  dsn        = dao.getDsn()
				, sql        = _getRecordClickSql()
				, params     = _getRecordClickParams( arguments.id )
				, returnType = "info"
			);
			updated =  Val( updated.recordCount ?: 0 ) > 0
		}

		if ( updated ) {
			if ( arguments.skipActivity ) {
				_processEventForStatsTables(
					  message  = arguments.id
					, activity = "click"
					, data     = { link=arguments.link, link_title=arguments.linkTitle, link_body=arguments.linkBody }
					, first    = wasFirstClick
					, hitDate  = arguments.eventDate
				);
			} else {
				recordActivity(
					  messageId = arguments.id
					, activity  = "click"
					, extraData = { link=arguments.link, link_title=arguments.linkTitle, link_body=arguments.linkBody }
					, first     = wasFirstClick
					, userIp    = arguments.ipAddress
					, userAgent = arguments.userAgent
					, eventDate = arguments.eventDate
				);
			}
		}

		markAsOpened( id=id, softMark=true, userAgent=arguments.userAgent, ipAddress=arguments.ipAddress );
	}

	/**
	 * Resends an email. A duplicate of the original content is sent
	 *
	 */
	public void function resendOriginalEmail( required string id ) {
		var dao                    = $getPresideObject( "email_template_send_log");
		var message                = dao.selectData(
			  id           = arguments.id
			, selectFields = [
				  "email_template_send_log.*"
				, "content.html_body as html_body"
				, "content.text_body as text_body"
			  ]
		);
		var template               = _getEmailTemplateService().getTemplate( message.email_template );
		var recipientIdLogProperty = _getRecipientTypeService().getRecipientIdLogPropertyForRecipientType( template.recipient_type );
		var sendArgs               = deserializeJson( message.send_args );

		var resentMessageId        = $sendEmail(
		      template              = message.email_template
		    , recipientId           = message[ recipientIdLogProperty ] ?: ""
		    , to                    = [ message.recipient ]
		    , from                  = message.sender
		    , subject               = message.subject
		    , htmlBody              = message.html_body
		    , textBody              = message.text_body
		    , args                  = sendArgs
		    , resendOf              = message.id
		    , returnLogId           = true
		    , overwriteTemplateArgs = true
			, layout                = message.layout_override
			, customLayout          = message.custom_layout
		);

		$audit(
			  action   = "resend_original_email"
			, type     = "emailresend"
			, recordId = resentMessageId
			, detail   = { subject=message.subject, recipient=message.recipient, originalMessageId=arguments.id }
		);

		recordActivity(
			  messageId = arguments.id
			, activity  = "resend"
			, userAgent = ""
			, extraData = { resentMessageId=resentMessageId, resendType="original" }
		);

	}

	/**
	 * Resends an email. Email is regenerated using the original sendArgs
	 *
	 */
	public void function rebuildAndResendEmail( required string id ) {
		var dao                    = $getPresideObject( "email_template_send_log");
		var message                = dao.selectData( id=arguments.id );
		var template               = _getEmailTemplateService().getTemplate( message.email_template );
		var recipientIdLogProperty = _getRecipientTypeService().getRecipientIdLogPropertyForRecipientType( template.recipient_type );
		var originalArgs           = deserializeJson( message.send_args );
		var sendArgs               = _getEmailTemplateService().rebuildArgsForResend( template=message.email_template, logId=id, originalArgs=originalArgs );
		var resentMessageId        = $sendEmail(
			  template     = message.email_template
			, recipientId  = message[ recipientIdLogProperty ] ?: ""
			, to           = !len( message[ recipientIdLogProperty ] ?: "" ) ? [ message.recipient ] : []
			, args         = sendArgs
			, resendOf     = message.id
			, returnLogId  = true
			, layout       = message.layout_override
			, customLayout = message.custom_layout
		);

		$audit(
			  action   = "rebuild_and_resend_email"
			, type     = "emailresend"
			, recordId = resentMessageId
			, detail   = { subject=message.subject, recipient=message.recipient, originalMessageId=arguments.id }
		);

		recordActivity(
			  messageId = arguments.id
			, activity  = "resend"
			, userAgent = ""
			, extraData = { resentMessageId=resentMessageId, resendType="rebuild" }
		);

	}

	/**
	 * Delete expired email content and it's send log
	 *
	 */
	public boolean function deleteExpiredContent( any logger ) {
		var canLog   = StructKeyExists( arguments, "logger" );
		var canInfo  = canLog && logger.canInfo();
		var canError = canLog && logger.canError();
		var dao      = $getPresideObject( "email_template_send_log_content");

		if ( canInfo ) { logger.info( "Deleting expired email content from logs..." ); }

		var deleted  = dao.deleteData(
			  filter       = "expires <= :expires"
			, filterParams = { expires=now() }
		);

		if ( canInfo ) { logger.info( "Content of [#deleted#] emails deleted." ); }

		var emailSettings = $getPresideCategorySettings( "email" );
		if ( $helpers.isTrue( emailSettings.remove_view_online_content ?: "" ) && ( val( emailSettings.view_online_content_expiry ?: "" ) > 0 ) ) {
			var deleted = $getPresideObject( "email_template_view_online_content").deleteData(
				  filter       = "datecreated <= :datecreated"
				, filterParams = { datecreated=dateAdd( "d", -val( emailSettings.view_online_content_expiry ), now() ) }
			);

			if ( canInfo ) { logger.info( "[#deleted#] emails' view online contents deleted." ); }
		}

		return true;
	}

	/**
	 * Inserts a tracking pixel into the given HTML email
	 * content (based on the given message ID). Returns
	 * the HTML with the inserted tracking pixel
	 *
	 * @autodoc          true
	 * @messageId.hint   ID of the message (log id)
	 * @messageHtml.hint HTML content of the message
	 */
	public string function insertTrackingPixel(
		  required string messageId
		, required string messageHtml
	) {
		var trackingUrl   = $getRequestContext().buildLink( linkto="email.tracking.open", queryString="mid=" & arguments.messageId );
		var trackingPixel = "<img src=""#trackingUrl#"" width=""1"" height=""1"" style=""width:1px;height:1px"" />";

		if ( $isFeatureEnabled( "emailTrackingBotDetection" ) ) {
			var honeyPotUrl  = $getRequestContext().buildLink( linkto="email.tracking.honeypot", queryString="mid=" & arguments.messageId );
			var honeyPotLink = '<a href="#honeyPotUrl#" style="display:inline-block;overflow:hidden;width:1px;height:1px;font-size:1px;line-height:1px;color:transparent;">Preferences</a>';

			trackingPixel &= honeyPotLink;
		}

		if ( FindNoCase( "</body>", messageHtml ) ) {
			return ReplaceNoCase( messageHtml, "</body>", trackingPixel & "</body>" );
		}

		return messageHtml & trackingPixel;
	}

	/**
	 * converts links in html email to tracking links,
	 * Returns the HTML with the inserted tracking links.
	 *
	 * @autodoc          true
	 * @messageId.hint   ID of the message (log id)
	 * @messageHtml.hint HTML content of the message
	 */
	public string function insertClickTrackingLinks(
		  required string messageId
		, required string messageHtml
	) {
		var doc             = "";
		var links           = "";
		var link            = "";
		var attribs         = "";
		var href            = "";
		var title           = "";
		var body            = "";
		var linkHash        = "";
		var shortenedLinkId = "";
		var storeInDb       = $isFeatureEnabled( "emailLinkShortener" );
		var baseTrackingUrl = $getRequestContext().buildLink( linkto="email.tracking.click", queryString="mid=#arguments.messageId#&link=" );
		var honeyPotPath    = _linkPath( $getRequestContext().buildLink( linkto="email.tracking.honeypot" ) );
		var linkDao         = storeInDb ? $getPresideObject( "email_template_shortened_link" ) : "";

		try {
			doc = _jsoup.parse( arguments.messageHtml );
			links = doc.select( "A" );
		} catch( any e ) {
			$raiseError( e );
			return arguments.messageHtml;
		}

		for( link in links ) {
			attribs = link.attributes();
			href = Trim( attribs.get( "href" ) );

			if ( Len( href ) && ReFindNoCase( "^https?://", href ) && !_hrefIsHoneyPot( href, honeyPotPath ) ) {
				if ( storeInDb ) {
					title           = Trim( attribs.get( "title" ) );
					body            = Trim( link.text() );
					linkHash        = Hash( href & title & body );
					shortenedLinkId = linkDao.selectData( filter={ link_hash=linkhash }, selectFields=[ "id" ] ).id;

					if ( !Len( shortenedLinkId ) ) {
						try {
							shortenedLinkId = linkDao.insertData( {
								  link_hash = linkhash
								, href      = href
								, title     = title
								, body      = body
							} );
						} catch( any e ) {
							shortenedLinkId = linkDao.selectData( filter={ link_hash=linkhash }, selectFields=[ "id" ], useCache=false ).id;

							if ( !shortenedLinkId.len() ) {
								rethrow;
							}
						}
					}

					link.attr( "href", baseTrackingUrl & shortenedLinkId );
				} else {
					link.attr( "href", baseTrackingUrl & ToBase64( href ) );
				}
			}
		}

		if ( $isFeatureEnabled( "emailStyleInlinerAscii" ) ) {
			doc.outputSettings().charset( "ASCII" );
		}

		return doc.html();
	}

	/**
	 * Records an activity performed against an specific sent email.
	 * e.g. opened, clicked link, etc.
	 *
	 * @autodoc true
	 * @messageId.hint ID of the message (send log) to record against
	 * @activity.hint  The activity type performed (see system ENUM, `emailActivityType`)
	 * @extraData.hint Structure of additional data that may be useful in email send log viewer (e.g. URL of clicked link)
	 *
	 */
	public void function recordActivity(
		  required string  messageId
		, required string  activity
		,          struct  extraData = {}
		,          string  userIp    = cgi.remote_addr
		,          string  userAgent = cgi.http_user_agent
		,          boolean first                = false
		,          date    eventDate            = Now()
		,          string  classification       = ""
		,          boolean recordStats          = true
		,          boolean announceInterception = true
	) {
		var fieldsToAddFromExtraData = [ "link", "code", "reason", "link_title", "link_body" ];
		var extra = StructCopy( arguments.extraData );
		var data = {
			  message       = arguments.messageId
			, activity_type = arguments.activity
			, user_ip       = arguments.userIp
			, user_agent    = arguments.userAgent
			, datecreated   = arguments.eventDate
		};

		if ( Len( arguments.classification ) ) {
			data.classification = arguments.classification;
		}

		for( var field in extra ) {
			if ( ArrayFind( fieldsToAddFromExtraData, LCase( field ) ) ) {
				data[ field ] = extra[ field ];
				extra.delete( field );
			}
		}
		data.extra_data = SerializeJson( extra );

		if ( arguments.announceInterception ) {
			try {
				$announceInterception( "onEmail#arguments.activity#", data );
			} catch( any e ) {
				$raiseError( e );
			}
		}

		try {
			$getPresideObject( "email_template_send_log_activity" ).insertData( data );
			if ( arguments.recordStats ) {
				_processEventForStatsTables(
					  message  = data.message
					, activity = arguments.activity
					, data     = data
					, first    = arguments.first
					, hitDate  = arguments.eventDate
				);
			}
		} catch( database e ) {
			// ignore missing logs when recording activity - but record the error for
			// info only
			$raiseError( e );
		}
	}

	/**
	 * Returns a struct of the log (by given id)
	 *
	 * @autodoc
	 * @id.hint ID of the log record
	 */
	public struct function getLog( required string id ) {
		var selectFields = [
			  "email_template_send_log.id"
			, "email_template_send_log.recipient"
			, "email_template_send_log.sender"
			, "email_template_send_log.subject"
			, "email_template_send_log.sent"
			, "email_template_send_log.failed"
			, "email_template_send_log.delivered"
			, "email_template_send_log.opened"
			, "email_template_send_log.marked_as_spam"
			, "email_template_send_log.unsubscribed"
			, "email_template_send_log.sent_date"
			, "email_template_send_log.failed_date"
			, "email_template_send_log.failed_reason"
			, "email_template_send_log.delivered_date"
			, "email_template_send_log.opened_date"
			, "email_template_send_log.marked_as_spam_date"
			, "email_template_send_log.unsubscribed_date"
			, "email_template_send_log.click_count"
			, "email_template_send_log.email_template"
			, "email_template_send_log.datecreated"
			, "email_template_send_log.resend_of"
			, "email_template_send_log.send_args"
			, "email_template.name"
			, "email_template.recipient_type"
		];
		if ( $isFeatureEnabled( "emailCenterResend" ) ) {
			selectFields.append( "content.html_body" );
			selectFields.append( "content.text_body" );
		}

		var logRecord = $getPresideObject( "email_template_send_log" ).selectData( id=arguments.id, selectFields=selectFields );

		for( var l in logRecord ) {
			return l;
		}

		return {};
	}

	/**
	 * Returns a query of an individual log's activity
	 *
	 * @autodoc
	 * @id.hint  ID of the log record
	 */
	public query function getActivity( required string id ) {
		return $getPresideObject( "email_template_send_log_activity" ).selectData(
			  filter  = { message = arguments.id }
			, orderBy = "datecreated"
		);
	}

	public boolean function sendLogExists( required string messageId ) {
		if ( !Len( Trim( arguments.messageId ) ) ) {
			return false;
		}

		return $getPresideObject( "email_template_send_log" ).dataExists( id=arguments.messageId );
	}

	/**
	 * Recomputes open_count and click_count on send logs from stored activity.
	 * An absolute replacement of the stored counts, not an adjustment.
	 *
	 * @templateId.hint Limit the recompute to send logs for one email template
	 */
	public void function recomputeOpenAndClickCounts( string templateId="" ) {
		_recomputeActivityCount( activityType="open", countColumn="open_count", templateId=arguments.templateId );
		_recomputeActivityCount( activityType="click", countColumn="click_count", templateId=arguments.templateId );
	}

	/**
	 * Security check on incoming links for link tracking.
	 * Block links that are not authorized. This is to prevent malicious
	 * manipulation of link tracking URLs from damaging
	 * reputation of the website.
	 *
	 * @autodoc
	 * @link.hint      The link to check
	 * @messageId.hint The ID of the send log message used to check against the content of the email to send
	 *
	 */
	public boolean function clickLinkIsValid( required string link, required string messageId ) {
		var poService = $getPresideObjectService();
		var event     = $getRequestContext();

		// links that just start with a slash, internal website links - no probs
		if ( ReFindNoCase( "^/", arguments.link ) ) {
			return true;
		}

		// otherwise, if they're not valid http resource, no good any way
		if ( !ReFindNoCase( "^https?://", arguments.link ) ) {
			return false;
		}

		if ( $helpers.isTrue( $getPresideSetting( "email", "disable_link_checking" ) ) ) {
			return true;
		}

		// is the domain of the link one that we host ourselves? (if so, fine)
		var linkMinusQs = ListFirst( arguments.link, "?&" );
		var domain = ReReplace( linkMinusQs, "^https?://([^/]+).*$", "\1" );
		if ( !Len( domain ) ) {
			return false;
		}

		if ( domain == event.getServerName() ) {
			return true;
		}


		if ( $isFeatureEnabled( "sites" ) ) {
			var currentSite = event.getSite();
			if ( domain == ( currentSite.domain ?: "" ) ) {
				return true;
			}
			var siteDomainObjects = [ "site", "site_alias_domain", "site_redirect_domain" ];
			for( var objName in siteDomainObjects ) {
				var domainExists = poService.dataExists( objectName=objName, filter={ domain=domain } );
				if ( domainExists ) {
					return true;
				}
			}
		} else {
			var allowedDomains = $getColdbox().getSetting( "allowedDomains" );

			if ( IsArray( allowedDomains ) && ArrayFindNoCase( allowedDomains, domain ) ) {
				return true;
			}
		}

		// Check domain against allowed domains setting
		var allowedDomains = _getDomainAllowlist();
		var domainRegex     = "";
		for( var allowedDomain in allowedDomains ) {
			if ( domain == allowedDomain ) {
				return true;
			}
			if ( Left( allowedDomain, 1 ) == "*" ) {
				domainRegex = replace( allowedDomain, "*", "" ) & "$";
				if ( reFindNoCase( domainRegex, domain ) ) {
					return true;
				}
			}
		}

		// is the link in our link table
		var linkExists =  $getPresideObject( "link" ).dataExists( filter="type = :type and external_address like :external_address", filterParams={
			  type             = "url"
			, external_address = ReReplace( linkMinusQs, "^https?://", "" ) & "%"
		} )
		if ( linkExists ) {
			return true;
		}


		// is the link included in the email content
		var versionObjName = poService.getVersionObjectName( "email_template" );
		var emailTemplate  = poService.selectData(
			  objectName   = "email_template_send_log"
			, id           = arguments.messageId
			, selectFields = [ "email_template.id", "email_template.html_body" ]
		);

		// layers of depth for encoded links found in nested widgets :o
		var encodedLinks = [ UrlEncodedFormat( linkMinusQs ) ];
		ArrayAppend( encodedLinks, UrlEncodedFormat( ArrayLast( encodedLinks ) ) );
		ArrayAppend( encodedLinks, UrlEncodedFormat( ArrayLast( encodedLinks ) ) );
		ArrayAppend( encodedLinks, UrlEncodedFormat( ArrayLast( encodedLinks ) ) );
		ArrayAppend( encodedLinks, UrlEncodedFormat( ArrayLast( encodedLinks ) ) );
		ArrayAppend( encodedLinks, UrlEncodedFormat( ArrayLast( encodedLinks ) ) );
		var contentFilter = { filter = "html_body like :html_body", filterParams={ html_body="%#arguments.link#%" } };
		for( var i=1; i<=ArrayLen( encodedLinks ); i++  ) {
			contentFilter.filter &= " or html_body like :html_body_#i#";
			contentFilter.filterParams[ "html_body_#i#" ] = { type="cf_sql_varchar", value="%#encodedLinks[ i ]#%" };
		}

		if ( emailTemplate.recordCount ) {
			if ( Find( linkMinusQs, emailTemplate.html_body ) ) {
				return true;
			}
			for( var encodedLink in encodedLinks ) {
				if ( Find( encodedLink, emailTemplate.html_body ) ) {
					return true;
				}
			}

			// or any previous versions of the email content?!
			if ( Len( Trim( versionObjName ) ) ) {
				return poService.dataExists(
					  objectName   = versionObjName
					, id           = emailTemplate.id
					, extraFilters = [ contentFilter ]
				);
			}

			return false;
		}

		// the email log no longer exists - have we included this link in *any* of
		// our historical email templates?!
		var start = GetTickCount();
		return poService.dataExists(
			  objectName   = ( Len( versionObjName ) ? versionObjName : "email_template" )
			, extraFilters = [ contentFilter ]
		);
	}

	public void function classifyTentativeTrackingEvents() {
		if ( !$isFeatureEnabled( "emailTrackingBotDetection" ) ) {
			return;
		}

		var settings = _getEmailBotDetectionService().getBotDetectionSettings();
		var cutoff   = DateAdd( "s", -Val( settings.sweepDelaySeconds ?: 90 ), _getNow() );
		var messages = $getPresideObject( "email_template_send_log_activity" ).selectData(
			  selectFields = [ "message" ]
			, filter       = "classification = :classification and datecreated <= :cutoff and activity_type in ( 'open', 'click' )"
			, filterParams = { classification="tentative", cutoff={ type="cf_sql_timestamp", value=cutoff } }
			, groupBy      = "message"
		);

		for ( var message in messages ) {
			try {
				classifyMessageTracking( message.message, false );
			} catch ( any e ) {
				$raiseError( e );
			}
		}
	}

	public void function classifyMessageTracking( required string messageId, boolean includeImmature=false ) {
		var events   = _trackingEventsForMessage( arguments.messageId );
		var settings = _getEmailBotDetectionService().getBotDetectionSettings();
		var sentDate = _sendDateForMessage( arguments.messageId );
		var now      = _getNow();
		var tracked  = 0;
		var volume   = false;

		for ( var event in events ) {
			if ( ListFindNoCase( "open,click,bot_open,bot_click", event.activityType ) ) {
				tracked++;
			}
		}

		volume = tracked >= Val( settings.eventCountThreshold ?: 6 );

		for ( var event in events ) {
			if ( !_shouldScoreTrackingEvent( event, settings, now, arguments.includeImmature, volume ) ) {
				continue;
			}

			applyTrackingClassification(
				  activity = event
				, score    = _getEmailBotDetectionService().scoreTrackingEvent(
					  event         = event
					, messageEvents = events
					, sentDate      = sentDate
				)
			);
		}
	}

	public void function applyTrackingClassification( required struct activity, required struct score ) {
		var activityType = arguments.activity.activityType ?: "";
		var previous     = arguments.activity.classification ?: "";
		var isBot        = IsBoolean( arguments.score.isBot ?: "" ) && arguments.score.isBot;
		var newType      = activityType;
		var dao          = $getPresideObject( "email_template_send_log_activity" );

		if ( ListFindNoCase( "open,bot_open", activityType ) ) {
			newType = isBot ? "bot_open" : "open";
		} else if ( ListFindNoCase( "click,bot_click", activityType ) ) {
			newType = isBot ? "bot_click" : "click";
		} else {
			return;
		}

		var newClassification = isBot ? "bot" : "human";
		var updated = dao.updateData(
			  filter       = "id = :id and classification = :classification"
			, filterParams = { id=arguments.activity.id, classification=previous }
			, data         = {
				  activity_type  = newType
				, classification = newClassification
				, bot_score      = Val( arguments.score.score ?: 0 )
				, bot_signals    = ArrayToList( arguments.score.signals ?: [], "," )
			}
		);

		if ( !updated || newClassification == previous ) {
			return;
		}

		if ( previous == "tentative" && isBot ) {
			_processEventForStatsTables(
				  message  = arguments.activity.message
				, activity = newType
				, data     = _trackingStatData( arguments.activity )
				, hitDate  = arguments.activity.eventDate
			);
		} else if ( previous == "tentative" ) {
			_confirmHumanTracking( arguments.activity, newType );
		} else if ( previous == "human" && isBot ) {
			_reverseHumanTrackingStat( arguments.activity, activityType );
			_processEventForStatsTables(
				  message  = arguments.activity.message
				, activity = newType
				, data     = _trackingStatData( arguments.activity )
				, hitDate  = arguments.activity.eventDate
			);
		} else if ( previous == "bot" && !isBot ) {
			_processEventForStatsTables(
				  message   = arguments.activity.message
				, activity  = activityType
				, data      = _trackingStatData( arguments.activity )
				, hitCount  = -1
				, hitDate   = arguments.activity.eventDate
			);
			_confirmHumanTracking( arguments.activity, newType );
		}
	}

// PRIVATE HELPERS
	private array function _trackingEventsForMessage( required string messageId ) {
		var rows   = $getPresideObject( "email_template_send_log_activity" ).selectData(
			  filter       = "message = :message and activity_type in ( 'open', 'click', 'bot_open', 'bot_click', 'honeypotclick' )"
			, filterParams = { message=arguments.messageId }
		);
		var events = [];

		for ( var row in rows ) {
			events.append( {
				  id             = row.id
				, message        = row.message
				, activityType   = row.activity_type ?: ""
				, userAgent      = row.user_agent ?: ""
				, ipAddress      = row.user_ip ?: ""
				, eventDate      = row.datecreated
				, link           = row.link ?: ""
				, linkTitle      = row.link_title ?: ""
				, linkBody       = row.link_body ?: ""
				, classification = row.classification ?: ""
				, extraData      = _activityExtra( row.extra_data ?: "" )
			} );
		}

		return events;
	}

	private struct function _activityExtra( required string extraData ) {
		if ( !Len( Trim( arguments.extraData ) ) ) {
			return {};
		}

		try {
			var parsed = DeserializeJson( arguments.extraData );
			return IsStruct( parsed ) ? parsed : {};
		} catch ( any e ) {
			return {};
		}
	}

	private any function _sendDateForMessage( required string messageId ) {
		var log = $getPresideObject( "email_template_send_log" ).selectData(
			  id           = arguments.messageId
			, selectFields = [ "sent_date" ]
		);

		return log.recordCount ? ( log.sent_date ?: "" ) : "";
	}

	private boolean function _shouldScoreTrackingEvent( required struct event, required struct settings, required date now, required boolean includeImmature, required boolean volume ) {
		var activityType   = arguments.event.activityType ?: "";
		var classification = arguments.event.classification ?: "";
		var age            = DateDiff( "s", arguments.event.eventDate, arguments.now );
		var reclassify     = arguments.includeImmature || arguments.volume;

		if ( !ListFindNoCase( "open,click,bot_open,bot_click", activityType ) ) {
			return false;
		}

		if ( classification == "tentative" ) {
			return age >= Val( arguments.settings.sweepDelaySeconds ?: 90 ) || arguments.includeImmature || arguments.volume;
		}

		return reclassify && ListFindNoCase( "human,bot", classification ) && age >= 0 && age <= Val( arguments.settings.reclassifyWindowSeconds ?: 1800 );
	}

	private struct function _trackingStatData( required struct activity ) {
		return {
			  link       = arguments.activity.link ?: ""
			, link_title = arguments.activity.linkTitle ?: ""
			, link_body  = arguments.activity.linkBody ?: ""
		};
	}

	private void function _confirmHumanTracking( required struct activity, required string activityType ) {
		if ( arguments.activityType == "open" ) {
			markAsOpened(
				  id           = arguments.activity.message
				, skipActivity = true
				, userAgent    = arguments.activity.userAgent
				, ipAddress    = arguments.activity.ipAddress
				, eventDate    = arguments.activity.eventDate
			);
			return;
		}

		recordClick(
			  id           = arguments.activity.message
			, link         = arguments.activity.link ?: ""
			, linkTitle    = arguments.activity.linkTitle ?: ""
			, linkBody     = arguments.activity.linkBody ?: ""
			, eventDate    = arguments.activity.eventDate
			, userAgent    = arguments.activity.userAgent
			, ipAddress    = arguments.activity.ipAddress
			, skipActivity = true
		);
	}

	private void function _reverseHumanTrackingStat( required struct activity, required string activityType ) {
		var column = arguments.activityType == "open" ? "open_count" : "click_count";

		_decrementSendLogCount( arguments.activity.message, column );
		_processEventForStatsTables(
			  message  = arguments.activity.message
			, activity = arguments.activityType
			, data     = _trackingStatData( arguments.activity )
			, hitCount = -1
			, hitDate  = arguments.activity.eventDate
		);

		if ( !_messageHasActivity( arguments.activity.message, arguments.activityType, arguments.activity.id ) ) {
			_processEventForStatsTables(
				  message  = arguments.activity.message
				, activity = arguments.activityType == "open" ? "unique_open" : "unique_click"
				, hitCount = -1
				, hitDate  = arguments.activity.eventDate
			);
		}
	}

	private boolean function _messageHasActivity( required string messageId, required string activityType, required string exceptId ) {
		return $getPresideObject( "email_template_send_log_activity" ).dataExists(
			  filter       = "message = :message and activity_type = :activity_type and id <> :id"
			, filterParams = { message=arguments.messageId, activity_type=arguments.activityType, id=arguments.exceptId }
		);
	}

	private void function _decrementSendLogCount( required string id, required string column ) {
		var dao     = $getPresideObject( "email_template_send_log" );
		var adapter = dao.getDbAdapter();
		var table   = adapter.escapeEntity( dao.getTableName() );
		var col     = adapter.escapeEntity( arguments.column );
		var idCol   = adapter.escapeEntity( "id" );

		_getSqlRunner().runSql(
			  dsn    = dao.getDsn()
			, sql    = "update #table# set #col# = case when #col# > 0 then #col# - 1 else 0 end where #idCol# = :id"
			, params = [ { name="id", type="cf_sql_varchar", value=arguments.id } ]
		);
	}

	private struct function _getAdditionalDataForRecipientType( required string recipientType, required string recipientId, required struct sendArgs ) {
		var additional           = {};
		var recipientTypeService = _getRecipientTypeService();

		if ( recipientType.len() ) {
			var fkColumn            = recipientTypeService.getRecipientIdLogPropertyForRecipientType( recipientType );
			var additionalSelectors = recipientTypeService.getRecipientAdditionalLogProperties( recipientType );

			if ( fkColumn.len() ) {
				additional[ fkColumn ] = arguments.recipientId
			}
			if ( additionalSelectors.count() ) {
				var fields = [];
				for( var additionalSelector in additionalSelectors ) {
					fields.append( "#additionalSelectors[ additionalSelector ]# as #additionalSelector#" );
				}
				var record = $getPresideObject( recipientTypeService.getFilterObjectForRecipientType( arguments.recipientType ) ).selectData(
					  id           = arguments.recipientId
					, selectFields = fields
					, autoGroupBy  = true
				);
				for( var r in record ) {
					additional.append( r );
				}
			}
		}

		return additional;
	}

	private date function _getNow() {
		return Now(); // abstracting this makes testing easier
	}

	private string function _linkPath( required string link ) {
		var path = ReReplace( arguments.link, "^https?://[^/]+", "" );

		return ListFirst( path, "?" );
	}

	private boolean function _hrefIsHoneyPot( required string href, required string honeyPotPath ) {
		if ( !Len( arguments.honeyPotPath ) ) {
			return false;
		}

		var hrefPath = _linkPath( arguments.href );

		return hrefPath == arguments.honeyPotPath || FindNoCase( arguments.honeyPotPath, hrefPath );
	}

	private void function _recomputeActivityCount( required string activityType, required string countColumn, string templateId="" ) {
		var logDao        = $getPresideObject( "email_template_send_log" );
		var activityDao   = $getPresideObject( "email_template_send_log_activity" );
		var adapter       = logDao.getDbAdapter();
		var adapterName   = ListLast( GetMetaData( adapter ).name, "." );
		var logTable      = adapter.escapeEntity( logDao.getTableName() );
		var activityTable = adapter.escapeEntity( activityDao.getTableName() );
		var countCol      = adapter.escapeEntity( arguments.countColumn );
		var idCol         = adapter.escapeEntity( "id" );
		var messageCol    = adapter.escapeEntity( "message" );
		var typeCol       = adapter.escapeEntity( "activity_type" );
		var templateCol   = adapter.escapeEntity( "email_template" );
		var subQuery      = "select #messageCol# as message, count(1) as n from #activityTable# where #typeCol# = :activity_type group by #messageCol#";
		var templateSql   = Len( arguments.templateId ) ? " where l.#templateCol# = :email_template" : "";
		var sql           = "";

		if ( adapterName == "MsSqlAdapter" ) {
			sql = "update l set l.#countCol# = coalesce( sub.n, 0 ) from #logTable# as l left join ( #subQuery# ) as sub on sub.message = l.#idCol##templateSql#";
		} else if ( adapterName == "PostgreSqlAdapter" ) {
			sql = "update #logTable# as l set #countCol# = ( select count(1) from #activityTable# where #messageCol# = l.#idCol# and #typeCol# = :activity_type )#templateSql#";
		} else {
			sql = "update #logTable# as l left join ( #subQuery# ) as sub on sub.message = l.#idCol# set l.#countCol# = coalesce( sub.n, 0 )#templateSql#";
		}

		var params = [ { name="activity_type", type="cf_sql_varchar", value=arguments.activityType } ];

		if ( Len( arguments.templateId ) ) {
			params.append( { name="email_template", type="cf_sql_varchar", value=arguments.templateId } );
		}

		_getSqlRunner().runSql(
			  dsn    = logDao.getDsn()
			, sql    = sql
			, params = params
		);
	}

	private any function _new( required string className ) {
		return CreateObject( "java", arguments.className, _getLib() );
	}

	private array function _getLib() {
		if ( !_lib.len() ) {
			var libDir = GetDirectoryFromPath( getCurrentTemplatePath() ) & "/lib";
			_lib = DirectoryList( libDir, false, "path", "*.jar" );
		}
		return _lib;
	}

	private array function _getDomainAllowlist() {
		var allowList = $getPresideSetting( "email", "link_checking_allowlist" );

		return ListToArray( Trim( allowList ), " #chr(9)##chr(10)##chr(13)#" );
	}


	private function _getRecordClickSql() {
		if ( !StructKeyExists( variables, "_recordClickSql" ) ) {
			var dao = $getPresideObject( "email_template_send_log" );
			var adapter = dao.getDbAdapter();
			var tableName = adapter.escapeEntity( dao.getTableName() );
			var countCol  = adapter.escapeEntity( "click_count" );
			var idCol = adapter.escapeEntity( "id" );

			variables._recordClickSql = "update #tableName# set #countCol# = #countCol# + 1 where #idCol# = :id";
		}

		return variables._recordClickSql;
	}

	private function _getRecordClickParams( sendLogId ) {
		return [{
			  type = "cf_sql_varchar"
			, value = arguments.sendLogId
			, name = "id"
		}];
	}

	private function _getRecordOpenSql() {
		if ( !StructKeyExists( variables, "_recordOpenSql" ) ) {
			var dao = $getPresideObject( "email_template_send_log" );
			var adapter = dao.getDbAdapter();
			var tableName = adapter.escapeEntity( dao.getTableName() );
			var countCol  = adapter.escapeEntity( "open_count" );
			var idCol = adapter.escapeEntity( "id" );

			variables._recordOpenSql = "update #tableName# set #countCol# = #countCol# + 1 where #idCol# = :id";
		}

		return variables._recordOpenSql;
	}

	private function _getRecordOpenParams( sendLogId ) {
		return [{
			  type = "cf_sql_varchar"
			, value = arguments.sendLogId
			, name = "id"
		}];
	}

	private function _processEventForStatsTables( message, activity, data={}, first, numeric hitCount=1, date hitDate ) {
		if ( !Len( arguments.message ) ) {
			return;
		}

		var ignoredActivities = [ "honeypotclick", "resend" ];
		if ( ArrayFind( ignoredActivities, arguments.activity ) ) {
			return;
		}

		var template = $getPresideObjectService().selectData(
			  objectName   = "email_template_send_log"
			, selectFields = [ "email_template" ]
			, forceJoins   = "inner"
			, filter       = {
				  id                                        = arguments.message
				, "email_template.stats_collection_enabled" = true
			  }
		);

		if ( Len( template.email_template ) ) {
			_getEmailStatsService().recordHit(
				  emailTemplateId = template.email_template
				, hitDate         = ( StructKeyExists( arguments, "hitDate" ) && IsDate( arguments.hitDate ) ) ? arguments.hitDate : Now()
				, hitStat         = _activityToHitStat( arguments.activity )
				, hitCount        = arguments.hitCount
				, first           = arguments.first && arguments.hitCount > 0
				, data            = arguments.data
			);
		}
	}

	private function _activityToHitStat( activity ) {
		switch( arguments.activity ) {
			case "deliver": return "delivery";
			case "markasspam": return "spam";
		}

		return arguments.activity;
	}



// GETTERS AND SETTERS
	private any function _getRecipientTypeService() {
		return _recipientTypeService;
	}
	private void function _setRecipientTypeService( required any recipientTypeService ) {
		_recipientTypeService = arguments.recipientTypeService;
	}

	private any function _getEmailTemplateService() {
		return _emailTemplateService;
	}
	private void function _setEmailTemplateService( required any emailTemplateService ) {
		_emailTemplateService = arguments.emailTemplateService;
	}

	private any function _getEmailBotDetectionService() {
		return _emailBotDetectionService;
	}
	private void function _setEmailBotDetectionService( required any emailBotDetectionService ) {
		_emailBotDetectionService = arguments.emailBotDetectionService;
	}

	private any function _getSqlRunner() {
		return _sqlRunner;
	}
	private void function _setSqlRunner( required any sqlRunner ) {
		_sqlRunner = arguments.sqlRunner;
	}

	private any function _getEmailStatsService() {
		return _emailStatsService;
	}
	private void function _setEmailStatsService( required any emailStatsService ) {
		_emailStatsService = arguments.emailStatsService;
	}

}
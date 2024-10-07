/**
 * Provides business logic for detecting bots
 * in email opens and clicks
 *
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 * @feature        emailCenter
 */
component displayname="Email Bot Detection Service" {

	property name="botDetectionSettings" inject="coldbox:setting:email.botDetection";

	public function init() {
		return this;
	}

	/**
	 * Decides whether or not the given data represents a bot event.
	 *
	 * @autodoc   true
	 * @messageId ID of the email send log to which the event belongs
	 * @userAgent User agent string used in the event request
	 * @ipAddress Client IP of the event request
	 * @eventData Date the event happened
	 */
	public boolean function isBot( messageId, userAgent, ipAddress, eventDate ) {
		var interceptData = StructCopy( arguments );

		StructAppend( interceptData, {
			  isBotAgent      = isBotAgent( arguments.userAgent )
			, matchesHoneyPot = matchesHoneyPot( argumentCollection=arguments )
			, tooManyClicks   = tooManyClicksInShortPeriod( argumentCollection=arguments )
		} );

		// our default answer
		interceptData.isBot = ( interceptData.isBotAgent || interceptData.matchesHoneyPot || interceptData.tooManyClicks );

		// allow custom code to extend bot detection given information
		// above and potentially change the decision
		$announceInterception( "onDetectEmailEventBot", interceptData );

		return interceptData.isBot;
	}

	/**
	 * Decides whether or not the given user agent highly likely to be a bot
	 *
	 * @autodoc   true
	 * @userAgent User agent string used in the event request
	 */
	public boolean function isBotAgent( userAgent ) {
		if ( !Len( Trim( arguments.userAgent ) ) ) {
			return true;
		}
		for( var agentPattern in getBotDetectionSettings().userAgents ) {
			if ( ReFindNoCase( agentPattern, arguments.userAgent ) ) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Returns true if there is a matching "honeypot" click event
	 * for the given email send log ID that either matches the provided
	 * IP/User agent, or happened within the configured time frame
	 * of the honeypot click event.
	 *
	 * @autodoc   true
	 * @messageId ID of the email send log to which the event belongs
	 * @userAgent User agent string used in the event request
	 * @ipAddress Client IP of the event request
	 * @eventData Date the event happened
	 */
	public boolean function matchesHoneyPot( messageId, userAgent, ipAddress, eventDate ) {
		var timePeriodInHalf = ( getBotDetectionSettings().honeyPotTimezoneSeconds / 2 );
		var filter = "message = :message and activity_type = :activity_type and (
		       user_ip     = :user_ip
		    or user_agent  = :user_agent
		    or datecreated between :startdate and :enddate
		)";
		var params = {
			  message       = arguments.messageId
			, activity_type = "honeypotclick"
			, user_ip       = arguments.ipAddress
			, user_agent    = arguments.userAgent
			, startDate = { type="cf_sql_timestamp", value=DateAdd( "s", -timePeriodInHalf, arguments.eventDate ) }
			, endDate   = { type="cf_sql_timestamp", value=DateAdd( "s",  timePeriodInHalf, arguments.eventDate ) }
		};

		return $getPresideObject( "email_template_send_log_activity" ).dataExists(
			    filter       = filter
			  , filterParams = params
		);
	}

	/**
	 * Returns true if there were more than the configured threshold
	 * of clicks for the same send log in the configured time span
	 *
	 * @autodoc   true
	 * @messageId ID of the email send log to which the event belongs
	 * @eventData Date the event happened
	 */
	public boolean function tooManyClicksInShortPeriod( messageId, eventDate ) {
		/*
			This is a tricky one, set a suitably high threshold here
			to rule out regular human behaviour. Will not work for emails
			with only a few links in.

			This works as we fire event processing to process 1 min after
			event comes in and then keep the adhoc task for a further 1 min
			before deleting so that we can get a sense of multiple activities
			coming in at once
		 */

		var timePeriodInHalf = ( getBotDetectionSettings().tooManyClicksSeconds / 2 );

		return $getPresideObject( "taskmanager_adhoc_task" ).selectData(
			  recordCountOnly = true
			, filter          = "reference = :reference and event = :event and datecreated between :startdate and :enddate"
			, filterParams    = {
				  reference = arguments.messageId
				, event     = "email.tracking.processClickEventWithBotDetection"
				, startDate = { type="cf_sql_timestamp", value=DateAdd( "s", -timePeriodInHalf, arguments.eventDate ) }
				, endDate   = { type="cf_sql_timestamp", value=DateAdd( "s",  timePeriodInHalf, arguments.eventDate ) }
			  }

		) > getBotDetectionSettings().tooManyClicksCount;
	}

	public struct function getBotDetectionSettings() {
		if ( !StructKeyExists( variables, "_botDetectionSettings" ) ) {
			// ensures raw struct of settings we get passed has all the keys we need
			variables._botDetectionSettings = {
				  userAgents              = botDetectionSettings.userAgents              ?: [ "(bot\b|crawler\b|spider\b|80legs|ia_archiver|voyager|curl|wget|wget|python|yahoo! slurp|mediapartners-google)", "Microsoft Outlook", "ms-office", "googleimageproxy", "thunderbird", "healthcheck", "zabbix", "kube-probe" ]
				, tooManyClicksCount      = botDetectionSettings.tooManyClicksCount      ?: 10
				, tooManyClicksSeconds    = botDetectionSettings.tooManyClicksSeconds    ?: 10
				, honeyPotTimezoneSeconds = botDetectionSettings.honeyPotTimezoneSeconds ?: 10
			};
		}

		return variables._botDetectionSettings;
	}
}
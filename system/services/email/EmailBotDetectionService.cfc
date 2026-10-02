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
	public boolean function isBot( messageId, userAgent, ipAddress, eventDate, struct requestMeta={} ) {
		var event = {
			  activityType   = "click"
			, userAgent      = arguments.userAgent ?: ""
			, ipAddress      = arguments.ipAddress ?: ""
			, eventDate      = arguments.eventDate ?: Now()
			, link           = ""
			, extraData      = arguments.requestMeta
			, classification = ""
		};
		var result = scoreTrackingEvent(
			  event          = event
			, messageEvents  = [ event ]
			, sentDate       = ""
		);

		result.messageId        = arguments.messageId ?: "";
		result.isBotAgent       = !Len( Trim( event.userAgent ) ) || _matchesAgentList( event.userAgent, getBotDetectionSettings().userAgents ?: [] );
		result.matchesHoneyPot  = _hasSignal( result.signals, "honeypot_user_agent" ) || _hasSignal( result.signals, "honeypot_request" );
		result.tooManyClicks    = _hasSignal( result.signals, "click_burst" );

		$announceInterception( "onDetectEmailEventBot", result );

		return IsBoolean( result.isBot ?: "" ) && result.isBot;
	}

	/**
	 * Scores one open or click against the other events recorded for its message.
	 * A single medium signal stays under the default threshold. Short-circuits score 100.
	 */
	public struct function scoreTrackingEvent(
		  required struct event
		, required array  messageEvents
		,          any    sentDate = ""
	) {
		var settings = getBotDetectionSettings();
		var signals  = [];
		var score    = 0;
		var high     = Val( settings.weightHigh   ?: 50 );
		var medium   = Val( settings.weightMedium ?: 25 );
		var low      = Val( settings.weightLow    ?: 10 );
		var extra    = IsStruct( arguments.event.extraData ?: "" ) ? arguments.event.extraData : {};
		var tracked  = _trackedEvents( arguments.messageEvents );

		if ( !Len( Trim( arguments.event.userAgent ?: "" ) ) ) {
			return _scoreResult( 100, [ "empty_user_agent" ], settings );
		}

		if ( _isAffirmative( extra.cf_verified_bot ?: "" ) ) {
			return _scoreResult( 100, [ "cf_verified_bot" ], settings );
		}

		if ( _honeypotOnThisRequest( arguments.event, arguments.messageEvents ) ) {
			return _scoreResult( 100, [ "honeypot_request" ], settings );
		}

		if ( _honeypotSharesUserAgent( arguments.event, arguments.messageEvents, Val( settings.honeyPotTimezoneSeconds ?: 10 ) ) ) {
			signals.append( "honeypot_user_agent" );
			score += high;
		}

		if ( _clicksAreBunched( arguments.event, tracked, Val( settings.tooManyClicksCount ?: 10 ), Val( settings.tooManyClicksSeconds ?: 10 ) ) ) {
			signals.append( "click_burst" );
			score += medium;
		}

		if ( isDatacenterIp( arguments.event.ipAddress ?: "" ) ) {
			signals.append( "datacenter_ip" );
			score += medium;
		}

		if ( _cloudflareSaysBot( extra.cf_bot_score ?: "", Val( settings.cfBotScoreMax ?: 30 ) ) ) {
			signals.append( "cf_bot_score" );
			score += high;
		}

		if ( !Len( Trim( extra.accept_language ?: "" ) ) ) {
			signals.append( "missing_accept_language" );
			score += low;
		}

		if ( tracked.len() >= Val( settings.eventCountThreshold ?: 6 ) ) {
			signals.append( "event_count" );
			score += high;
		}

		if ( _distinctLinkCount( tracked ) >= Val( settings.distinctLinkThreshold ?: 5 ) ) {
			signals.append( "distinct_links" );
			score += high;
		}

		if ( _ipFanoutCounts( arguments.event, tracked, Val( settings.ipFanoutThreshold ?: 2 ), Val( settings.eventCountThreshold ?: 6 ) ) ) {
			signals.append( "ip_fanout" );
			score += medium;
		}

		if ( _isGatewayScan( arguments.event, arguments.sentDate, Val( settings.gatewaySeconds ?: 5 ) ) ) {
			signals.append( "seconds_since_send" );
			score += medium;
		}

		if ( _matchesAgentList( arguments.event.userAgent ?: "", settings.userAgents ?: [] ) || _matchesAgentList( arguments.event.userAgent ?: "", settings.scannerUserAgents ?: [] ) ) {
			signals.append( "scanner_user_agent" );
			score += high;
		}

		return _scoreResult( Min( score, 100 ), signals, settings );
	}

	public boolean function isDatacenterIp( required string ipAddress ) {
		var ip = Trim( arguments.ipAddress );

		if ( !Len( ip ) ) {
			return false;
		}

		for ( var cidr in _getDatacenterCidrs() ) {
			if ( _ipv4InCidr( ip, cidr ) ) {
				return true;
			}
		}

		return false;
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
		for ( var agentPattern in getBotDetectionSettings().userAgents ) {
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
		var filter = "message = :message and activity_type = :activity_type and datecreated between :startdate and :enddate and (
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

	public struct function getBotDetectionSettings() {
		var configured = IsStruct( botDetectionSettings ) ? botDetectionSettings : {};
		var saved      = {};
		var settings   = _defaultBotDetectionSettings( configured );

		try {
			saved = $getPresideCategorySettings( "email" );
		} catch ( any e ) {
			saved = {};
		}

		if ( !IsStruct( saved ) ) {
			saved = {};
		}

		_applySavedNumeric( settings, saved, "bot_score_threshold", "scoreThreshold" );
		_applySavedNumeric( settings, saved, "bot_weight_high", "weightHigh" );
		_applySavedNumeric( settings, saved, "bot_weight_medium", "weightMedium" );
		_applySavedNumeric( settings, saved, "bot_weight_low", "weightLow" );
		_applySavedNumeric( settings, saved, "bot_sweep_delay_seconds", "sweepDelaySeconds" );
		_applySavedNumeric( settings, saved, "bot_reclassify_window_seconds", "reclassifyWindowSeconds" );
		_applySavedNumeric( settings, saved, "bot_event_count_threshold", "eventCountThreshold" );
		_applySavedNumeric( settings, saved, "bot_distinct_link_threshold", "distinctLinkThreshold" );
		_applySavedNumeric( settings, saved, "bot_click_burst_count", "tooManyClicksCount" );
		_applySavedNumeric( settings, saved, "bot_click_burst_seconds", "tooManyClicksSeconds" );
		_applySavedNumeric( settings, saved, "bot_honeypot_window_seconds", "honeyPotTimezoneSeconds" );
		_applySavedNumeric( settings, saved, "bot_gateway_seconds", "gatewaySeconds" );

		var savedScanners = Trim( saved.bot_scanner_user_agents ?: "" );
		if ( Len( savedScanners ) ) {
			settings.scannerUserAgents = _patternsFromText( savedScanners );
		}

		return settings;
	}

// PRIVATE HELPERS
	private struct function _defaultBotDetectionSettings( required struct configured ) {
		return {
			  userAgents              = arguments.configured.userAgents              ?: [ "(bot\b|crawler\b|spider\b|80legs|ia_archiver|voyager|curl|wget|wget|python|yahoo! slurp|mediapartners-google)", "healthcheck", "zabbix", "kube-probe" ]
			, scannerUserAgents       = arguments.configured.scannerUserAgents       ?: [ "proofpoint", "mimecast", "barracuda", "safelinks", "antispam-agent", "skypeuripreview", "^mozilla/5\.0$" ]
			, tooManyClicksCount      = arguments.configured.tooManyClicksCount      ?: 10
			, tooManyClicksSeconds    = arguments.configured.tooManyClicksSeconds    ?: 10
			, honeyPotTimezoneSeconds = arguments.configured.honeyPotTimezoneSeconds ?: 10
			, scoreThreshold          = arguments.configured.scoreThreshold          ?: 50
			, weightHigh              = arguments.configured.weightHigh              ?: 50
			, weightMedium            = arguments.configured.weightMedium            ?: 25
			, weightLow               = arguments.configured.weightLow               ?: 10
			, sweepDelaySeconds       = arguments.configured.sweepDelaySeconds       ?: 90
			, reclassifyWindowSeconds = arguments.configured.reclassifyWindowSeconds ?: 1800
			, eventCountThreshold     = arguments.configured.eventCountThreshold     ?: 6
			, distinctLinkThreshold   = arguments.configured.distinctLinkThreshold   ?: 5
			, gatewaySeconds          = arguments.configured.gatewaySeconds          ?: 5
			, cfBotScoreMax           = arguments.configured.cfBotScoreMax           ?: 30
			, ipFanoutThreshold       = arguments.configured.ipFanoutThreshold       ?: 2
		};
	}

	private void function _applySavedNumeric( required struct settings, required struct saved, required string savedKey, required string settingKey ) {
		var raw = Trim( arguments.saved[ arguments.savedKey ] ?: "" );

		if ( Len( raw ) && IsNumeric( raw ) ) {
			arguments.settings[ arguments.settingKey ] = Val( raw );
		}
	}

	private array function _patternsFromText( required string patterns ) {
		var parsed = [];

		for ( var pattern in ListToArray( arguments.patterns, Chr( 10 ) ) ) {
			pattern = Trim( pattern );
			if ( Len( pattern ) ) {
				parsed.append( pattern );
			}
		}

		return parsed;
	}

	private struct function _scoreResult( required numeric score, required array signals, required struct settings ) {
		return {
			  score     = arguments.score
			, signals   = arguments.signals
			, isBot     = arguments.score >= Val( arguments.settings.scoreThreshold ?: 50 )
			, threshold = Val( arguments.settings.scoreThreshold ?: 50 )
		};
	}

	private boolean function _hasSignal( required array signals, required string name ) {
		return arguments.signals.findNoCase( arguments.name ) > 0;
	}

	private boolean function _isAffirmative( required string value ) {
		return ListFindNoCase( "1,true,yes", Trim( arguments.value ) ) > 0;
	}

	private array function _trackedEvents( required array messageEvents ) {
		var tracked = [];
		var counted = [ "open", "click", "bot_open", "bot_click" ];

		for ( var event in arguments.messageEvents ) {
			if ( counted.findNoCase( event.activityType ?: "" ) ) {
				tracked.append( event );
			}
		}

		return tracked;
	}

	private boolean function _honeypotOnThisRequest( required struct event, required array messageEvents ) {
		for ( var candidate in arguments.messageEvents ) {
			if ( ( candidate.activityType ?: "" ) == "honeypotclick" && Abs( DateDiff( "s", candidate.eventDate, arguments.event.eventDate ) ) <= 2 ) {
				return true;
			}
		}

		return false;
	}

	private boolean function _honeypotSharesUserAgent( required struct event, required array messageEvents, required numeric windowSeconds ) {
		var userAgent = Trim( arguments.event.userAgent ?: "" );
		var half      = arguments.windowSeconds / 2;

		if ( !Len( userAgent ) ) {
			return false;
		}

		for ( var candidate in arguments.messageEvents ) {
			if ( ( candidate.activityType ?: "" ) == "honeypotclick" && Trim( candidate.userAgent ?: "" ) == userAgent && Abs( DateDiff( "s", candidate.eventDate, arguments.event.eventDate ) ) <= half ) {
				return true;
			}
		}

		return false;
	}

	private boolean function _clicksAreBunched( required struct event, required array tracked, required numeric threshold, required numeric windowSeconds ) {
		var half  = arguments.windowSeconds / 2;
		var count = 0;

		for ( var candidate in arguments.tracked ) {
			if ( ListFindNoCase( "click,bot_click", candidate.activityType ?: "" ) && Abs( DateDiff( "s", candidate.eventDate, arguments.event.eventDate ) ) <= half ) {
				count++;
			}
		}

		return count > arguments.threshold;
	}

	private boolean function _cloudflareSaysBot( required string headerValue, required numeric maximum ) {
		var raw = Trim( arguments.headerValue );

		if ( !Len( raw ) || !IsNumeric( raw ) ) {
			return false;
		}

		return Val( raw ) > 0 && Val( raw ) <= arguments.maximum;
	}

	private numeric function _distinctLinkCount( required array tracked ) {
		var links = {};

		for ( var event in arguments.tracked ) {
			var link = Trim( event.link ?: "" );
			if ( Len( link ) && ListFindNoCase( "click,bot_click", event.activityType ?: "" ) ) {
				links[ link ] = true;
			}
		}

		return StructCount( links );
	}

	private boolean function _ipFanoutCounts( required struct event, required array tracked, required numeric ipThreshold, required numeric volumeThreshold ) {
		var ips    = {};
		var uaIps  = {};
		var shared = false;

		for ( var candidate in arguments.tracked ) {
			var ip = Trim( candidate.ipAddress ?: "" );
			var ua = Trim( candidate.userAgent ?: "" );

			if ( Len( ip ) ) {
				ips[ ip ] = true;
			}
			if ( Len( ua ) && Len( ip ) ) {
				if ( !StructKeyExists( uaIps, ua ) ) {
					uaIps[ ua ] = {};
				}
				uaIps[ ua ][ ip ] = true;
			}
		}

		for ( var ua in uaIps ) {
			if ( StructCount( uaIps[ ua ] ) >= arguments.ipThreshold ) {
				shared = true;
			}
		}

		return StructCount( ips ) >= arguments.ipThreshold && ( shared || arguments.tracked.len() >= arguments.volumeThreshold );
	}

	private boolean function _isGatewayScan( required struct event, any sentDate, required numeric gatewaySeconds ) {
		if ( !IsDate( arguments.sentDate ) || !IsDate( arguments.event.eventDate ?: "" ) ) {
			return false;
		}

		var elapsed = DateDiff( "s", arguments.sentDate, arguments.event.eventDate );

		return elapsed >= 0 && elapsed <= arguments.gatewaySeconds;
	}

	private boolean function _matchesAgentList( required string userAgent, required array patterns ) {
		for ( var pattern in arguments.patterns ) {
			if ( Len( pattern ) && ReFindNoCase( pattern, arguments.userAgent ) ) {
				return true;
			}
		}

		return false;
	}

	private array function _getDatacenterCidrs() {
		if ( !StructKeyExists( variables, "_datacenterCidrs" ) ) {
			var path = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "../../assets/email/datacenterCidrs.txt";
			var cidrs = [];

			if ( FileExists( path ) ) {
				for ( var line in ListToArray( FileRead( path ), Chr( 10 ) ) ) {
					line = Trim( line );
					if ( Len( line ) && Left( line, 1 ) != "##" ) {
						ArrayAppend( cidrs, line );
					}
				}
			}

			variables._datacenterCidrs = cidrs;
		}

		return variables._datacenterCidrs;
	}

	private boolean function _ipv4InCidr( required string ipAddress, required string cidr ) {
		var ipParts    = ListToArray( arguments.ipAddress, "." );
		var range      = ListFirst( arguments.cidr, "/" );
		var bits       = Val( ListLen( arguments.cidr, "/" ) == 2 ? ListLast( arguments.cidr, "/" ) : 32 );
		var rangeParts = ListToArray( range, "." );
		var fullOctets = Int( bits / 8 );
		var remainder  = bits mod 8;
		var mask       = 0;
		var bit        = 128;
		var i          = 0;

		if ( ArrayLen( ipParts ) != 4 || ArrayLen( rangeParts ) != 4 || bits < 0 || bits > 32 ) {
			return false;
		}

		for ( i = 1; i <= fullOctets; i++ ) {
			if ( !_isOctet( ipParts[ i ] ) || !_isOctet( rangeParts[ i ] ) || Val( ipParts[ i ] ) != Val( rangeParts[ i ] ) ) {
				return false;
			}
		}

		if ( !remainder || fullOctets >= 4 ) {
			return true;
		}

		if ( !_isOctet( ipParts[ fullOctets + 1 ] ) || !_isOctet( rangeParts[ fullOctets + 1 ] ) ) {
			return false;
		}

		for ( i = 1; i <= remainder; i++ ) {
			mask += bit;
			bit = bit / 2;
		}

		return BitAnd( Val( ipParts[ fullOctets + 1 ] ), mask ) == BitAnd( Val( rangeParts[ fullOctets + 1 ] ), mask );
	}

	private boolean function _isOctet( required string value ) {
		return ReFind( "^\d{1,3}$", arguments.value ) && Val( arguments.value ) >= 0 && Val( arguments.value ) <= 255;
	}

}

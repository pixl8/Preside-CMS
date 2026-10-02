component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "isBotAgent()", function(){
			it( "should return true if the supplied user agent is empty", function(){
				var svc = _getService();

				expect( svc.isBotAgent( "" ) ).toBe( true );
			} );
			it( "should return true if ANY of the configured user agent regex expressions matches the supplied user agent", function(){
				var svc = _getService();

				expect( svc.isBotAgent( "python 3.1" ) ).toBe( true );
				expect( svc.isBotAgent( "curl1.2" ) ).toBe( true );
				expect( svc.isBotAgent( "somecoolbot 2.3" ) ).toBe( true );

			} );
			it( "should return false if the supplied user agent is non-empty and does not match any of the configured bot detection agents", function(){
				var svc = _getService();
				expect( svc.isBotAgent( "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0 " ) ).toBe( false );
			} );
			it( "should not classify mail clients that fetch images for a human reader as bots", function(){
				var svc = _getService();

				expect( svc.isBotAgent( "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Microsoft Outlook 16.0" ) ).toBe( false );
				expect( svc.isBotAgent( "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Thunderbird/102.0" ) ).toBe( false );
				expect( svc.isBotAgent( "Mozilla/5.0 (Windows NT 5.1; rv:11.0) Gecko Firefox/11.0 (via ggpht.com GoogleImageProxy)" ) ).toBe( false );
				expect( svc.isBotAgent( "Mozilla/4.0 (compatible; ms-office; MSOffice 16)" ) ).toBe( false );
			} );
		} );

		describe( "matchesHoneyPot()", function(){
			it( "should return true if the request belongs to a message that had a recent honey pot click or matches IP or user agent of recent honey pot click activity", function(){
				var svc                = _getService();
				var mockLogActivityDao = createStub();
				var messageId          = CreateUUId();
				var ipAddress          = CreateUUId();
				var userAgent          = CreateUUId();
				var eventDate          = Now();
				var args               = {};

				args.filter = "message = :message and activity_type = :activity_type and datecreated between :startdate and :enddate and (
		       user_ip     = :user_ip
		    or user_agent  = :user_agent
		    or datecreated between :startdate and :enddate
		)";
				args.filterParams = {
					  message       = messageId
					, activity_type = "honeypotclick"
					, user_ip       = ipAddress
					, user_agent    = userAgent
					, startDate = { type="cf_sql_timestamp", value=DateAdd( "s", -5, eventDate ) }
					, endDate   = { type="cf_sql_timestamp", value=DateAdd( "s",  5, eventDate ) }
				};

				svc.$( "$getPresideObject" ).$args( "email_template_send_log_activity" ).$results( mockLogActivityDao )
				mockLogActivityDao.$( "dataExists" ).$args( argumentCollection=args ).$results( true );

				expect( svc.matchesHoneyPot(
					  messageId = messageId
					, ipAddress = ipAddress
					, userAgent = userAgent
					, eventDate = eventDate
				) ).toBe( true );

			} );

			it( "should return false if no matching honeypot activity found", function(){
				var svc                = _getService();
				var mockLogActivityDao = createStub();
				var messageId          = CreateUUId();
				var ipAddress          = CreateUUId();
				var userAgent          = CreateUUId();
				var eventDate          = Now();
				var args               = {};

				args.filter = "message = :message and activity_type = :activity_type and datecreated between :startdate and :enddate and (
		       user_ip     = :user_ip
		    or user_agent  = :user_agent
		    or datecreated between :startdate and :enddate
		)";
				args.filterParams = {
					  message       = messageId
					, activity_type = "honeypotclick"
					, user_ip       = ipAddress
					, user_agent    = userAgent
					, startDate = { type="cf_sql_timestamp", value=DateAdd( "s", -5, eventDate ) }
					, endDate   = { type="cf_sql_timestamp", value=DateAdd( "s",  5, eventDate ) }
				};

				svc.$( "$getPresideObject" ).$args( "email_template_send_log_activity" ).$results( mockLogActivityDao )
				mockLogActivityDao.$( "dataExists" ).$args( argumentCollection=args ).$results( false );

				expect( svc.matchesHoneyPot(
					  messageId = messageId
					, ipAddress = ipAddress
					, userAgent = userAgent
					, eventDate = eventDate
				) ).toBe( false );

			} );
		} );

		describe( "scoreTrackingEvent()", function(){
			it( "should stay under the threshold for a single medium signal", function(){
				var svc       = _getService();
				var eventDate = Now();
				var event     = _trackedEvent( eventDate, "198.51.100.10", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" );

				event.ipAddress = "203.0.113.10";

				var result = svc.scoreTrackingEvent(
					  event         = event
					, messageEvents = [ event ]
					, sentDate      = DateAdd( "h", -2, eventDate )
				);

				expect( result.isBot ).toBe( false );
				expect( result.signals ).toBe( [ "datacenter_ip" ] );
				expect( result.score ).toBe( 25 );
			} );

			it( "should cross the threshold when medium signals combine", function(){
				var svc       = _getService();
				var eventDate = Now();
				var event     = _trackedEvent( eventDate, "203.0.113.10", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" );
				var result    = svc.scoreTrackingEvent(
					  event         = event
					, messageEvents = [ event ]
					, sentDate      = eventDate
				);

				expect( result.isBot ).toBe( true );
				expect( result.signals ).toInclude( "datacenter_ip" );
				expect( result.signals ).toInclude( "seconds_since_send" );
			} );

			it( "should treat a honeypot hit with the same user agent as a bot", function(){
				var svc       = _getService();
				var eventDate = Now();
				var click     = _trackedEvent( eventDate, "198.51.100.10", "SameAgent" );
				var honeypot  = _trackedEvent( DateAdd( "s", -3, eventDate ), "203.0.113.20", "SameAgent" );

				honeypot.activityType = "honeypotclick";

				var result = svc.scoreTrackingEvent(
					  event         = click
					, messageEvents = [ click, honeypot ]
					, sentDate      = DateAdd( "h", -2, eventDate )
				);

				expect( result.isBot ).toBe( true );
				expect( result.signals ).toInclude( "honeypot_user_agent" );
			} );

			it( "should classify a message with many events and no honeypot hit", function(){
				var svc       = _getService();
				var eventDate = Now();
				var events    = [];
				var i         = 1;

				for ( i = 1; i <= 6; i++ ) {
					events.append( _trackedEvent( DateAdd( "n", i, eventDate ), "198.51.100.10", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36", "https://example.com/news" ) );
				}

				var result = svc.scoreTrackingEvent(
					  event         = events[ 1 ]
					, messageEvents = events
					, sentDate      = DateAdd( "h", -2, eventDate )
				);

				expect( result.isBot ).toBe( true );
				expect( result.signals ).toInclude( "event_count" );
				expect( result.signals ).notToInclude( "honeypot_user_agent" );
			} );

			it( "should not classify two opens from different devices as a bot", function(){
				var svc       = _getService();
				var eventDate = Now();
				var phone     = _trackedEvent( eventDate, "198.51.100.10", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1" );
				var laptop    = _trackedEvent( DateAdd( "n", 1, eventDate ), "198.51.100.11", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" );

				phone.activityType  = "open";
				laptop.activityType = "open";

				var result = svc.scoreTrackingEvent(
					  event         = laptop
					, messageEvents = [ phone, laptop ]
					, sentDate      = DateAdd( "h", -2, eventDate )
				);

				expect( result.isBot ).toBe( false );
				expect( result.signals ).notToInclude( "ip_fanout" );
			} );
		} );

		describe( "isBot()", function(){
			it( "should raise an interception point and allow custom code to override the result", function(){
				var svc = _getService();

				svc.$( method="$announceInterception", callback=function( ev, data ){
					if ( arguments.ev == "onDetectEmailEventBot" ) {
						arguments.data.isBot = false;
					}
				} );

				expect( svc.isBot(
					  messageId   = CreateUUId()
					, ipAddress   = "203.0.113.10"
					, userAgent   = ""
					, eventDate   = Now()
					, requestMeta = { accept_language="en" }
				) ).toBe( false );
			} );
		} );

		describe( "getBotDetectionSettings()", function(){
			it( "should use saved email settings when they are present", function(){
				var svc = createMock( object=new preside.system.services.email.EmailBotDetectionService() );

				svc.$property( propertyName="botDetectionSettings", mock={
					  scoreThreshold = 50
					, weightHigh     = 50
					, weightMedium   = 25
				} );
				svc.$( "$getPresideCategorySettings" ).$args( "email" ).$results( {
					  bot_score_threshold      = 70
					, bot_weight_medium        = 30
					, bot_scanner_user_agents  = "Proofpoint"
				} );

				var settings = svc.getBotDetectionSettings();

				expect( settings.scoreThreshold ).toBe( 70 );
				expect( settings.weightMedium ).toBe( 30 );
				expect( settings.weightHigh ).toBe( 50 );
				expect( settings.scannerUserAgents ).toBe( [ "Proofpoint" ] );
			} );
		} );
	}

	private any function _getService(){
		var svc = createMock( object=new preside.system.services.email.EmailBotDetectionService() );

		variables.botDetectionSettings = {
			  userAgents              = [ "(bot\b|crawler\b|spider\b|80legs|ia_archiver|voyager|curl|wget|wget|python|yahoo! slurp|mediapartners-google)", "healthcheck", "zabbix", "kube-probe" ]
			, scannerUserAgents       = [ "proofpoint", "mimecast", "barracuda", "safelinks", "antispam-agent", "skypeuripreview", "^mozilla/5\.0$" ]
			, tooManyClicksCount      = 10
			, tooManyClicksSeconds    = 10
			, honeyPotTimezoneSeconds = 10
			, scoreThreshold          = 50
			, weightHigh              = 50
			, weightMedium            = 25
			, weightLow               = 10
			, eventCountThreshold     = 6
			, distinctLinkThreshold   = 5
			, gatewaySeconds          = 5
			, cfBotScoreMax           = 30
			, ipFanoutThreshold       = 2
		};

		svc.$( "getBotDetectionSettings", botDetectionSettings );
		svc.$( "$announceInterception" );

		return svc;
	}

	private struct function _trackedEvent( required date eventDate, required string ipAddress, required string userAgent, string link="" ) {
		return {
			  activityType   = "click"
			, userAgent      = arguments.userAgent
			, ipAddress      = arguments.ipAddress
			, eventDate      = arguments.eventDate
			, link           = arguments.link
			, classification = "tentative"
			, extraData      = { accept_language="en", cf_bot_score="", cf_verified_bot="" }
		};
	}

}
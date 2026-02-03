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

				args.filter = "message = :message and activity_type = :activity_type and (
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

				args.filter = "message = :message and activity_type = :activity_type and (
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

		describe( "tooManyClicksInShortPeriod()", function(){
			it( "should return true if there more than the configured threshold of clicks in the given time period around the given event", function(){
				var svc         = _getService();
				var mockTaskDao = createStub();
				var messageId   = CreateUUId();
				var eventDate   = Now();
				var args        = {};

				args.recordcount = true
				args.filter = "reference = :reference and event = :event and datecreated between :startdate and :enddate";
				args.filterParams = {
					  reference = messageId
					, event     = "email.tracking.processClickEventWithBotDetection"
					, startDate = { type="cf_sql_timestamp", value=DateAdd( "s", -5, eventDate ) }
					, endDate   = { type="cf_sql_timestamp", value=DateAdd( "s",  5, eventDate ) }
				}

				svc.$( "$getPresideObject" ).$args( "taskmanager_adhoc_task" ).$results( mockTaskDao )
				mockTaskDao.$( "selectData" ).$args( argumentCollection=args ).$results( 20 );

				expect( svc.tooManyClicksInShortPeriod(
					  messageId = messageId
					, eventDate = eventDate
				) ).toBe( true );

			} );

			it( "should return false if there are less than the configured threshold of clicks in the given time period around the given event", function(){
				var svc         = _getService();
				var mockTaskDao = createStub();
				var messageId   = CreateUUId();
				var eventDate   = Now();
				var args        = {};

				args.recordcount = true
				args.filter = "reference = :reference and event = :event and datecreated between :startdate and :enddate";
				args.filterParams = {
					  reference = messageId
					, event     = "email.tracking.processClickEventWithBotDetection"
					, startDate = { type="cf_sql_timestamp", value=DateAdd( "s", -5, eventDate ) }
					, endDate   = { type="cf_sql_timestamp", value=DateAdd( "s",  5, eventDate ) }
				}

				svc.$( "$getPresideObject" ).$args( "taskmanager_adhoc_task" ).$results( mockTaskDao )
				mockTaskDao.$( "selectData" ).$args( argumentCollection=args ).$results( 5 );

				expect( svc.tooManyClicksInShortPeriod(
					  messageId = messageId
					, eventDate = eventDate
				) ).toBe( false );
			} );
		} );

		describe( "isBot()", function(){
			it( "should return false if ALL of the bot detection subroutines return false", function(){
				var svc = _getService();
				var args = {
					  messageId = CreateUUId()
					, ipAddress = CreateUUId()
					, userAgent = CreateUUId()
					, eventDate = Now()
				};

				svc.$( "isBotAgent" ).$args( args.userAgent ).$results( false );
				svc.$( "matchesHoneyPot" ).$args( argumentCollection=args ).$results( false );
				svc.$( "tooManyClicksInShortPeriod" ).$args( argumentCollection=args ).$results( false );

				expect( svc.isBot( argumentCollection=args ) ).toBe( false );
			} );

			it( "should return true if ANY of the bot detection subroutines return true", function(){
				var svc = _getService();
				var args = {
					  messageId = CreateUUId()
					, ipAddress = CreateUUId()
					, userAgent = CreateUUId()
					, eventDate = Now()
				};

				svc.$( "isBotAgent" ).$args( args.userAgent ).$results( true );
				svc.$( "matchesHoneyPot" ).$args( argumentCollection=args ).$results( false );
				svc.$( "tooManyClicksInShortPeriod" ).$args( argumentCollection=args ).$results( false );

				expect( svc.isBot( argumentCollection=args ) ).toBe( true );

				svc.$( "isBotAgent" ).$args( args.userAgent ).$results( false );
				svc.$( "matchesHoneyPot" ).$args( argumentCollection=args ).$results( true );
				svc.$( "tooManyClicksInShortPeriod" ).$args( argumentCollection=args ).$results( false );

				expect( svc.isBot( argumentCollection=args ) ).toBe( true );

				svc.$( "isBotAgent" ).$args( args.userAgent ).$results( false );
				svc.$( "matchesHoneyPot" ).$args( argumentCollection=args ).$results( false );
				svc.$( "tooManyClicksInShortPeriod" ).$args( argumentCollection=args ).$results( true );

				expect( svc.isBot( argumentCollection=args ) ).toBe( true );

				svc.$( "isBotAgent" ).$args( args.userAgent ).$results( true );
				svc.$( "matchesHoneyPot" ).$args( argumentCollection=args ).$results( true );
				svc.$( "tooManyClicksInShortPeriod" ).$args( argumentCollection=args ).$results( true );

				expect( svc.isBot( argumentCollection=args ) ).toBe( true );
			} );

			it( "should raise an interception point and allow custom code to override the result", function(){
				var svc = _getService();
				var args = {
					  messageId = CreateUUId()
					, ipAddress = CreateUUId()
					, userAgent = CreateUUId()
					, eventDate = Now()
				};

				svc.$( "isBotAgent" ).$args( args.userAgent ).$results( false );
				svc.$( "matchesHoneyPot" ).$args( argumentCollection=args ).$results( true );
				svc.$( "tooManyClicksInShortPeriod" ).$args( argumentCollection=args ).$results( false );

				svc.$( method="$announceInterception", callback=function( ev, data ){
					if ( arguments.ev == "onDetectEmailEventBot" ) {
						if ( !arguments.data.isBotAgent && arguments.data.matchesHoneyPot && !arguments.data.tooManyClicks ) {
							arguments.data.isBot = false;
						}
					}
				} );

				expect( svc.isBot( argumentCollection=args ) ).toBe( false );
			} );
		} );
	}

	private any function _getService(){
		var svc = createMock( object=new preside.system.services.email.EmailBotDetectionService() );

		variables.botDetectionSettings = {
			  userAgents              = [ "(bot\b|crawler\b|spider\b|80legs|ia_archiver|voyager|curl|wget|wget|python|yahoo! slurp|mediapartners-google)", "Microsoft Outlook", "ms-office", "googleimageproxy", "thunderbird", "healthcheck", "zabbix", "kube-probe" ]
			, tooManyClicksCount      = 10
			, tooManyClicksSeconds    = 10
			, honeyPotTimezoneSeconds = 10
		};

		svc.$( "getBotDetectionSettings", botDetectionSettings );
		svc.$( "$announceInterception" );

		return svc;
	}

}
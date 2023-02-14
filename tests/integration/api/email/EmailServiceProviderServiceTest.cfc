component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "listProviders()", function(){
			it( "should return a list of configured service providers, with translated titles, descriptions and icons", function(){
				var service = _getService();
				var providers = _getDefaultTestProviders();
				var expected  = [];

				for( var providerId in providers ) {
					var provider = {
						  id          = providerId
						, title       = providerId & CreateUUId()
						, description = providerId & CreateUUId()
						, iconClass   = providerId & CreateUUId()
					};

					expected.append( provider );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:title"      , defaultValue=providerId ).$results( provider.title       );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:description", defaultValue=""         ).$results( provider.description );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:iconClass"  , defaultValue=""         ).$results( provider.iconClass   );
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );


				expect( service.listProviders() ).toBe( expected );
			} );

			it( "should exclude services when they have been disabled through preside system settings", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var expected  = [];
				var excluded  = "mailgun,smtp";

				service.$( "$getPresideSetting" ).$args( "email", "disabledProviders" ).$results( excluded );

				for( var providerId in providers ) {
					if ( ListFindNoCase( excluded, providerId ) ) {
						continue;
					}

					var provider = {
						  id          = providerId
						, title       = providerId & CreateUUId()
						, description = providerId & CreateUUId()
						, iconClass   = providerId & CreateUUId()
					};

					expected.append( provider );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:title"      , defaultValue=providerId ).$results( provider.title       );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:description", defaultValue=""         ).$results( provider.description );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:iconClass"  , defaultValue=""         ).$results( provider.iconClass   );
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );


				expect( service.listProviders() ).toBe( expected ); ;
			} );

			it( "should not exclude services when they have been disabled through preside system settings but includeDisabled is passed as true", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var expected  = [];
				var excluded  = "mailgun,smtp";

				service.$( "$getPresideSetting" ).$args( "email", "disabledProviders" ).$results( excluded );

				for( var providerId in providers ) {
					var provider = {
						  id          = providerId
						, title       = providerId & CreateUUId()
						, description = providerId & CreateUUId()
						, iconClass   = providerId & CreateUUId()
					};

					expected.append( provider );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:title"      , defaultValue=providerId ).$results( provider.title       );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:description", defaultValue=""         ).$results( provider.description );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:iconClass"  , defaultValue=""         ).$results( provider.iconClass   );
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );


				expect( service.listProviders( includeDisabled=true ) ).toBe( expected ); ;
			} );


		} );

		describe( "getProvider()", function(){
			it( "should return the provider with translated title, description and icon class", function(){
				var service    = _getService();
				var providerId = "smtp";
				var provider   = {
					  id          = providerId
					, title       = providerId & CreateUUId()
					, description = providerId & CreateUUId()
					, iconClass   = providerId & CreateUUId()
				};

				service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:title"      , defaultValue=providerId ).$results( provider.title       );
				service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:description", defaultValue=""         ).$results( provider.description );
				service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:iconClass"  , defaultValue=""         ).$results( provider.iconClass   );

				expect( service.getProvider( providerId ) ).toBe( provider );
			} );

			it( "should return an empty struct when the provider is not enabled", function(){
				var service    = _getService();
				var providerId = "smtp";

				service.$( "isProviderEnabled" ).$args( providerId ).$results( false );

				expect( service.getProvider( providerId ) ).toBe( {} );
			} );
		} );

		describe( "getDefaultProvider()", function(){
			it( "should return the configured default provider", function(){
				var service = _getService();
				var defaultProvider = "smtp";

				service.$( "$getPresideSetting" ).$args( "email", "defaultProvider" ).$results( defaultProvider );

				expect( service.getDefaultProvider() ).toBe( defaultProvider );
			} );

			it( "should return the first in the list of providers when no default set in settings", function(){
				var service = _getService();
				var defaultProvider = CreateUUId();

				service.$( "$getPresideSetting" ).$args( "email", "defaultProvider" ).$results( "" );
				service.$( "listProviders", [ { id=defaultProvider } ] )

				expect( service.getDefaultProvider() ).toBe( defaultProvider );
			} );

			it( "should return an empty string when no default configured and no providers listed", function(){
				var service = _getService();

				service.$( "$getPresideSetting" ).$args( "email", "defaultProvider" ).$results( "" );
				service.$( "listProviders", [] )

				expect( service.getDefaultProvider() ).toBe( "" );
			} );
		} );

		describe( "getProviderConfigFormName()", function(){
			it( "should return the configured config form name for the provider", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var provider  = "mailchimp";

				expect( service.getProviderConfigFormName( provider ) ).toBe( providers[ provider ].configForm );
			} );

			it( "should return a convention based form name when no specific form configured", function(){
				var service   = _getService();
				var provider  = "smtp";

				expect( service.getProviderConfigFormName( provider ) ).toBe( "email.serviceProvider.smtp" );
			} );
		} );

		describe( "getProviderSendAction()", function(){
			it( "should return the configured send action for the provider", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var provider  = "mailgun";

				expect( service.getProviderSendAction( provider ) ).toBe( providers[ provider ].sendAction );
			} );

			it( "should return a convention based action when no specific action configured", function(){
				var service   = _getService();
				var provider  = "smtp";

				expect( service.getProviderSendAction( provider ) ).toBe( "email.serviceProvider.smtp.send" );
			} );
		} );

		describe( "getProviderValidateSettingsAction()", function(){
			it( "should return the configured validateSettings action for the provider", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var provider  = "mailgun";

				expect( service.getProviderValidateSettingsAction( provider ) ).toBe( providers[ provider ].validateSettingsAction );
			} );

			it( "should return a convention based action when no specific action configured", function(){
				var service   = _getService();
				var provider  = "smtp";

				expect( service.getProviderValidateSettingsAction( provider ) ).toBe( "email.serviceProvider.smtp.validateSettings" );
			} );
		} );

		describe( "isProviderEnabled()", function(){
			it( "should return false when the provider is in the list of configured disabled providers", function(){
				var service   = _getService();
				var excluded  = "mailgun,smtp";

				service.$( "$getPresideSetting" ).$args( "email", "disabledProviders" ).$results( excluded );

				expect( service.isProviderEnabled( "smtp" ) ).toBe( false );
			} );

			it( "should return false when the provider does not exist", function(){
				var service   = _getService();

				expect( service.isProviderEnabled( CreateUUId() ) ).toBe( false );
			} );

			it( "should return true when the provider is not in the disabled providers list + exists in the configured providers struct", function(){
				var service   = _getService();
				var excluded  = "mailgun,mailchimp";

				service.$( "$getPresideSetting" ).$args( "email", "disabledProviders" ).$results( excluded );

				expect( service.isProviderEnabled( "smtp" ) ).toBe( true );
			} );
		} );

		describe( "sendWithProvider()", function(){
			it( "should call the providers configured send action passing through any passed args and saved provider config and returning the boolean result", function(){
				var service       = _getService();
				var result        = true;
				var providers     = _getDefaultTestProviders();
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummyArgs     = { test=CreateUUId(), fu="bar", messageId=CreateUUId(), htmlBody=dummyHtmlBody };
				var dummySettings = { server=CreateUUId(), fu="bar", password=CreateUUId() };

				service.$( "_logMessage", dummyArgs.messageId );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( dummySettings );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings=dummySettings }
				).$results( result );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( result );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 1 );
				expect( mockColdbox.$callLog().runEvent[ 1 ] ).toBe( {
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings=dummySettings }
				} );
			} );

			it( "should return false when the given send event returns false", function(){
				var service       = _getService();
				var result        = false;
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummyArgs     = { test=CreateUUId(), fu="bar", messageId=CreateUUId(), htmlBody=dummyHtmlBody };
				var dummySettings = { what="ever" };

				service.$( "_logMessage", dummyArgs.messageId );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( dummySettings );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );

				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings=dummySettings  }
				).$results( result );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( result );
			} );

			it( "should return false when the send action throws an error", function(){
				var service   = _getService();
				var result    = false;
				var provider  = "mailgun";
				var sendAction = CreateUUId() & ".send";

				service.$( "_logMessage", CreateUUId() );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( method="runEvent", throwException=true, throwType="blah.blah", throwMessage="Blah blah blah" );
				service.$( "$raiseError" );
				mockEmailLoggingService.$( "markAsFailed" );

				expect( service.sendWithProvider( provider, {} ) ).toBe( false );
				expect( service.$callLog().$raiseError.len() ).toBe( 1 );
				expect( mockEmailLoggingService.$callLog().markAsFailed.len() ).toBe( 1 );
			} );

			it( "should raise an informative error when no send action handler exists", function(){
				var service     = _getService();
				var provider    = "mailgun";
				var sendAction  = CreateUUId() & ".send";
				var errorThrown = false;

				service.$( "_logMessage", CreateUUId() );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "handlerExists" ).$args( sendAction ).$results( false );

				try {
					service.sendWithProvider( provider, {} );
				} catch ( "preside.emailservice.provider.missing.send.action" e ) {
					expect( e.message ).toBe( "The email service provider, [#provider#], has not implemented a send action handler. Missing handler: [#sendAction#]." );
					errorThrown = true;
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should return false and raise a silent error when the send action does not return a boolean value", function(){
				var service   = _getService();
				var provider  = "mailgun";
				var sendAction = CreateUUId() & ".send";
				var dummyArgs = { test=CreateUUId(), fu="bar", messageId=CreateUUId(), htmlBody=dummyHtmlBody };

				service.$( "_logMessage", dummyArgs.messageId );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( {} );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings={} }
				).$results( {} );
				service.$( "$raiseError" );
				mockEmailLoggingService.$( "markAsFailed" );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( false );
				expect( service.$callLog().$raiseError.len() ).toBe( 1 );

				var errorRaised = service.$callLog().$raiseError[ 1 ][ 1 ];

				expect( errorRaised.type    ?: "" ).toBe( "preside.emailservice.provider.invalid.send.action.return.value" );
				expect( errorRaised.message ?: "" ).toBe( "The email service provider send action, [#sendAction#], for the provider, [#provider#], did not return a boolean value to indicate success/failure of email sending." );
				expect( errorRaised.detail  ?: "" ).toBe( "The system has return false to indicate a failure and has logged this error silently as a warning." );
			} );

			it( "should create a log record for the send", function(){
				var service   = _getService();
				var dummyArgs = {
					  to       = [ "somebody@tolove.com" ]
					, from     = "me@me.com"
					, subject  = "blah"
					, htmlBody = dummyHtmlBody
					, textBody = "plain blah"
					, args     = { test=CreateUUId() }
				};
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummySettings = { server=CreateUUId(), fu="bar", password=CreateUUId() };

				var expectedArgs = Duplicate( dummyArgs );

				expectedArgs.messageId = CreateUUId();
				mockEmailLoggingService.$( "createEmailLog" ).$args(
					  template      = ""
					, recipientType = ""
					, recipient     = dummyArgs.to[ 1 ]
					, sender        = dummyArgs.from
					, subject       = dummyArgs.subject
					, sendArgs      = dummyArgs.args
				).$results( expectedArgs.messageId );

				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( dummySettings );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=expectedArgs, settings=dummySettings }
				).$results( true );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( true );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 1 );
				expect( mockColdbox.$callLog().runEvent[ 1 ] ).toBe( {
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=expectedArgs, settings=dummySettings }
				} );

			} );

			it( "should create a log record with sender details for the send", function(){
				var service   = _getService();
				var template  = CreateUUId();
				var dummyArgs = {
					  to       = [ "somebody@tolove.com" ]
					, from     = "me@me.com"
					, subject  = "blah"
					, htmlBody = dummyHtmlBody
					, textBody = "plain blah"
					, args     = { test=CreateUUId(), template=template }
				};
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummySettings = { server=CreateUUId(), fu="bar", password=CreateUUId() };
				var dummyTemplate = { recipient_type=CreateUUId() };
				var expectedArgs  = Duplicate( dummyArgs );

				mockEmailTemplateService.$( "getTemplate" ).$args( template ).$results( dummyTemplate );
				expectedArgs.messageId = CreateUUId();
				mockEmailLoggingService.$( "createEmailLog" ).$args(
					  template      = template
					, recipientType = dummyTemplate.recipient_type
					, recipient     = dummyArgs.to[ 1 ]
					, sender        = dummyArgs.from
					, subject       = dummyArgs.subject
					, sendArgs      = dummyArgs.args
				).$results( expectedArgs.messageId );

				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( dummySettings );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=expectedArgs, settings=dummySettings }
				).$results( true );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( true );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 1 );
				expect( mockColdbox.$callLog().runEvent[ 1 ] ).toBe( {
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=expectedArgs, settings=dummySettings }
				} );

			} );

			it( "should mark email log record as 'sent' when send action returns true", function(){
				var service    = _getService();
				var provider   = "smtp";
				var sendAction = "blah.blah";
				var messageId  = CreateUUId();

				service.$( "_logMessage", messageId );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( {} );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs={ messageId=messageId, htmlBody=dummyHtmlBody }, settings={} }
				).$results( true );

				service.sendWithProvider( provider, { htmlBody=dummyHtmlBody } );

				expect( mockEmailLoggingService.$callLog().markAsSent.len() ).toBe( 1 );
				expect( mockEmailLoggingService.$callLog().markAsSent[ 1 ] ).toBe( [ messageId ] );
			} );

			it( "should insert tracking pixel into html body", function(){
				var service    = _getService();
				var provider   = "smtp";
				var sendAction = "blah.blah";
				var messageId  = CreateUUId();
				var moddedBody = CreateUUId();

				service.$( "_logMessage", messageId );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( {} );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockEmailLoggingService.$( "insertTrackingPixel" ).$args( messageId=messageId, messageHtml=dummyHtmlBody ).$results( moddedBody );
				mockEmailLoggingService.$( "insertClickTrackingLinks" ).$args( messageId=messageId, messageHtml=moddedBody ).$results( moddedBody );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs={ messageId=messageId, htmlBody=moddedBody }, settings={} }
				).$results( true );

				service.sendWithProvider( provider, { htmlBody=dummyHtmlBody } );

				expect( mockEmailLoggingService.$callLog().markAsSent.len() ).toBe( 1 );
				expect( mockEmailLoggingService.$callLog().markAsSent[ 1 ] ).toBe( [ messageId ] );
			} );

			it( "should replace hrefs with tracking link in html body", function(){
				var service    = _getService();
				var provider   = "smtp";
				var sendAction = "blah.blah";
				var messageId  = CreateUUId();
				var moddedBody = CreateUUId();
				var templateId = CreateUUId();

				service.$( "_logMessage", messageId );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( {} );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockEmailTemplateService.$( "isTrackingEnabled" ).$args( templateId ).$results( true );
				mockEmailLoggingService.$( "insertClickTrackingLinks" ).$args( messageId=messageId, messageHtml=dummyHtmlBody ).$results( moddedBody );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs={ messageId=messageId, htmlBody=moddedBody, template=templateId }, settings={} }
				).$results( true );

				service.sendWithProvider( provider, { htmlBody=dummyHtmlBody, template=templateId } );

				expect( mockEmailLoggingService.$callLog().markAsSent.len() ).toBe( 1 );
				expect( mockEmailLoggingService.$callLog().markAsSent[ 1 ] ).toBe( [ messageId ] );
			} );

			it( "should NOT replace hrefs with tracking link in html body when click tracking is not enabled for the template", function(){
				var service    = _getService();
				var provider   = "smtp";
				var sendAction = "blah.blah";
				var messageId  = CreateUUId();
				var moddedBody = CreateUUId();
				var templateId = CreateUUId();

				service.$( "_logMessage", messageId );
				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( {} );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockEmailTemplateService.$( "isTrackingEnabled" ).$args( templateId ).$results( false );
				mockEmailLoggingService.$( "insertClickTrackingLinks" ).$args( messageId=messageId, messageHtml=dummyHtmlBody ).$results( moddedBody );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs={ messageId=messageId, htmlBody=dummyHtmlBody, template=templateId }, settings={} }
				).$results( true );

				service.sendWithProvider( provider, { htmlBody=dummyHtmlBody, template=templateId } );

				expect( mockEmailLoggingService.$callLog().markAsSent.len() ).toBe( 1 );
				expect( mockEmailLoggingService.$callLog().markAsSent[ 1 ] ).toBe( [ messageId ] );
			} );

			it( "should announce pre and post email send interception points", function(){
				var service   = _getService();
				var dummyArgs = {
					  to       = [ "somebody@tolove.com" ]
					, from     = "me@me.com"
					, subject  = "blah"
					, htmlBody = dummyHtmlBody
					, textBody = "plain blah"
					, args     = { test=CreateUUId() }
				};
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummySettings = { server=CreateUUId(), fu="bar", password=CreateUUId() };
				var expectedArgs = Duplicate( dummyArgs );

				expectedArgs.messageId = CreateUUId();
				mockEmailLoggingService.$( "createEmailLog" ).$args(
					  template      = ""
					, recipientType = ""
					, recipient     = dummyArgs.to[ 1 ]
					, sender        = dummyArgs.from
					, subject       = dummyArgs.subject
					, sendArgs      = dummyArgs.args
				).$results( expectedArgs.messageId );

				service.$( "$getPresideCategorySettings" ).$args( category="emailServiceProvider#provider#", provider=provider ).$results( dummySettings );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=expectedArgs, settings=dummySettings }
				).$results( true );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( true );

				expect( service.$callLog().$announceInterception.len() ).toBe( 2 );
				expect( service.$callLog().$announceInterception[ 1 ][ 1 ] ).toBe( "preSendEmail" );
				expect( service.$callLog().$announceInterception[ 2 ][ 1 ] ).toBe( "postSendEmail" );

			} );
		} );

		describe( "saveSettings()", function(){
			it( "should proxy to the preside system configuration service, calculating the category name by convention", function(){
				var service           = _getService();
				var mockConfigService = createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
				var settings          = StructNew( "linked" );
				var site              = CreateUUId();
				var provider          = "mailgun";
				var settingsCategory  = "emailServiceProvider#provider#";

				settings.test = "setting";
				settings.blah = CreateUUId();

				service.$( "$getSystemConfigurationService", mockConfigService );
				for( var settingid in settings ) {
					mockConfigService.$( "saveSetting" ).$args(
						  category = settingsCategory
						, setting  = settingId
						, value    = settings[ settingId ]
						, siteId   = site
					).$results( 1 );
				}

				service.saveSettings(
					  provider = provider
					, settings = settings
					, site     = site
				);

				expect( mockConfigService.$callLog().saveSetting.len() ).toBe( settings.count() );
				var i=0;
				for( var settingid in settings ) {
					expect( mockConfigService.$callLog().saveSetting[ ++i ] ).toBe( {
						  category = settingsCategory
						, setting  = settingId
						, value    = settings[ settingId ]
						, siteId   = site
					} );
				}
			} );
		} );

		describe( "validateSettings()", function(){
			it( "should call the provider's configured validateSettings action, passing the settings + validation result arguments", function(){
				var service              = _getService();
				var provider             = "testprovider";
				var mockValidationResult = { thisIsDummy=CreateUUId() };
				var validateAction       = "test." & CreateUUId();
				var settings             = { test=CreateUUId(), password="pass" };

				service.$( "$newValidationResult", mockValidationResult );
				service.$( "getProviderValidateSettingsAction" ).$args( provider ).$results( validateAction );

				mockColdbox.$( "runEvent" );

				expect( service.validateSettings( provider, settings ) ).toBe( mockValidationResult );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 1 );
				expect( mockColdbox.$callLog().runEvent[ 1 ] ).toBe( {
					  event          = validateAction
					, eventArguments = { settings=settings, validationResult=mockValidationResult }
					, private        = true
					, prePostExempt  = true
				} );
			} );

			it( "should do nothing when the handler action does not exist", function(){
				var service              = _getService();
				var provider             = "testprovider";
				var mockValidationResult = { thisIsDummy=CreateUUId() };
				var validateAction       = "test." & CreateUUId();
				var settings             = { test=CreateUUId(), password="pass" };

				service.$( "$newValidationResult", mockValidationResult );
				service.$( "getProviderValidateSettingsAction" ).$args( provider ).$results( validateAction );

				mockColdbox.$( "handlerExists" ).$args( validateAction ).$results( false );
				mockColdbox.$( "runEvent" );

				expect( service.validateSettings( provider, settings ) ).toBe( mockValidationResult );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );
			} );
		} );

		describe( "getProviderForTemplate()", function(){
			it( "should return the default provider when the template ID is empty", function(){
				var service = _getService();
				var defaultProvider = "whatev";

				service.$( "getDefaultProvider", defaultProvider );

				expect( service.getProviderForTemplate( "" ) ).toBe( defaultProvider );
			} );

			it( "should return the configured provider for the template (as saved in db)", function(){
				var service       = _getService();
				var savedTemplate = { service_provider="smtp" };
				var templateId    = CreateUUId();

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( savedTemplate );
				service.$( "isProviderEnabled" ).$args( savedTemplate.service_provider ).$results( true );

				expect( service.getProviderForTemplate( templateId ) ).toBe( savedTemplate.service_provider );
			} );

			it( "should return the default provider when the configured template does not have a service provider set", function(){
				var service         = _getService();
				var defaultProvider = "whatev";
				var savedTemplate   = { service_provider="" };
				var templateId      = CreateUUId();

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( savedTemplate );

				service.$( "getDefaultProvider", defaultProvider );

				expect( service.getProviderForTemplate( templateId ) ).toBe( defaultProvider );
			} );

			it( "should return the default provider when the configured template's service provider is not enabled", function(){
				var service         = _getService();
				var defaultProvider = "whatev";
				var savedTemplate   = { service_provider="yaddayadda!" };
				var templateId      = CreateUUId();

				mockEmailTemplateService.$( "getTemplate" ).$args( templateId ).$results( savedTemplate );
				service.$( "isProviderEnabled" ).$args( savedTemplate.service_provider ).$results( false );

				service.$( "getDefaultProvider", defaultProvider );

				expect( service.getProviderForTemplate( templateId ) ).toBe( defaultProvider );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService( struct configuredProviders=_getDefaultTestProviders() ) {
		mockEmailLoggingService  = createEmptyMock( "preside.system.services.email.EmailLoggingService" );
		mockEmailTemplateService = createEmptyMock( "preside.system.services.email.EmailTemplateService" );

		var service = createMock( object=new preside.system.services.email.EmailServiceProviderService(
			  configuredProviders  = arguments.configuredProviders
			, emailLoggingService  = mockEmailLoggingService
			, emailTemplateService = mockEmailTemplateService
		) );

		mockColdbox = createEmptyMock( "preside.system.coldboxModifications.Controller" );

		service.$( "$getPresideSetting", "" );
		service.$( "$getPresideCategorySettings", {} );
		service.$( "$announceInterception" );
		service.$( "$getColdbox", mockColdbox );
		mockColdbox.$( "handlerExists", true );
		mockEmailLoggingService.$( "markAsSent", 1 );
		mockEmailLoggingService.$( "logEmailContent" );

		dummyHtmlBody = CreateUUId();
		mockEmailLoggingService.$( "insertTrackingPixel", dummyHtmlBody );
		mockEmailLoggingService.$( "insertClickTrackingLinks", dummyHtmlBody );
		mockEmailTemplateService.$( "isTrackingEnabled", false );

		return service;
	}

	private struct function _getDefaultTestProviders() {
		return {
			  smtp      = {}
			, mailgun   = { sendAction="whatev.send", validateSettingsAction="whatev.validate" }
			, mailchimp = { configForm="blah.blah.mailchimp.blah" }
		};
	}
}
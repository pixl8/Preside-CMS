/**
 * Provides logic for dealing with email service providers. i.e. services
 * that allow sending of email (e.g. smtp, mailgun + other APIs, etc.).
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredProviders.inject  coldbox:setting:email.serviceProviders
	 * @emailLoggingService.inject  emailLoggingService
	 * @emailTemplateService.inject emailTemplateService
	 *
	 */
	public any function init(
		  required struct configuredProviders
		, required any    emailLoggingService
		, required any    emailTemplateService
	) {
		_setConfiguredProviders( arguments.configuredProviders );
		_setEmailLoggingService( arguments.emailLoggingService );
		_setEmailTemplateService( arguments.emailTemplateService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of configured providers with translated
	 * titles, descriptions and icon classes. Providers are
	 * ordered by transated title.
	 *
	 * @autodoc true
	 * @includeDisabled.hint Whether or not to include disabled providers (default is false)
	 */
	public array function listProviders( boolean includeDisabled=false ) {
		var rawProviders      = _getConfiguredProviders();
		var providers         = [];
		var disabledProviders = $getPresideSetting( "email", "disabledProviders" ).listToArray();

		for( var providerId in rawProviders ) {
			if ( arguments.includeDisabled || !disabledProviders.findNoCase( providerId ) ) {
				providers.append( getProvider( providerId, arguments.includeDisabled ) );
			}
		}

		providers.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return providers;
	}

	/**
	 * Returns a struct with info about the given provider.
	 * Keys are id, title, description and iconClass. The
	 * latter three are translated dynamically at runtime.
	 *
	 * @autodoc true
	 * @provider.hint ID of the provider to get
	 */
	public struct function getProvider( required string provider, boolean includeDisabled=false ) {
		if ( arguments.includeDisabled || isProviderEnabled( arguments.provider ) ) {
			var uriRoot = "email.serviceProvider.#arguments.provider#:";

			return {
				  id          = arguments.provider
				, title       = $translateResource( uri=uriRoot & "title"      , defaultValue=arguments.provider )
				, description = $translateResource( uri=uriRoot & "description", defaultValue="" )
				, iconClass   = $translateResource( uri=uriRoot & "iconClass"  , defaultValue="" )
			};
		}

		return {};
	}

	/**
	 * Returns the configured default provider.
	 *
	 * @autodoc true
	 */
	public string function getDefaultProvider() {
		var provider = $getPresideSetting( "email", "defaultProvider" );

		if ( provider.len() ) {
			return provider;
		}

		var providers = listProviders();

		return providers[1].id ?: "";
	}

	/**
	 * Returns the configured provider for a given template, or
	 * if no provider configured, the default provider.
	 *
	 * @autodoc         true
	 * @templateId.hint ID of the template whose provider we are to get
	 *
	 */
	public string function getProviderForTemplate( required string templateId ) {
		if ( Len( Trim( templateId ) ) ) {
			var template = _getEmailTemplateService().getTemplate( templateId );

			if ( ( template.service_provider ?: "" ).len() && isProviderEnabled( template.service_provider ) ) {
				return template.service_provider;
			}
		}

		return getDefaultProvider();
	}

	/**
	 * Returns the configuration form name for
	 * the given provider.
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider whose config form name you wish to get
	 */
	public string function getProviderConfigFormName( required string provider ) {
		var rawProviders = _getConfiguredProviders();

		return rawProviders[ arguments.provider ].configForm ?: ( "email.serviceProvider." & arguments.provider );
	}

	/**
	 * Returns the configured/convention based send action for the
	 * given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider whose send action you wish to get
	 */
	public string function getProviderSendAction( required string provider ) {
		var rawProviders = _getConfiguredProviders();

		return rawProviders[ arguments.provider ].sendAction ?: ( "email.serviceProvider." & arguments.provider & ".send" );
	}


	/**
	 * Returns the configured/convention based validate settings action for the
	 * given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider whose validate settings action you wish to get
	 */
	public string function getProviderValidateSettingsAction( required string provider ) {
		var rawProviders = _getConfiguredProviders();

		return rawProviders[ arguments.provider ].validateSettingsAction ?: ( "email.serviceProvider." & arguments.provider & ".validateSettings" );
	}


	/**
	 * Returns whether or not the given provider is enabled.
	 *
	 * @autodoc true
	 * @provider.hint ID of the provider whose enabled/disabled status you wish to check
	 */
	public boolean function isProviderEnabled( required string provider ) {
		var disabledProviders = $getPresideSetting( "email", "disabledProviders" ).listToArray();

		if ( disabledProviders.findNoCase( arguments.provider ) ) {
			return false;
		}

		var configuredProviders = _getConfiguredProviders();

		return StructKeyExists( configuredProviders, arguments.provider );
	}

	/**
	 * Returns configured settings structure for the given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider whose settings you wish to get
	 */
	public struct function getProviderSettings( required string provider ) {
		var categoryName = getProviderSettingsCategory( arguments.provider );

		return $getPresideCategorySettings( argumentCollection=arguments, category=categoryName );
	}

	/**
	 * Returns the system config category for the given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider whose settings category you wish to get
	 */
	public string function getProviderSettingsCategory( required string provider ) {
		return "emailServiceProvider#arguments.provider#";
	}

	/**
	 * Sends an email through the given provider's send action.
	 * Returns true to indicate that the email was sent successfully, false
	 * otherwise.
	 *
	 * @autodoc true
	 * @provider.hint ID of the provider through which to send the email
	 * @sendArgs.hint Structure of arguments to send to the provider's send handler action
	 * @logSend.hint  Whether or not to log the email send and track future events
	 */
	public any function sendWithProvider( required string provider, required struct sendArgs, boolean logSend=true ) {
		var sendAction  = getProviderSendAction( arguments.provider );
		var settings    = getProviderSettings( arguments.provider );
		var logService  = _getEmailLoggingService();
		var sent        = false;
		var returnLogId = arguments.sendArgs.returnLogId ?: false;
		var htmlBody    = sendArgs.htmlBody ?: "";

		if ( !$getColdbox().handlerExists( sendAction ) ) {
			throw(
				  type    = "preside.emailservice.provider.missing.send.action"
				, message = "The email service provider, [#arguments.provider#], has not implemented a send action handler. Missing handler: [#sendAction#]."
			);
		}

		var args = { sendArgs=arguments.sendArgs, settings=settings };
		$announceInterception( "preSendEmail", args );


		if ( arguments.logSend ) {
			args.sendArgs.messageId = _logMessage( args.sendArgs );

			args.sendArgs.htmlBody  = logService.insertTrackingPixel(
				  messageId   = args.sendArgs.messageId
				, messageHtml = args.sendArgs.htmlBody ?: ""
			);

			if ( _getEmailTemplateService().isTrackingEnabled( args.sendArgs.template ?: "" ) ) {
				args.sendArgs.htmlBody  = logService.insertClickTrackingLinks(
					  messageId   = args.sendArgs.messageId
					, messageHtml = args.sendArgs.htmlBody ?: ""
				);
			}
		} else {
			args.sendArgs.messageId = CreateUUId();
		}

		try {
			sent = $getColdbox().runEvent(
				  event          = sendAction
				, eventArguments = { sendArgs=args.sendArgs, settings=args.settings }
				, private        = true
				, prePostExempt  = true
			);

			if ( !IsBoolean( sent ) ) {
				throw(
					  type    = "preside.emailservice.provider.invalid.send.action.return.value"
					, message = "The email service provider send action, [#sendAction#], for the provider, [#arguments.provider#], did not return a boolean value to indicate success/failure of email sending."
					, detail  = "The system has return false to indicate a failure and has logged this error silently as a warning."
				);
			}

		} catch ( any e ) {
			$raiseError( e );
			sent = false;
			if ( arguments.logSend ) {
				logService.markAsFailed( id=args.sendArgs.messageId, reason="An error occurred while sending the email. Error message: [#e.message#]. See error logs for details" );
			}
		}

		if ( arguments.logSend && sent ) {
			logService.markAsSent( args.sendArgs.messageId );
			logService.logEmailContent(
				  template = args.sendArgs.args.template ?: ""
				, id       = args.sendArgs.messageId
				, htmlBody = htmlBody
				, textBody = args.sendArgs.textBody ?: ""
			);
		}

		$announceInterception( "postSendEmail", args );

		return returnLogId ? args.sendArgs.messageId : sent;
	}

	/**
	 * Validates the provided settings. Returns a [[validation-framework]] validationResult
	 * object with any validation errors.
	 *
	 * @autodoc true
	 * @provider.hint         Provider whose settings we are to validate
	 * @settings.hint         Struct of settings to validate
	 * @validationResult.hint Pre-initialized validationResult object - any validation results will be added to this object and returned
	 *
	 */
	public any function validateSettings(
		  required string provider
		, required struct settings
		,          any    validationResult = $newValidationResult()
	) {
		var validateAction = getProviderValidateSettingsAction( provider );

		if ( $getColdbox().handlerExists( validateAction ) ) {
			$getColdbox().runEvent(
				  event          = validateAction
				, eventArguments = { settings=arguments.settings, validationResult=arguments.validationResult }
				, private        = true
				, prePostExempt  = true
			);
		}

		return arguments.validationResult;
	}

	/**
	 * Saves the settings for a particular service provider and optional site
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider whose settings you want to save
	 * @settings.hint Structure of settings to save
	 * @site.hint     Optional ID of preside site to save the settings against
	 */
	public void function saveSettings(
		  required string provider
		, required struct settings
		,          string site = ""
	) {
		var settingsCategory = getProviderSettingsCategory( arguments.provider );
		var configService    = $getSystemConfigurationService();

		for( var key in arguments.settings ) {
			configService.saveSetting(
				  category = settingsCategory
				, setting  = key
				, value    = arguments.settings[ key ]
				, siteId   = arguments.site
			);
		}

		return;
	}

// PRIVATE HELPERS
	private string function _logMessage( required struct sendArgs ) {
		var templateId    = sendArgs.args.template ?: "";
		var recipientType = "";

		if ( templateId.len() ) {
			var template = _getEmailTemplateService().getTemplate( templateId );

			if ( template.count() ) {
				recipientType = template.recipient_type ?: "";
			} else {
				templateId = "";
			}
		}

		return _getEmailLoggingService().createEmailLog(
			  template      = templateId
			, recipientType = recipientType
			, recipientId   = sendArgs.recipientId ?: ""
			, recipient     = ( sendArgs.to[ 1 ]   ?: "" )
			, sender        = ( sendArgs.from      ?: "" )
			, subject       = ( sendArgs.subject   ?: "" )
			, resendOf      = ( sendArgs.resendOf  ?: "" )
			, sendArgs      = ( sendArgs.args      ?: {} )
		);
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required struct configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}

	private any function _getEmailLoggingService() {
		return _emailLoggingService;
	}
	private void function _setEmailLoggingService( required any emailLoggingService ) {
		_emailLoggingService = arguments.emailLoggingService;
	}

	private any function _getEmailTemplateService() {
		return _emailTemplateService;
	}
	private void function _setEmailTemplateService( required any emailTemplateService ) {
		_emailTemplateService = arguments.emailTemplateService;
	}
}
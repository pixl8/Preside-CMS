/**
 * The email service takes care of sending emails through the PresideCMS's email templating system (see [[emailtemplating]]).
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 */
component displayName="Email service" {

// CONSTRUCTOR
	/**
	 * @emailTemplateDirectories.inject presidecms:directories:handlers/emailTemplates
	 */
	public any function init(
		  required array emailTemplateDirectories
	) {
		_setEmailTemplateDirectories( arguments.emailTemplateDirectories );
		_loadTemplates();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Sends an email. If a template is supplied, first runs the template handler which can return a struct that will override any arguments
	 * passed directly to the function
	 *
	 * @template.hint Name of the template who's handler will do the rendering, etc.
	 * @args.hint     Structure of arbitrary arguments to forward on to the template handler
	 * @to.hint       Array of email addresses to send the email to
	 * @from.hint     Optional from email address
	 * @subject.hint  Optional email subject. If not supplied, the template handler should supply it
	 * @cc.hint       Optional array of CC addresses
	 * @bcc.hint      Optional array of BCC addresses
	 * @htmlBody.hint Optional HTML body
	 * @textBody.hint Optional plain text body
	 * @params.hint   Optional struct of cfmail params (headers, attachments, etc.)
	 */
	public boolean function send(
		  string template = ""
		, struct args     = {}
		, array  to       = []
		, string from     = ""
		, string subject  = ""
		, array  cc       = []
		, array  bcc      = []
		, string htmlBody = ""
		, string textBody = ""
		, struct params   = {}
	) autodoc=true {
		var hasTemplate = Len( Trim( arguments.template ) );
		var sendArgs    = hasTemplate ? _mergeArgumentsWithTemplateHandlerResult( argumentCollection=arguments ) : arguments;
		    sendArgs    = _addDefaultsForMissingArguments( sendArgs );

		_validateArguments( sendArgs );

		_send( argumentCollection = sendArgs );

		return true;
	}

	/**
	 * Returns an array of email templates that have been dicovered from the /handlers/emailTemplates
	 * directory
	 *
	 */
	public array function listTemplates() autodoc=true {
		return _getTemplates();
	}

	/**
	 * Validates the supplied connection settings
	 * Returns empty string on success, detailed
	 * server error message otherwise.
	 *
	 * @autodoc
	 *
	 */
	public string function validateConnectionSettings(
		  required string  host
		, required numeric port
		,          string  username = ""
		,          string  password = ""
	) {

		try {
			var props = CreateObject( "java", "java.util.Properties" ).init();
			props.put( "mail.smtp.starttls.enable", "true" );
			props.put( "mail.smtp.auth", "true" );

			var mailSession = CreateObject( "java", "javax.mail.Session" ).getInstance( props, NullValue() );
			var transport   = mailSession.getTransport( "smtp" );

			transport.connect( arguments.host, arguments.port, arguments.username, arguments.password );
			transport.close();

			return "";
		} catch ( "javax.mail.AuthenticationFailedException" e ) {
			return "authentication failure";
		} catch( any e ) {
			return e.message;
		}

	}

// PRIVATE HELPERS
	private void function _loadTemplates() {
		var dirs      = _getEmailTemplateDirectories();
		var templates = {};

		for( var dir in dirs ) {
			dir   = ExpandPath( dir );
			files = DirectoryList( dir, true, "path", "*.cfc" );

			for( file in files ){
				var templateName = ReplaceNoCase( file, dir, "" );
				    templateName = ReReplace( templateName, "\.cfc$", "" );
				    templateName = ListChangeDelims( templateName, ".", "\/" );

				templates[ templateName ] = templateName;
			}
		}

		templates = templates.keyArray();
		templates.sort( "textnocase" );

		_setTemplates( templates );
	}

	private boolean function _send(
		  required string from
		, required array  to
		, required string subject
		,          array  cc       = []
		,          array  bcc      = []
		,          string htmlBody = ""
		,          string textBody = ""
		,          struct params   = {}
	) {
		var m          = new Mail();
		var settings   = $getPresideCategorySettings( "email" );
		var mailServer = settings.server   ?: "";
		var port       = settings.port     ?: "";
		var username   = settings.username ?: "";
		var password   = settings.password ?: "";

		m.setTo( arguments.to.toList( ";" ) );
		m.setFrom( arguments.from );
		m.setSubject( arguments.subject );

		if ( arguments.cc.len()  ) {
			m.setCc( arguments.cc.toList( ";" ) );
		}
		if ( arguments.bcc.len() ) {
			m.setBCc( arguments.bcc.toList( ";" ) );
		}
		if ( Len( Trim( arguments.textBody ) ) ) {
			m.addPart( type='text', body=Trim( arguments.textBody ) );
		}
		if ( Len( Trim( arguments.htmlBody ) ) ) {
			m.addPart( type='html', body=Trim( arguments.htmlBody ) );
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

		for( var param in arguments.params ){
			m.addParam( argumentCollection=arguments.params[ param ] );
		}

		m.addParam( name="X-Mailer", value="PresideCMS" );
		m.send();

		return true;
	}

	private struct function _mergeArgumentsWithTemplateHandlerResult( required string template, required struct args ) {
		if ( !_getTemplates().findNoCase( arguments.template ) ) {
			throw(
				  type    = "EmailService.missingTemplate"
				, message = "Missing email template [#arguments.template#]"
				, detail  = "Expected to find a handler at [/handlers/emailTemplates/#arguments.template#.cfc]"
			);
		}

		var handlerArgs = Duplicate( arguments.args  );
		    handlerArgs.append( arguments, false );
		    handlerArgs.delete( "template" );
		    handlerArgs.delete( "args" );

		var sendArgs = $getColdbox().runEvent(
			  event          = "emailTemplates.#arguments.template#.prepareMessage"
			, private        = true
			, eventArguments = { args=handlerArgs }
		);

		sendArgs.append( arguments, false );
		sendArgs.delete( "template" );
		sendArgs.delete( "args" );

		return sendArgs;
	}

	private struct function _addDefaultsForMissingArguments( required struct sendArgs ) {
		if ( !Len( Trim( sendArgs.from ?: "" ) ) ) {
			sendArgs.from = $getPresideSetting( "email", "default_from_address" );
		}

		return sendArgs;
	}

	private void function _validateArguments( required struct sendArgs ) {
		if ( !Len( Trim( sendArgs.from ?: "" ) ) ) {
			throw(
				  type   = "EmailService.missingSender"
				, message= "Missing from email address when sending message with subject [#sendArgs.subject ?: ''#]"
				, detail = "Ensure that a default from email address is configured through your PresideCMS administrator"
			);
		}

		if ( !( sendArgs.to ?: [] ).len() ) {
			throw(
				  type   = "EmailService.missingToAddress"
				, message= "Missing to email address(es) when sending message with subject [#sendArgs.subject ?: ''#]"
			);
		}

		if ( !Len( Trim( sendArgs.subject ?: "" ) ) ) {
			throw(
				  type   = "EmailService.missingSubject"
				, message= "Missing subject when sending message to [#(sendArgs.to ?: []).toList(';')#], from [#(sendArgs.from ?: '')#]"
			);
		}

		if ( !Len( Trim( ( sendArgs.htmlBody ?: "" ) & ( sendArgs.textBody ?: "" ) ) ) ) {
			throw(
				  type   = "EmailService.missingBody"
				, message= "Missing body when sending message with subject [#sendArgs.subject ?: ''#]"
			);
		}
	}


// GETTERS AND SETTERS
	private any function _getEmailTemplateDirectories() {
		return _emailTemplateDirectories;
	}
	private void function _setEmailTemplateDirectories( required any emailTemplateDirectories ) {
		_emailTemplateDirectories = arguments.emailTemplateDirectories;
	}

	private array function _getTemplates() {
		return _templates;
	}
	private void function _setTemplates( required array templates ) {
		_templates = arguments.templates;
	}
}
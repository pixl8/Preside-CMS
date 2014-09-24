/**
 * The email service takes care of sending emails through the PresideCMS's email templating system (see :doc:`/devguides/emailtemplates`).
 *
 */
component output=false autodoc=true {

// CONSTRUCTOR
	/**
	 * @emailTemplateDirectories.inject presidecms:directories:handlers/emailTemplates
	 * @systemConfigurationService.inject systemConfigurationService
	 * @coldbox.inject                  coldbox
	 */
	public any function init( required array emailTemplateDirectories, required any coldbox, required any systemConfigurationService ) output=false {
		_setEmailTemplateDirectories( arguments.emailTemplateDirectories );
		_setColdbox( arguments.coldbox );
		_setSystemConfigurationService( arguments.systemConfigurationService );

		_loadTemplates();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Sends an email. If a template is supplied, first runs the template handler which can return a struct that will override any arguments
	 * passed directly to the function
	 *
	 * @template.hint      Name of the template who's handler will do the rendering, etc.
	 * @args.hint          Structure of arbitrary arguments to forward on to the template handler
	 * @to.hint            Array of email addresses to send the email to
	 * @from.hint          Optional from email address
	 * @subject.hint       Optional email subject. If not supplied, the template handler should supply it
	 * @cc.hint            Optional array of CC addresses
	 * @bcc.hint           Optional array of BCC addresses
	 * @htmlBody.hint      Optional HTML body
	 * @plainTextBody.hint Optional plain text body
	 * @params.hint        Optional struct of cfmail params (headers, attachments, etc.)
	 */
	public boolean function send(
		  string template      = ""
		, struct args          = {}
		, array  to            = []
		, string from          = ""
		, string subject       = ""
		, array  cc            = []
		, array  bcc           = []
		, string htmlBody      = ""
		, string plainTextBody = ""
		, struct params        = {}
	) output=false autodoc=true {
		var hasTemplate = Len( Trim( arguments.template ) );
		var sendArgs    = hasTemplate ? _mergeArgumentsWithTemplateHandlerResult( argumentCollection=arguments ) : arguments;
		    sendArgs    = _addDefaultsForMissingArguments( sendArgs );

		_send( argumentCollection = sendArgs );

		return true;
	}

	/**
	 * Returns an array of email templates that have been dicovered from the /handlers/emailTemplates
	 * directory
	 *
	 */
	public array function listTemplates() output=false autodoc=true {
		return _getTemplates();
	}

// PRIVATE HELPERS
	private void function _loadTemplates() output=false {
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
		,          array  cc            = []
		,          array  bcc           = []
		,          string htmlBody      = ""
		,          string plainTextBody = ""
		,          struct params        = {}
	) output=false {
		var m          = new Mail();
		var mailServer = _getSystemConfigurationService().getSetting( "email", "server", "" );
		var port       = _getSystemConfigurationService().getSetting( "email", "port"  , "" );

		m.setTo( arguments.to.toList( ";" ) );
		m.setFrom( arguments.from );
		m.setSubject( arguments.subject );

		if ( arguments.cc.len()  ) {
			m.setCc( arguments.cc.toList( ";" ) );
		}
		if ( arguments.bcc.len() ) {
			m.setBCc( arguments.bcc.toList( ";" ) );
		}
		if ( Len( Trim( arguments.plainTextBody ) ) ) {
			m.addPart( type='text', body=arguments.plainTextBody );
		}
		if ( Len( Trim( arguments.htmlBody ) ) ) {
			m.addPart( type='html', body=arguments.htmlBody );
		}
		if ( Len( Trim( mailServer ) ) ) {
			m.setServer( mailServer );
		}
		if ( Len( Trim( port ) ) ) {
			m.setPort( port );
		}

		for( var param in arguments.params ){
			m.addParam( argumentCollection=arguments.params[ param ] );
		}

		try {
			m.send();
		} catch( any e ) {
			// TODO: logging here
			return false;
		}

		return true;
	}

	private struct function _mergeArgumentsWithTemplateHandlerResult() output=false {
		var handlerArgs = Duplicate( arguments.args  );
		    handlerArgs.append( arguments, false );
		    handlerArgs.delete( "template" );
		    handlerArgs.delete( "args" );

		var sendArgs = _getColdbox().runEvent(
			  event          = "emailTemplates.#arguments.template#.index"
			, private        = true
			, eventArguments = { args=handlerArgs }
		);

		sendArgs.append( arguments, false );
		sendArgs.delete( "template" );
		sendArgs.delete( "args" );

		return sendArgs;
	}

	private struct function _addDefaultsForMissingArguments( required struct sendArgs ) output=false {
		if ( !Len( Trim( sendArgs.from ?: "" ) ) ) {
			sendArgs.from = _getSystemConfigurationService().getSetting( "email", "default_from_address" );
		}

		return sendArgs;
	}


// GETTERS AND SETTERS
	private any function _getEmailTemplateDirectories() output=false {
		return _emailTemplateDirectories;
	}
	private void function _setEmailTemplateDirectories( required any emailTemplateDirectories ) output=false {
		_emailTemplateDirectories = arguments.emailTemplateDirectories;
	}

	private array function _getTemplates() output=false {
		return _templates;
	}
	private void function _setTemplates( required array templates ) output=false {
		_templates = arguments.templates;
	}

	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}

	private any function _getSystemConfigurationService() output=false {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) output=false {
		_systemConfigurationService = arguments.systemConfigurationService;
	}
}
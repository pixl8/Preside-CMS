/**
 * The email service takes care of sending emails through the PresideCMS's email templating system (see :doc:`/devguides/emailtemplates`).
 *
 */
component output=false autodoc=true {

// CONSTRUCTOR
	/**
	 * @emailTemplateDirectories.inject presidecms:directories:handlers/emailTemplates
	 * @coldbox.inject                  coldbox
	 */
	public any function init( required array emailTemplateDirectories, required any coldbox ) output=false {
		_setEmailTemplateDirectories( arguments.emailTemplateDirectories );
		_setColdbox( arguments.coldbox );

		_loadTemplates();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Sends an email after first rendering the email + extracting any other variables from
	 * the specified email template handler.
	 *
	 * @template.hint Name of the template who's handler will do the rendering, etc.
	 * @to.hint       Array of email addresses to send the email to
	 * @args.hint     Structure of arbitrary arguments to forward on to the template handler
	 */
	public boolean function send( required string template, required array to, struct args={} ) output=false autodoc=true {
		var sendArgs = _getColdbox().runEvent( event="emailTemplates.#arguments.template#", eventArguments={ args=arguments.args } );
		sendArgs.to = arguments.to;

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
		,          struct headers       = {}
	) output=false {
		try {
			// todo, cfmail call
		} catch( any e ) {
			// TODO: logging here
			return false;
		}

		return true;
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
}
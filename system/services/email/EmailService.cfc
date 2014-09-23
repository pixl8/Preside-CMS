/**
 * The email service takes care of sending emails through the PresideCMS's email templating system (see :doc:`/devguides/emailtemplates`).
 *
 */
component output=false autodoc=true {

// CONSTRUCTOR
	/**
	 * emailTemplateDirectories.inject presidecms:directories:handlers/emailTemplates
	 *
	 */
	public any function init( required array emailTemplateDirectories ) output=false {
		_setEmailTemplateDirectories( arguments.emailTemplateDirectories );

		_loadTemplates();

		return this;
	}

// PUBLIC API METHODS
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
}
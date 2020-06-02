/**
 * The site templates service provides methods for discovering and listing out
 * site templates which are self contained sets of widgets, page types, objects, etc. See [[workingwithmultiplesites]].
 */
component singleton=true displayname="Site Templates service" autodoc=true {

// CONSTRUCTOR
	/**
	 * @templateDirectories.inject presidecms:directories:site-templates
	 *
	 */
	public any function init( required array templateDirectories ) output=false {
		_setDirectories( arguments.templateDirectories );

		reload();

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of SiteTemplate objects that have been discovered by the system
	 */
	public array function listTemplates() output=false autodoc=true {
		return _getTemplates();
	}

	/**
	 * Re-reads all the template directories to repopulate the internal list of templates
	 */
	public void function reload() output=false autodoc=true {
		var templates   = [];
		var templateIds = {};

		for( var dir in _getDirectories() ) {
			var subs = DirectoryList( dir, false, "query" );
			for( var sub in subs ){
				if ( sub.type == "Dir" ) {
					templateIds[ sub.name ] = true;
				}
			}
		}
		for( var templateId in templateIds ) {
			templates.append( new SiteTemplate(
				  id          = templateId
				, title       = "site-templates.#templateId#:title"
				, description = "site-templates.#templateId#:description"
			) );
		}

		_setTemplates( templates );
	}

// GETTERS AND SETTERS
	private any function _getDirectories() output=false {
		return _directories;
	}
	private void function _setDirectories( required any directories ) output=false {
		_directories = arguments.directories;
	}

	private array function _getTemplates() output=false {
		return _templates;
	}
	private void function _setTemplates( required array templates ) output=false {
		_templates = arguments.templates;
	}

}
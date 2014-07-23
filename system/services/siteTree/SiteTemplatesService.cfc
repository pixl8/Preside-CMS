/**
 * The site templates service provides methods for discovering and listing out
 * site templates which are self contained sets of widgets, page types, objects, etc. See :doc:`/devguides/sites`.
 */
component output=false displayname="Site Templates service" autodoc=true {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API

	/**
	 * Returns an array of SiteTemplate objects that have been discovered by the system
	 */
	public array function listTemplates() output=false autodoc=true {
		return [];
	}

}
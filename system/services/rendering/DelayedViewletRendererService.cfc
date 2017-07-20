/**
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 *
 * Service that deals with replacing 'delayed viewlet' markup in content with live evaluated
 * viewlet renders.
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Takes string content and injects dynamically rendered viewlets
	 * into locations that are marked up with delayed viewlet syntax
	 *
	 * @autodoc true
	 * @content The content to be parsed and injected with rendered viewlets
	 *
	 */
	public string function renderDelayedViewlets( required string content ) {
		return arguments.content;
	}

}
/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public boolean function hasNextAction( required WorkflowInstance instance ) {
		return ArrayFindNoCase( arguments.instance.getManualActions(), "next" ) > 0;
	}

	public boolean function hasPrevAction( required WorkflowInstance instance ) {
		return ArrayFindNoCase( arguments.instance.getManualActions(), "prev" ) > 0;
	}

}
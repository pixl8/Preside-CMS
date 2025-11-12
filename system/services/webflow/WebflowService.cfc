/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @cfflow.inject           cfflow@cfflow
	 * @webflowConverter.inject webflowToCfFlowConverter
	 * @webflowLibrary.inject   webflowSpecLibrary
	 */
	public any function init(
		  required any cfFlow
		, required any webflowConverter
		, required any webflowLibrary
	) {
		_setCfFlow( arguments.cfFlow );
		_setWebflowConverter( arguments.webflowConverter );
		_setWebflowLibrary( arguments.webflowLibrary );
		_setRegisteredFlows( [] );

		return this;
	}

// PUBLIC API METHODS
	public void function loadStepDirectory( required string dir ) {
		var lib       = _getWebflowLibrary();
		var yamlFiles = DirectoryList( arguments.dir, false, "path", "*.yml" );

		ArraySort( yamlFiles, "textnocase" );

		for( var yamlFile in yamlFiles ) {
			lib.registerStep( yamlFile );
		}
	}

	public void function loadSubflowDirectory( required string dir ) {
		var lib       = _getWebflowLibrary();
		var yamlFiles = DirectoryList( arguments.dir, false, "path", "*.yml" );

		ArraySort( yamlFiles, "textnocase" );

		for( var yamlFile in yamlFiles ) {
			lib.registerSubflow( yamlFile );
		}
	}

	public void function loadFlowDirectory( required string dir ) {
		var lib       = _getWebflowLibrary();
		var cfflow    = _getCfFlow();
		var converter = _getWebflowConverter();
		var yamlFiles = DirectoryList( arguments.dir, false, "path", "*.yml" );
		var newFlows  = [];

		ArraySort( yamlFiles, "textnocase" );

		for( var yamlFile in yamlFiles ) {
			var webFlow = lib.registerWebflow( yamlFile );

			if ( !IsNull( webFlow ) ) {
				cfflow.registerWorkflow( converter.convert( webflow ) );
				ArrayAppend( newFlows, webFlow.getId() );
			}
		}

		if ( ArrayLen( newFlows ) ) {
			ArrayAppend( _getRegisteredFlows(), newFlows, true );
		}
	}

	public void function ensureWebflowConfigMatchWithDefined() {
		var registeredFlows = _getRegisteredFlows();

		if ( ArrayLen( registeredFlows ) ) {
			$getPresideObject( "webflow_configuration" ).deleteData(
				  filter        = "webflow_id NOT IN (:webflow_id)"
				, filterParams  = { webflow_id=registeredFlows }
				, bypassTenants = [ "site" ]
			);
		}

		_setRegisteredFlows( [] );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getCfFlow() {
	    return _cfFlow;
	}
	private void function _setCfFlow( required any cfFlow ) {
	    _cfFlow = arguments.cfFlow;
	}

	private any function _getWebflowConverter() {
	    return _webflowConverter;
	}
	private void function _setWebflowConverter( required any webflowConverter ) {
	    _webflowConverter = arguments.webflowConverter;
	}

	private any function _getWebflowLibrary() {
	    return _webflowLibrary;
	}
	private void function _setWebflowLibrary( required any webflowLibrary ) {
	    _webflowLibrary = arguments.webflowLibrary;
	}

	private array function _getRegisteredFlows() {
	    return _registeredFlows;
	}
	private void function _setRegisteredFlows( required array registeredFlows ) {
	    _registeredFlows = arguments.registeredFlows;
	}
}
/**
 * Model of event handler execution taken from
 * Coldbox and modified to be more performant.
 * See https://presidecms.atlassian.net/browse/PRESIDECMS-1607
 * Should hopefully be made redundant pending future Coldbox
 * updates.
 *
 * @accessors false
 */
component {

	/**
	* Constructor
	*/
	function init(){
		variables.invocationPath 	= "";
		variables.handler 			= "";
		variables.method			= "";
		variables.module 			= "";
		variables.isPrivate			= false;
		variables.missingAction		= "";
		variables.viewDispatch		= false;
		variables.actionMetadata 	= {};
		variables.handlerMetadata 	= {};
		variables.metaDataIsSet 	= false;

		return this;
	}

	/************************************** PUBLIC RETURN BACK SETTERS *********************************************/

	function setIsPrivate( required isPrivate ){
		variables.isPrivate = arguments.isPrivate;
		return this;
	}
	function setHandler( required handler ){
		variables.handler = arguments.handler;
		return this;
	}
	function setMethod( required method ){
		variables.method = arguments.method;
		return this;
	}
	function setModule( required module ){
		variables.module = arguments.module;
		return this;
	}
	function setMissingAction( required missingAction ){
		variables.missingAction = arguments.missingAction;
		return this;
	}
	function setViewDispatch( required viewDispatch ){
		variables.viewDispatch = arguments.viewDispatch;
		return this;
	}
	function setInvocationPath( required invocationPath ){
		variables.invocationPath = arguments.invocationPath;
		return this;
	}
	function setActionMetadata( required actionMetadata ){
		variables.actionMetadata = arguments.actionMetadata;
		return this;
	}
	function setHandlerMetadata( required handlerMetadata ){
		variables.handlerMetadata = arguments.handlerMetadata;
		return this;
	}
	function setMetadataIsSet( required metadataIsSet ){
		variables.metadataIsSet = arguments.metadataIsSet;
		return this;
	}

	function getInvocationPath() {
		return variables.invocationPath;
	}
	function getHandler() {
		return variables.handler;
	}
	function getMethod() {
		return variables.method;
	}
	function getModule() {
		return variables.module;
	}
	function getIsPrivate() {
		return variables.isPrivate;
	}
	function getMissingAction() {
		return variables.missingAction;
	}
	function getViewDispatch() {
		return variables.viewDispatch;
	}
	function getMetaDataIsSet() {
		return variables.metaDataIsSet;
	}

	/************************************** UTILITY METHODS *********************************************/

	/**
	 * Return the full action metadata structure or filter by key and default value if needed
	 *
	 * @key The key to search for in the action metadata
	 * @defaultValue Default value to return if not found
	 *
	 * @return any
	 */
	function getActionMetadata( key, defaultValue="" ){
		// If no key passed, then return full structure
		if( isNull( arguments.key ) || !len( arguments.key ) ){
			return variables.actionMetadata;
		}
		// Filter by key
		if( structKeyExists( variables.actionMetadata, arguments.key ) ){
			return variables.actionMetadata[ arguments.key ];
		}
		// Nothing found, just return the default value of empty string
		return arguments.defaultValue;
	}

	/**
	 * Return the full handler metadata structure or filter by key and default value if needed
	 *
	 * @key The key to search for in the handler metadata
	 * @defaultValue Default value to return if not found
	 *
	 * @return any
	 */
	function getHandlerMetadata( key, defaultValue="" ){
		// If no key passed, then return full structure
		if( isNull( arguments.key ) || !len( arguments.key ) ){
			return variables.handlerMetadata;
		}
		// Filter by key
		if( structKeyExists( variables.handlerMetadata, arguments.key ) ){
			return variables.handlerMetadata[ arguments.key ];
		}
		// Nothing found, just return the default value of empty string
		return arguments.defaultValue;
	}

	/**
	* Get the full execution string
	*/
	function getFullEvent(){
		var event = variables.handler & "." & variables.method;
		if( isModule() ){
			return variables.module  & ":" & event;
		}
		return event;
	}

	/**
	* Get the runnable execution path
	*/
	function getRunnable(){
		return getInvocationPath() & "." & variables.handler;
	}

	/**
	* Is this a module execution
	*/
	boolean function isModule(){
		return ( len( variables.module ) GT 0 );
	}

	/**
	* Are we in missing action execution
	*/
	boolean function isMissingAction(){
		return ( len( variables.missingAction ) GT 0 );
	}

}
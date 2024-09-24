/**
 * @singleton true
 */
component extends="coldbox.system.FrameworkSupertype" accessors=true {

// CONSTRUCTOR
	/**
	 * @controller.inject coldbox
	 *
	 */
	public any function init( required any controller ) {
		variables.controller = arguments.controller;

		super.loadApplicationHelpers();
		_registerFlds();

		return this;
	}

	public any function onMissingMethod( required string missingMethodName, any missingMethodArguments ) {
		if ( IsCustomFunction( variables[ arguments.missingMethodName ] ?: "" ) ) {
			this[ arguments.missingMethodName ] = variables[ arguments.missingMethodName ]; // lazy load

			return variables[ arguments.missingMethodName ]( argumentCollection=arguments.missingMethodArguments );
		}
	}

// private helper
	private function _registerFlds() {
		for( var key in this ) {
			if ( isCustomFunction( this[ key ] ) ) {
				_registerFld( LCase( key ) );
			}
		}
		for( var key in variables ) {
			if ( isCustomFunction( variables[ key ] ) ) {
				_registerFld( LCase( key ) );
			}
		}
	}

	private function _registerFld( key ) {
		var ignoreList = [ "init", "onmissingmethod" ];

		if ( ArrayFind( ignoreList, arguments.key ) || Left( arguments.key, 1 ) == "_" || Left( arguments.key, 1 ) == "$" ) {
			return;
		}

		var coreFldFile = ExpandPath( "/preside/system/flds/#arguments.key#.cfm" );
		var fldFile = ExpandPath( "/preside/system/flds/.scratch/#arguments.key#.cfm" );

		if ( !FileExists( coreFldFile ) && !FileExists( fldFile ) ) {
			FileWrite( fldFile, '<c' & 'ffunction name="#key#" output="false"><c' & 'fsilent><c' & 'freturn application.cbbootstrap.getController().getWirebox().getInstance( "presideHelperClass" ).#key#( argumentCollection=arguments ) /></c' & 'fsilent></c' & 'ffunction>' );
		}
	}
}
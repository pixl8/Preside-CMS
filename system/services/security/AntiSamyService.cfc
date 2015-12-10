/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		_setLibPath( ExpandPath( "/coldbox/system/plugins/AntiSamy-lib" ) );
		_setupPolicyFiles();
		_setupAntiSamy();

		return this;
	}

// PUBLIC API
	public any function clean( required string input, string policy="myspace" ) {
		var antiSamyResult = _getAntiSamy().scan( arguments.input, _getPolicyFile( arguments.policy ) );

		return antiSamyResult.getCleanHtml();
	}

// PRIVATE HELPERS
	private void function _setupPolicyFiles() {
		var libPath = _getLibPath();

		_setPolicyFiles ( {
			  antisamy = libPath & '/antisamy-anythinggoes-1.4.4.xml'
			, ebay     = libPath & '/antisamy-ebay-1.4.4.xml'
			, myspace  = libPath & '/antisamy-myspace-1.4.4.xml'
			, slashdot = libPath & '/antisamy-slashdot-1.4.4.xml'
			, tinymce  = libPath & '/antisamy-tinymce-1.4.4.xml'
		} );
	}

	private void function _setupAntiSamy() {
		var jars = DirectoryList( _getLibPath(), false, "path", "*.jar" );

		_setAntiSamy( CreateObject( "java", "org.owasp.validator.html.AntiSamy", jars ) );
	}

	private array function _listJars( required string directory ) {
		return ;
	}

	private string function _getPolicyFile( required string policy ) {
		var policies = _getPolicyFiles();

		return policies[ arguments.policy ] ?: throw( type="preside.antisamyservice.policy.not.found", message="The policy [#arguments.policy#] was not found. Existing policies: '#SerializeJson( policies.keyArray() )#" );
	}

// GETTERS AND SETTERS
	private string function _getLibPath() {
		return _libPath;
	}
	private void function _setLibPath( required string libPath ) {
		_libPath = arguments.libPath;
	}

	private struct function _getPolicyFiles() {
		return _policyFiles;
	}
	private void function _setPolicyFiles( required struct policyFiles ) {
		_policyFiles = arguments.policyFiles;
	}

	private any function _getAntiSamy() {
		return _antiSamy;
	}
	private void function _setAntiSamy( required any antiSamy ) {
		_antiSamy = arguments.antiSamy;
	}
}
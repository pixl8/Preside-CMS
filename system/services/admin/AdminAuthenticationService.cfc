/**
 * @singleton      true
 * @presideservice true
 */
component accessors=true {

	property name="adminAuthenticationExemptEvents" type="array" inject="coldbox:setting:adminAuthenticationExemptEvents";

	public function init() {
		return this;
	}

	public boolean function eventRequiresAdminAuthentication( required string eventName ) {
		return _isAdminEvent( arguments.eventName ) && !isAdminAuthenticationExempt( arguments.eventName );
	}

	public boolean function isAdminAuthenticationExempt( required string eventName ) {
		return ReFindNoCase( "^admin\.(login|ajaxProxy|general\.setlocale)", arguments.eventName )
			|| _isStaticAssetDownload( arguments.eventName )
			|| _matchesConfiguredExemption( arguments.eventName );
	}

	public boolean function allowsStatelessRequest( required string eventName ) {
		return _isStaticAssetDownload( arguments.eventName ) || _matchesConfiguredExemption( arguments.eventName );
	}

	public boolean function backstopDeniesStatelessRequest( required string eventName ) {
		return _isAdminEvent( arguments.eventName ) && !allowsStatelessRequest( arguments.eventName );
	}

	private boolean function _isAdminEvent( required string eventName ) {
		return ReFindNoCase( "^admin\.", arguments.eventName );
	}

	private boolean function _isStaticAssetDownload( required string eventName ) {
		return ReFindNoCase( "^admin\.staticAssetDownload(\.|$)", arguments.eventName );
	}

	private boolean function _matchesConfiguredExemption( required string eventName ) {
		var eventKey  = LCase( Trim( arguments.eventName ) );
		var exemption = "";
		var pattern   = "";

		for ( exemption in _getConfiguredExemptions() ) {
			pattern = LCase( Trim( exemption ) );

			if ( !Len( pattern ) || !Find( ".", pattern ) ) {
				continue;
			}

			if ( eventKey == pattern || Left( eventKey, Len( pattern ) + 1 ) == pattern & "." ) {
				return true;
			}
		}

		return false;
	}

	private array function _getConfiguredExemptions() {
		if ( !StructKeyExists( variables, "adminAuthenticationExemptEvents" ) || !IsArray( variables.adminAuthenticationExemptEvents ) ) {
			return [];
		}

		return variables.adminAuthenticationExemptEvents;
	}

}

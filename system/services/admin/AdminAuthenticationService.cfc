component {

	public boolean function eventRequiresAdminAuthentication( required string eventName ) {
		return _isAdminEvent( arguments.eventName ) && !isAdminAuthenticationExempt( arguments.eventName );
	}

	public boolean function isAdminAuthenticationExempt( required string eventName ) {
		return ReFindNoCase( "^admin\.(login|ajaxProxy|general\.setlocale)", arguments.eventName ) || _isStaticAssetDownload( arguments.eventName );
	}

	public boolean function backstopDeniesStatelessRequest( required string eventName ) {
		return _isAdminEvent( arguments.eventName ) && !_isStaticAssetDownload( arguments.eventName );
	}

	private boolean function _isAdminEvent( required string eventName ) {
		return ReFindNoCase( "^admin\.", arguments.eventName );
	}

	private boolean function _isStaticAssetDownload( required string eventName ) {
		return ReFindNoCase( "^admin\.staticAssetDownload(\.|$)", arguments.eventName );
	}

}

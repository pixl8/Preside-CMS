component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @eventName.inject coldbox:setting:eventName
	 * @assetManagerService.inject assetManagerService
	 */
	public any function init( required string eventName, required any assetManagerService ) output=false {
		_setEventName( arguments.eventName );
		_setAssetManagerService( arguments.assetManagerService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/asset/(.*?)/", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var assetId        = UrlDecode( ReReplace( arguments.path, "^/asset/(.*?)/.*$", "\1" ) );
		var versionId      = ListLen( assetId, "." ) > 1 ? ListRest( assetId, "." ) : "";
		var isTrashedAsset = Left( assetId, 1 ) == "$";
		var derivativeId   = "";
		var urlParam       = "";

		assetId = ListFirst( assetId, "." );
		assetId = ReReplace( assetId, "^[_\$]", "" );

		event.setValue( "assetId"  , assetId );
		event.setValue( "isTrashed", isTrashedAsset );
		event.setValue( "versionId", versionId );
		event.setValue( _getEventName(), "core.AssetDownload.asset" );

		if ( ReFind( "^/asset/.*?/(.*?)/.*$", arguments.path ) ) {
			derivativeId = UrlDecode( ReReplace( arguments.path, "^/asset/.*?/(.*?)/.*$", "\1" ) );
			event.setValue( "derivativeId", derivativeId );
		}
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return Len( Trim( buildArgs.assetId ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var assetId    = buildArgs.assetId    ?: "";
		var derivative = buildArgs.derivative ?: "";
		var versionId  = buildArgs.versionId  ?: _getAssetManagerService().getCurrentVersionId( assetId );
		var trashed    = IsBoolean( buildArgs.trashed ?: "" ) && buildArgs.trashed;
		var link       = "/asset/" & UrlEncodedFormat( assetId );

		if ( Len( Trim( versionId ) ) ) {
			link &= "." & UrlEncodedFormat( versionId );
		}

		link &= "/";

		if ( Len( Trim( derivative ) ) ) {
			link &= UrlEncodedFormat( derivative ) & "/";
			var signature = _getAssetManagerService().getDerivativeConfigSignature( derivative );
			if ( Len( Trim( signature ) ) ) {
				link &= "#UrlEncodedFormat( signature )#/";
			}
		}

		if ( trashed ) {
			link = ReReplace( link, "^/asset/", "/asset/$" );
		}

		return event.getSiteUrl() & link;
	}

// private getters and setters
	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}

	private any function _getAssetManagerService() output=false {
		return _assetManagerService;
	}
	private void function _setAssetManagerService( required any assetManagerService ) output=false {
		_assetManagerService = arguments.assetManagerService;
	}
}
component implements="iRouteHandler" singleton=true presideService=true {

// constructor
	/**
	 * @eventName.inject coldbox:setting:eventName
	 * @assetManagerService.inject assetManagerService
	 * @presideObjectService.inject presideObjectService
	 */
	public any function init(
		  required string eventName
		, required any    assetManagerService
		, required any    presideObjectService
	) output=false {
		_setEventName( arguments.eventName );
		_setAssetManagerService( arguments.assetManagerService );
		_setPresideObjectService( arguments.presideObjectService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/asset/(.*?)/", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var assetId        = UrlDecode( UrlDecode( ReReplace( arguments.path, "^/asset/(.*?)/.*$", "\1" ) ) );
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
			derivativeId = UrlDecode( UrlDecode( ReReplace( arguments.path, "^/asset/.*?/(.*?)/.*$", "\1" ) ) );
			event.setValue( "derivativeId", derivativeId );
		}
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return Len( Trim( buildArgs.assetId ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var siteId        = buildArgs.siteId        ?: "";
		var assetId       = buildArgs.assetId       ?: "";
		var derivative    = buildArgs.derivative    ?: "";
		var versionId     = buildArgs.versionId     ?: "";
		var trackDownload = buildArgs.trackDownload ?: false;
		var trashed       = IsBoolean( buildArgs.trashed ?: "" ) && buildArgs.trashed;
		var link          = "";
		var assetFields   = [ "asset_type" ];
		var assetTenant   = _getPresideObjectService().getObjectAttribute( objectName="asset", attributeName="tenant" );
		var isSiteTenant  = false;

		if ( Len( Trim( assetTenant ) ) ) {
			var tenantFieldProp = _getPresideObjectService().getObjectProperty( objectName="asset", propertyName=assetTenant );

			if ( ( tenantFieldProp.relatedTo ?: "" ) == "site" ) {
				isSiteTenant = true;
				ArrayAppend( assetFields, assetTenant );
			}
		}

		var assetDetail = _getAssetManagerService().getAsset( id=assetId, selectFields=assetFields );
		var assetType   = assetDetail.asset_type ?: "";

		if ( isSiteTenant ) {
			siteId = Len( siteId ) ? siteId : ( assetDetail[ assetTenant ] ?: "" );
		}

		if ( !isEmpty( assetType ) ) {
			var assetTypeDetail = _getAssetManagerService().getAssetType( name=assetType );
			trackDownload      = $helpers.isTrue( assetTypeDetail.trackDownloads ?: ( assetTypeDetail.serveAsAttachment ?: false ) );
		}

		if ( Len( Trim( derivative ) ) ) {
			if ( IsBoolean( trackDownload ) && trackDownload ) {
				link = _getAssetManagerService().getInternalAssetUrl(
					  id         = assetId
					, versionId  = versionId
					, derivative = derivative
				);
			} else {
				link = _getAssetManagerService().getDerivativeUrl(
					  assetId        = assetId
					, derivativeName = derivative
					, versionId      = versionId
				);
			}
		} else {
			if ( IsBoolean( trackDownload ) && trackDownload ) {
				link = _getAssetManagerService().getInternalAssetUrl(
					  id         = assetId
					, versionId  = versionId
					, trashed    = trashed
				);
			} else {
				link = _getAssetManagerService().getAssetUrl(
					  id         = assetId
					, versionId  = versionId
					, trashed    = trashed
				);
			}
		}

		if ( !ReFind( "^(https?:)?\/\/", link ) ) {
			link = event.getSiteUrl(
				  siteId              = siteId
				, includePath         = Len( siteId ) ? true : false
				, includeLanguageSlug = false
			) & link;
		}

		return link;
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

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}
}
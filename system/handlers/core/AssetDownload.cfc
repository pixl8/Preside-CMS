/**
 * @feature assetManager
 */
component {

	property name="assetManagerService"          inject="assetManagerService";
	property name="assetQueueService"            inject="presidecms:dynamicservice:assetQueue";
	property name="websiteUserActionService"     inject="featureInjector:websiteUsers:websiteUserActionService";
	property name="rulesEngineWebRequestService" inject="rulesEngineWebRequestService";
	property name="queueMaxWaitAttempts"         inject="coldbox:setting:assetManager.queue.downloadWaitSeconds";
	property name="publicCacheAge"               inject="coldbox:setting:assetManager.cacheExpiry.public";
	property name="privateCacheAge"              inject="coldbox:setting:assetManager.cacheExpiry.private";

	public function asset( event, rc, prc ) {
		announceInterception( "preDownloadAsset" );

		var permissionSettings = _getPermissionSettings( argumentCollection=arguments );
		var isTrashed          = IsTrue( rc.isTrashed ?: "" );
		if ( permissionSettings.restricted || isTrashed ) {
			_checkDownloadPermissions( argumentCollection=arguments, permissionSettings=permissionSettings, isTrashed=isTrashed );
		}

		var assetId           = rc.assetId      ?: "";
		var versionId         = rc.versionId    ?: "";
		var derivativeName    = rc.derivativeId ?: "";

		if ( !assetManagerService.assetExists( id=assetId ) ) {
			event.renderData( data="404 not found", type="text", statusCode=404 );
			return;
		}

		var asset             = "";
		var assetSelectFields = [ "asset.title", "asset.file_name", "asset.is_trashed" ];
		var passwordProtected = false;
		var config            = assetManagerService.getDerivativeConfig( assetId );
		var configHash        = assetManagerService.getDerivativeConfigHash( config );
		var queueEnabled      = isFeatureEnabled( "assetQueue" );
		var assetPublicUrl    = "";

		try {
			if ( Len( Trim( derivativeName ) ) ) {
				arrayAppend( assetSelectFields , "asset_derivative.asset_type" );

				var waitAttempts  = 0;
				var assetIsQueued = queueEnabled && assetQueueService.isQueued( assetId, derivativeName, versionId, configHash );

				do {
					asset = assetManagerService.getAssetDerivative(
						  assetId           = assetId
						, versionId         = versionId
						, derivativeName    = derivativeName
						, configHash        = configHash
						, selectFields      = assetSelectFields
						, createIfNotExists = !assetIsQueued
					);

					if ( !asset.recordCount && assetIsQueued ) {
						setting requestTimeout=120;
						sleep( 1000 );
					} else {
						break;
					}
				} while( ++waitAttempts <= queueMaxWaitAttempts );

				assetPublicUrl = assetManagerService.getDerivativeUrl(
					  assetId        = assetId
					, derivativeName = derivativeName
					, versionId      = versionId
				);
			} else if( Len( Trim( versionId ) ) ) {
				arrayAppend( assetSelectFields , "asset_version.asset_type" );
				asset = assetManagerService.getAssetVersion( assetId=assetId, versionId=versionId, selectFields=assetSelectFields );

				assetPublicUrl = assetManagerService.getAssetUrl(
					  id        = assetId
					, versionId = versionId
					, trashed   = isTrashed
				);
			} else {
				arrayAppend( assetSelectFields , "asset.asset_type" );
				asset = assetManagerService.getAsset( id=assetId, selectFields=assetSelectFields );

				assetPublicUrl = assetManagerService.getAssetUrl(
					  id      = assetId
					, trashed = isTrashed
				);
			}
		} catch ( "AssetManager.assetNotFound" e ) {
			asset = QueryNew('');
		} catch ( "AssetManager.versionNotFound" e ) {
			asset = QueryNew('');
		} catch ( "AssetManagerService.missingDerivativeConfiguration" e ) {
			if ( getSetting( name="showErrors", defaultValue=false ) ) {
				rethrow;
			}
			asset = QueryNew('');
		} catch ( "storageProvider.objectNotFound" e ) {
			asset = QueryNew('');
		} catch( "AssetManager.Password error" e ){
			asset = QueryNew('');
			passwordProtected = true;
		}

		try {
			if ( asset.recordCount && ( isTrashed == asset.is_trashed ) ) {
				var assetFilePathOrBinary = "";
				var type        = assetManagerService.getAssetType( name=asset.asset_type, throwOnMissing=true );
				var etag        = assetManagerService.getAssetEtag( id=assetId, versionId=versionId, derivativeName=derivativeName, configHash=configHash, throwOnMissing=true, isTrashed=isTrashed  );
				_doBrowserEtagLookup( etag );

				announceInterception( "onDownloadAsset", {
					  assetId        = assetId
					, derivativeName = derivativeName
					, asset          = asset
				} );

				var filename = _getFilenameForAsset( Len( Trim( asset.file_name ) ) ? asset.file_name : asset.title, type.extension );
				if ( type.trackDownloads ) {
					if ( isFeatureEnabled( "websiteUsers" ) ) {
						websiteUserActionService.recordAction(
							  action     = "download"
							, type       = "asset"
							, userId     = getLoggedInUserId()
							, identifier = assetId
						);
					}
					header name="Content-Disposition" value="attachment; filename=""#filename#""";
				} else {
					header name="Content-Disposition" value="inline; filename=""#filename#""";
				}

				if ( !ReFindNoCase( "^/asset/", assetPublicUrl ) && event.getCurrentUrl() != UrlDecode( assetPublicUrl ) ) {
					setNextEvent(
						  url        = assetPublicUrl
						, statusCode = type.trackDownloads ? 302 : 301
					);
				}

				if ( Len( Trim( derivativeName ) ) ) {
					assetFilePathOrBinary = assetManagerService.getAssetDerivativeBinary(
						  assetId                = assetId
						, versionId              = versionId
						, derivativeName         = derivativeName
						, configHash             = configHash
						, getFilePathIfSupported = true
					);
				} else {
					assetFilePathOrBinary = assetManagerService.getAssetBinary(
						  id                     = assetId
						, versionId              = versionId
						, isTrashed              = isTrashed
						, getFilePathIfSupported = true
					);
				}

				header name="etag" value=etag;
				if ( permissionSettings.restricted || isTrashed ) {
					header name="cache-control" value="private, max-age=#privateCacheAge#";
				} else {
					header name="cache-control" value="public, max-age=#publicCacheAge#";
				}

				if ( IsBinary( assetFilePathOrBinary ) ) {
					content
						reset    = true
						variable = assetFilePathOrBinary
						type     = type.mimeType;
				} else {
					content
						reset = true
						file  = assetFilePathOrBinary
						type  = type.mimeType;
				}
				abort;
			} else if( passwordProtected ){
				header name="Content-Disposition" value="inline; filename=""ProctedPDF""";
				content
					reset = true
					file  = ExpandPath( "/preside/system/assets/images/asset-type-icons/48px/locked-pdf.png" )
					type  = 'image/png';
				abort;
			}
		} catch ( "storageProvider.objectNotFound" e ) {}

		event.renderData( data="404 not found", type="text", statusCode=404 );

	}

// private helpers
	private string function _doBrowserEtagLookup( required string etag ) {
		if ( ( cgi.http_if_none_match ?: "" ) == arguments.etag ) {
			announceInterception( "onReturnAsset304", { etag = arguments.etag } );
			content reset=true;header statuscode=304 statustext="Not Modified";abort;
		}
	}

	private string function _getFilenameForAsset( required string assetTitle, required string extension ) {
		return ReReplace( arguments.assetTitle, "\.#arguments.extension#$", "" ) & "." & arguments.extension;
	}

	private struct function _getPermissionSettings( event, rc, prc ) {
		var assetId        = rc.assetId       ?: "";
		var derivativeName = rc.derivativeId  ?: "";

		if ( Len( Trim( derivativeName ) ) && assetManagerService.isDerivativePubliclyAccessible( derivativeName ) ) {
			return { restricted=false };
		}

		return assetManagerService.getAssetPermissioningSettings( assetId );
	}

	private void function _checkDownloadPermissions( event, rc, prc, permissionSettings, isTrashed ) {
		var assetId        = rc.assetId       ?: "";
		var derivativeName = rc.derivativeId  ?: "";
		var hasPerm        = false;

		if ( event.isAdminUser() ) {
			hasPerm = hasCmsPermission(
				  permissionKey = "assetmanager.assets.download"
				, context       = "assetmanagerfolder"
				, contextKeys   = arguments.permissionSettings.contextTree ?: []
			);
			if ( !hasPerm ) {
				event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
			}
			return;
		} else if ( arguments.isTrashed ) {
			event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
			return;
		}

		if ( Len( Trim( arguments.permissionSettings.conditionId ) ) ) {
			var conditionIsTrue = rulesEngineWebRequestService.evaluateCondition( arguments.permissionSettings.conditionId );

			if ( conditionIsTrue ) {
				return;
			}

			if ( !isLoggedIn() || ( arguments.permissionSettings.fullLoginRequired && isAutoLoggedIn() ) ) {
				event.accessDenied( reason="LOGIN_REQUIRED", postLoginUrl=( cgi.http_referer ?: "" ) );
			} else {
				event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
			}
		}

		if ( !isLoggedIn() || ( arguments.permissionSettings.fullLoginRequired && isAutoLoggedIn() ) ) {
			event.accessDenied( reason="LOGIN_REQUIRED", postLoginUrl=( cgi.http_referer ?: "" ) );
		}

		hasPerm = hasWebsitePermission(
			  permissionKey       = "assets.access"
			, context             = "asset"
			, contextKeys         = arguments.permissionSettings.contextTree
			, forceGrantByDefault = IsBoolean( arguments.permissionSettings.grantAcessToAllLoggedInUsers ) && arguments.permissionSettings.grantAcessToAllLoggedInUsers
		);

		if ( !hasPerm ) {
			event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
		}
	}
}
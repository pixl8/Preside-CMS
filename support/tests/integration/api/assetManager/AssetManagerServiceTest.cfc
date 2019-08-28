component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getAssetUrl()", function(){
			it( "should return url stored against the asset database record", function(){
				var service  = _getService();
				var assetId  = CreateUUId();
				var assetUrl = "http://blah.com/#CreateUUId()#.jpg";
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url,active_version', 'varchar,varchar,varchar,varchar', [["/blah/test",CreateUUId(),assetUrl,CreateUUId()]] );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url", "active_version" ] ).$results( asset );

				expect( service.getAssetUrl( assetId ) ).toBe( assetUrl );
			} );

			it( "should return url stored against the asset version database record when a specific version is supplied", function(){
				var service   = _getService();
				var assetId   = CreateUUId();
				var versionId = 485;
				var assetUrl  = "http://static.test.com/#CreateUUId()#.jpg";
				var asset     = QueryNew( 'storage_path,asset_folder,asset_url', 'varchar,varchar,varchar', [["/blah/test",CreateUUId(),assetUrl]] );

				service.$( "getAssetVersion" ).$args( assetId=assetId, versionId=versionId, selectFields=[ "asset_version.storage_path", "asset.asset_folder", "asset_version.asset_url" ] ).$results( asset );

				expect( service.getAssetUrl( id=assetId, versionId=versionId ) ).toBe( assetUrl );
			} );

			it( "should return an empty string when the asset is not found", function(){
				var service  = _getService();
				var assetId  = CreateUUId();
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url,active_version' );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url", "active_version" ] ).$results( asset );

				expect( service.getAssetUrl( assetId ) ).toBe( "" );
			} );

			it( "should return a newly generated URL when one not set against the database record", function(){
				var service  = _getService();
				var assetId  = CreateUUId();
				var assetUrl = "http://blah.com/#CreateUUId()#.jpg";
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url,active_version', 'varchar,varchar,varchar,varchar', [["/blah/test",CreateUUId(),"",CreateUUId()]] );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url", "active_version" ] ).$results( asset );
				service.$( "generateAssetUrl" ).$args(
					  id          = assetId
					, versionId   = asset.active_version
					, storagePath = asset.storage_path
					, folder      = asset.asset_folder
					, trashed     = false
				).$results( assetUrl );
				mockAssetDao.$( "updateData", 1 );
				mockAssetVersionDao.$( "updateData", 1 );

				expect( service.getAssetUrl( assetId ) ).toBe( assetUrl );
			} );

			it( "should save a newly generated URL against the asset when one not already set against the database record", function(){
				var service  = _getService();
				var assetId  = CreateUUId();
				var assetUrl = "http://blah.com/#CreateUUId()#.jpg";
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url,active_version', 'varchar,varchar,varchar,varchar', [["/blah/test",CreateUUId(),"",CreateUUId()]] );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url", "active_version" ] ).$results( asset );
				service.$( "generateAssetUrl" ).$args(
					  id          = assetId
					, versionId   = asset.active_version
					, storagePath = asset.storage_path
					, folder      = asset.asset_folder
					, trashed     = false
				).$results( assetUrl );

				mockAssetDao.$( "updateData", 1 );
				mockAssetVersionDao.$( "updateData", 1 );

				expect( service.getAssetUrl( assetId ) ).toBe( assetUrl );

				var callLog = mockAssetDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1] ).toBe( { id=assetId, data={ asset_url=assetUrl } } );

				var callLog = mockAssetVersionDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1] ).toBe( { id=asset.active_version, data={ asset_url=assetUrl } } );
			} );

			it( "should save a newly generated URL against the asset version when one not already set against the database record and version id supplied", function(){
				var service   = _getService();
				var assetId   = CreateUUId();
				var versionId = CreateUUId();
				var assetUrl  = "/asset/#assetId#.#versionId#/";
				var asset     = QueryNew( 'storage_path,asset_folder,asset_url', 'varchar,varchar,varchar', [["/blah/test",CreateUUId(),""]] );

				service.$( "getAssetVersion" ).$args( assetId=assetId, versionId=versionId, selectFields=[ "asset_version.storage_path", "asset.asset_folder", "asset_version.asset_url" ] ).$results( asset );
				service.$( "generateAssetUrl" ).$args(
					  id          = assetId
					, versionId   = versionId
					, storagePath = asset.storage_path
					, folder      = asset.asset_folder
					, trashed     = false
				).$results( assetUrl );
				mockAssetVersionDao.$( "updateData", 1 );

				expect( service.getAssetUrl( id=assetId, versionId=versionId ) ).toBe( assetUrl );

				var callLog = mockAssetVersionDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1] ).toBe( { id=versionId, data={ asset_url=assetUrl } } );
			} );

		} );

		describe( "getDerivativeUrl()", function(){
			it( "should return an internal URL when no derivative DB record yet exists and queue the creation of the derivative", function(){
				var service    = _getService();
				var assetId    = CreateUUId();
				var derivative = "thumbnailyarh";
				var internalUrl = "/asset/#assetId#/#derivative#/blah/";

				service.$( "getAssetDerivative" ).$args(
					  assetId           = assetId
					, derivativeName    = derivative
					, versionId         = ""
					, selectFields      = [ "asset_derivative.id", "asset_derivative.asset_url", "asset_derivative.storage_path", "asset.asset_folder", "asset.active_version" ]
					, createIfNotExists = false
				).$results( QueryNew( '' ) );
				service.$( "getActiveAssetVersion", "" );
				service.$( "getDerivativeConfig", "" );
				service.$( "getDerivativeConfigHash", "" );
				service.$( "$isFeatureEnabled" ).$args( "assetQueue" ).$results( true );
				service.$( "getInternalAssetUrl" ).$args(
					  id         = assetId
					, versionId  = ""
					, derivative = derivative
					, trashed    = false
				).$results( internalUrl );
				mockAssetQueueService.$( "queueAssetGeneration" );

				expect( service.getDerivativeUrl( assetId=assetId, derivativeName=derivative ) ).toBe( internalUrl );

				var callLog = mockAssetQueueService.$callLog().queueAssetGeneration;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( {
					   assetId        = assetId
					 , derivativeName = derivative
					 , versionId      = ""
					 , configHash     = ""
				} );
			} );

			it( "should return an internal URL when no derivative DB record yet exists for specific asset version", function(){
				var service    = _getService();
				var assetId    = CreateUUId();
				var versionId  = CreateUUId();
				var derivative = "thumbnailyarh";
				var internalUrl = "/asset/#assetId#/#derivative#/blah/";

				service.$( "getActiveAssetVersion", "" );
				service.$( "getDerivativeConfig", "" );
				service.$( "getDerivativeConfigHash", "" );
				service.$( "$isFeatureEnabled" ).$args( "assetQueue" ).$results( false );
				service.$( "getAssetDerivative" ).$args(
					  assetId           = assetId
					, derivativeName    = derivative
					, versionId         = versionId
					, selectFields      = [ "asset_derivative.id", "asset_derivative.asset_url", "asset_derivative.storage_path", "asset.asset_folder", "asset.active_version" ]
					, createIfNotExists = false
				).$results( QueryNew( '' ) );
				service.$( "getInternalAssetUrl" ).$args(
					  id         = assetId
					, versionId  = versionId
					, derivative = derivative
					, trashed    = false
				).$results( internalUrl );

				expect( service.getDerivativeUrl( assetId=assetId, derivativeName=derivative, versionId=versionId ) ).toBe( internalUrl );
			} );

			it( "should return the saved URL against the DB record for the derivative if it exists", function(){
				var service          = _getService();
				var assetId          = CreateUUId();
				var derivative       = "thumbnailyarh";
				var savedUrl         = "/asset/#assetId#/#derivative#/#CreateUUId()#/";
				var derivativeRecord = QueryNew( 'id,asset_url,storage_path,asset_folder,active_version', 'varchar,varchar,varchar,varchar,varchar', [[ CreateUUId(), savedUrl, "/some/path",CreateUUId(),CreateUUId()]]);

				service.$( "getActiveAssetVersion", "" );
				service.$( "getDerivativeConfig", "" );
				service.$( "getDerivativeConfigHash", "" );
				service.$( "getAssetDerivative" ).$args(
					  assetId           = assetId
					, derivativeName    = derivative
					, versionId         = ""
					, selectFields      = [ "asset_derivative.id", "asset_derivative.asset_url", "asset_derivative.storage_path", "asset.asset_folder", "asset.active_version" ]
					, createIfNotExists = false
				).$results( derivativeRecord );

				expect( service.getDerivativeUrl( assetId=assetId, derivativeName=derivative ) ).toBe( savedUrl );
			} );

			it( "should generate and save the URL for the derivative when a DB record exists but no URL is stored", function(){
				var service          = _getService();
				var assetId          = CreateUUId();
				var derivative       = "thumbnailyarh";
				var generatedUrl     = "/asset/#assetId#/#derivative#/#CreateUUId()#/";
				var derivativeRecord = QueryNew( 'id,asset_url,storage_path,asset_folder,active_version', 'varchar,varchar,varchar,varchar,varchar', [[ CreateUUId(), "", "/some/path",CreateUUId(),CreateUUId()]]);

				service.$( "getActiveAssetVersion", "" );
				service.$( "getDerivativeConfig", "" );
				service.$( "getDerivativeConfigHash", "" );
				service.$( "getAssetDerivative" ).$args(
					  assetId           = assetId
					, derivativeName    = derivative
					, versionId         = ""
					, selectFields      = [ "asset_derivative.id", "asset_derivative.asset_url", "asset_derivative.storage_path", "asset.asset_folder", "asset.active_version" ]
					, createIfNotExists = false
				).$results( derivativeRecord );

				service.$( "generateAssetUrl" ).$args(
					  id          = assetId
					, storagePath = derivativeRecord.storage_path
					, folder      = derivativeRecord.asset_folder
					, derivative  = derivative
					, versionId   = ""
				).$results( generatedUrl );

				mockAssetDerivativeDao.$( "updateData", 1 );

				expect( service.getDerivativeUrl( assetId=assetId, derivativeName=derivative ) ).toBe( generatedUrl );

				var callLog = mockAssetDerivativeDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( { id=derivativeRecord.id, data={ asset_url=generatedUrl } } );
			} );
		} );

		describe( "generateAssetUrl", function(){

			it( "should return public URL of asset as returned from the assets storage provider, when the asset has no access restrictions", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var folder          = CreateUUId();
				var path            = "/blah/test.pdf";
				var storageProvider = CreateStub();
				var dummyUrl        = "https://www.static-site.com/" & CreateUUId();
				var permissions     = {
					  contextTree                        = [ assetId ]
					, restricted                         = false
					, fullLoginRequired                  = false
					, grantAcessToAllLoggedInUsers       = false
				};

				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "getStorageProviderForFolder" ).$args( folder ).$results( storageProvider );
				storageProvider.$( "getObjectUrl" ).$args( path ).$results( dummyUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder ) ).toBe( dummyUrl );
			} );

			it( "should return internal URL of asset when its storage provider has no configured public URL", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var folder          = CreateUUId();
				var path            = "/blah/test.pdf";
				var storageProvider = CreateStub();
				var storageUrl      = "";
				var internalUrl     = "/whatever/test/#CreateUUId()#/";
				var permissions     = {
					  contextTree                  = [ assetId ]
					, restricted                   = false
					, fullLoginRequired            = false
					, grantAcessToAllLoggedInUsers = false
				};

				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "getStorageProviderForFolder" ).$args( folder ).$results( storageProvider );
				service.$( "getInternalAssetUrl" ).$args( id=assetId, versionId="", trashed=false, derivative="" ).$results( internalUrl );
				storageProvider.$( "getObjectUrl" ).$args( path ).$results( storageUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder ) ).toBe( internalUrl );
			} );

			it( "should return internal URL of asset when it has access restrictions", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var folder          = CreateUUId();
				var path            = "/blah/test.pdf";
				var storageProvider = CreateStub();
				var internalUrl     = "/asset/#assetId#/";
				var permissions     = {
					  contextTree                        = [ assetId ]
					, restricted                         = true
					, fullLoginRequired                  = false
					, grantAcessToAllLoggedInUsers       = false
				};

				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "getInternalAssetUrl" ).$args( id=assetId, versionId="", trashed=false, derivative="" ).$results( internalUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder ) ).toBe( internalUrl );
			} );

			it( "should return internal URL of asset when it is trashed", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var folder          = CreateUUId();
				var path            = "/blah/test.pdf";
				var storageProvider = CreateStub();
				var storageUrl      = "";
				var internalUrl     = "/whatever/test/#CreateUUId()#/";

				service.$( "getInternalAssetUrl" ).$args( id=assetId, versionId="", trashed=true, derivative="" ).$results( internalUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder, trashed=true ) ).toBe( internalUrl );
			} );

			it( "should check a derivative's permissions to determine public/internal URL checking when a derivative is also passed", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var derivative      = CreateUUId();
				var folder          = CreateUUId();
				var path            = "/blah/test.pdf";
				var storageProvider = CreateStub();
				var dummyUrl        = "https://www.static-site.com/" & CreateUUId();

				service.$( "getStorageProviderForFolder" ).$args( folder ).$results( storageProvider );
				service.$( "isDerivativePubliclyAccessible" ).$args( derivative ).$results( true );
				storageProvider.$( "getObjectUrl" ).$args( path ).$results( dummyUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder, derivative=derivative ) ).toBe( dummyUrl );
			} );

			it( "should ensure derivative is passed to internal URL calculation when derivative passed", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var derivative      = CreateUUId();
				var folder          = CreateUUId();
				var path            = "/blah/test.pdf";
				var storageProvider = CreateStub();
				var internalUrl     = "/test/" & CreateUUId();
				var permissions     = {
					  contextTree                  = [ assetId ]
					, restricted                   = true
					, fullLoginRequired            = false
					, grantAcessToAllLoggedInUsers = false
				};

				service.$( "isDerivativePubliclyAccessible" ).$args( derivative ).$results( false );
				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "getInternalAssetUrl" ).$args(
					  id         = assetId
					, versionId  = ""
					, trashed    = false
					, derivative = derivative
				).$results( internalUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder, derivative=derivative ) ).toBe( internalUrl );
			} );
		} );

		describe( "getInternalAssetUrl", function(){

			it( "should take the URL encoded form, /asset/{assetid}/, when no version id supplied", function(){
				var service = _getService();
				var assetId = CreateUUId();

				expect( service.getInternalAssetUrl( id=assetId ) ).toBe( "/asset/#UrlEncodedFormat( assetId )#/" );
			} );

			it( "should take the URL encoded form, /asset/{assetid}.{versionid}/, when version id supplied", function(){
				var service   = _getService();
				var assetId   = CreateUUId();
				var versionId = CreateUUId();

				expect( service.getInternalAssetUrl( id=assetId, versionId=versionId ) ).toBe( "/asset/#UrlEncodedFormat( assetId )#.#UrlEncodedFormat( versionId )#/" );
			} );

			it( "should add derivative id and signature to the URL when derivate details passed", function(){
				var service    = _getService();
				var assetId    = CreateUUId();
				var derivative = CreateUUId();
				var signature  = CreateUUId();

				service.$( "getDerivativeConfigSignature" ).$args( derivative ).$results( signature );

				expect( service.getInternalAssetUrl(
					  id         = assetId
					, derivative = derivative
				) ).toBe( "/asset/#UrlEncodedFormat( assetId )#/#UrlEncodedFormat( derivative )#/#UrlEncodedFormat( signature )#/" );
			} );

			it( "should prepend the assetId in the URL with the $ symbol when the asset is trashed", function(){
				var service = _getService();
				var assetId = CreateUUId();

				expect( service.getInternalAssetUrl( id=assetId, trashed=true ) ).toBe( "/asset/$#UrlEncodedFormat( assetId )#/" );
			} );

		} );
	}


	private any function _getService() {
		mockDefaultStorageProvider     = CreateStub();
		mockDocumentMetadataService    = CreateStub();
		mockStorageLocationService     = CreateStub();
		mockStorageProviderService     = CreateStub();
		mockAssetDao                   = CreateStub();
		mockAssetVersionDao            = CreateStub();
		mockAssetFolderDao             = CreateStub();
		mockAssetDerivativeDao         = CreateStub();
		mockAssetQueueService          = CreateStub();
		mockAssetMetaDao               = CreateStub();
		assetCache                     = CreateStub();
		mockDerivativeGeneratorService = CreateStub();
		configuredDerivatives          = {};
		configuredTypesByGroup         = {};
		configuredFolders              = {};

		var service = CreateObject( "preside.system.services.assetManager.AssetManagerService" );

		service = CreateMock( object=service );

		service.$( "$getPresideObject" ).$args( "asset"            ).$results( mockAssetDao           );
		service.$( "$getPresideObject" ).$args( "asset_version"    ).$results( mockAssetVersionDao    );
		service.$( "$getPresideObject" ).$args( "asset_folder"     ).$results( mockAssetFolderDao     );
		service.$( "$getPresideObject" ).$args( "asset_derivative" ).$results( mockAssetDerivativeDao );
		service.$( "$getPresideObject" ).$args( "asset_meta"       ).$results( mockAssetMetaDao       );
		service.$( "_setupSystemFolders" );
		service.$( "_migrateFromLegacyRecycleBinApproach" );

		assetCache.$( "clearByKeySnippet" );

		return service.init(
			  defaultStorageProvider     = mockDefaultStorageProvider
			, documentMetadataService    = mockDocumentMetadataService
			, storageLocationService     = mockStorageLocationService
			, storageProviderService     = mockStorageProviderService
			, assetQueueService          = mockAssetQueueService
			, derivativeGeneratorService = mockDerivativeGeneratorService
			, configuredDerivatives      = configuredDerivatives
			, configuredTypesByGroup     = configuredTypesByGroup
			, configuredFolders          = configuredFolders
			, renderedAssetCache         = assetCache
		);

	}

}

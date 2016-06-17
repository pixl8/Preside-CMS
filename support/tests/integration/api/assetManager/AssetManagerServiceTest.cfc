component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getAssetUrl()", function(){
			it( "should return url stored against the asset database record", function(){
				var service  = _getService();
				var assetId  = CreateUUId();
				var assetUrl = "http://blah.com/#CreateUUId()#.jpg";
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url', 'varchar,varchar,varchar', [["/blah/test",CreateUUId(),assetUrl]] );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url" ] ).$results( asset );

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
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url' );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url" ] ).$results( asset );

				expect( service.getAssetUrl( assetId ) ).toBe( "" );
			} );

			it( "should return a newly generated URL when one not set against the database record", function(){
				var service  = _getService();
				var assetId  = CreateUUId();
				var assetUrl = "http://blah.com/#CreateUUId()#.jpg";
				var asset    = QueryNew( 'storage_path,asset_folder,asset_url', 'varchar,varchar,varchar', [["/blah/test",CreateUUId(),""]] );

				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder", "asset_url" ] ).$results( asset );
				service.$( "generateAssetUrl" ).$args(
					  id          = assetId
					, versionId   = ""
					, storagePath = asset.storage_path
					, folder      = asset.asset_folder
				).$results( assetUrl );

				expect( service.getAssetUrl( assetId ) ).toBe( assetUrl );
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
				service.$( "_getStorageProviderForFolder" ).$args( folder ).$results( storageProvider );
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
					  contextTree                        = [ assetId ]
					, restricted                         = false
					, fullLoginRequired                  = false
					, grantAcessToAllLoggedInUsers       = false
				};

				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "_getStorageProviderForFolder" ).$args( folder ).$results( storageProvider );
				service.$( "getInternalAssetUrl" ).$args( id=assetId, versionId="" ).$results( internalUrl );
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
				service.$( "getInternalAssetUrl" ).$args( id=assetId, versionId="" ).$results( internalUrl );

				expect( service.generateAssetUrl( id=assetId, storagePath=path, folder=folder ) ).toBe( internalUrl );
			} );
		} );
	}


	private any function _getService() {
		mockDefaultStorageProvider  = CreateStub();
		mockAssetTransformer        = CreateStub();
		mockDocumentMetadataService = CreateStub();
		mockStorageLocationService  = CreateStub();
		mockStorageProviderService  = CreateStub();
		mockAssetDao                = CreateStub();
		mockAssetVersionDao         = CreateStub();
		mockAssetFolderDao          = CreateStub();
		mockAssetDerivativeDao      = CreateStub();
		mockAssetMetaDao            = CreateStub();
		configuredDerivatives       = {};
		configuredTypesByGroup      = {};
		configuredFolders           = {};

		var service = CreateObject( "preside.system.services.assetManager.AssetManagerService" );

		service = CreateMock( object=service );

		service.$( "$getPresideObject" ).$args( "asset"            ).$results( mockAssetDao           );
		service.$( "$getPresideObject" ).$args( "asset_version"    ).$results( mockAssetVersionDao    );
		service.$( "$getPresideObject" ).$args( "asset_folder"     ).$results( mockAssetFolderDao     );
		service.$( "$getPresideObject" ).$args( "asset_derivative" ).$results( mockAssetDerivativeDao );
		service.$( "$getPresideObject" ).$args( "asset_meta"       ).$results( mockAssetMetaDao       );
		service.$( "_setupSystemFolders" );
		service.$( "_migrateFromLegacyRecycleBinApproach" );

		return service.init(
			  defaultStorageProvider  = mockDefaultStorageProvider
			, assetTransformer        = mockAssetTransformer
			, documentMetadataService = mockDocumentMetadataService
			, storageLocationService  = mockStorageLocationService
			, storageProviderService  = mockStorageProviderService
			, configuredDerivatives   = configuredDerivatives
			, configuredTypesByGroup  = configuredTypesByGroup
			, configuredFolders       = configuredFolders
		);
	}

}

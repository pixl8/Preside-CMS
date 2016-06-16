component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getAssetUrl()", function(){
			it( "should return public URL of asset as returned from the assets storage provider, when the asset has no access restrictions", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var asset           = QueryNew( 'storage_path,asset_folder', 'varchar,varchar', [["/blah/test"],[CreateUUId()]] );
				var storageProvider = CreateStub();
				var dummyUrl        = "https://www.static-site.com/" & CreateUUId();
				var permissions     = {
					  contextTree                        = [ assetId ]
					, restricted                         = false
					, fullLoginRequired                  = false
					, grantAcessToAllLoggedInUsers       = false
				};

				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder" ] ).$results( asset );
				service.$( "_getStorageProviderForFolder" ).$args( asset.asset_folder ).$results( storageProvider );
				storageProvider.$( "getObjectUrl" ).$args( asset.storage_path ).$results( dummyUrl );

				expect( service.getAssetUrl( assetId ) ).toBe( dummyUrl );
			} );

			it( "should return internal URL of asset when its storage provider has no configured public URL", function(){
				var service         = _getService();
				var assetId         = CreateUUId();
				var asset           = QueryNew( 'storage_path,asset_folder', 'varchar,varchar', [["/blah/test"],[CreateUUId()]] );
				var storageProvider = CreateStub();
				var permissions     = {
					  contextTree                        = [ assetId ]
					, restricted                         = false
					, fullLoginRequired                  = false
					, grantAcessToAllLoggedInUsers       = false
				};

				service.$( "getAssetPermissioningSettings" ).$args( assetId ).$results( permissions );
				service.$( "getAsset" ).$args( id=assetId, selectFields=[ "storage_path", "asset_folder" ] ).$results( asset );
				service.$( "_getStorageProviderForFolder" ).$args( asset.asset_folder ).$results( storageProvider );
				storageProvider.$( "getObjectUrl" ).$args( asset.storage_path ).$results( "" );

				expect( service.getAssetUrl( assetId ) ).toBe( "/asset/#assetId#/" );
			} );

			it( "should return internal URL of asset when it has access restrictions", function(){
				var service = _getService();

				fail( "not yet implemented" );
			} );

			it( "should return internal URL of asset derivative when the derivate would have a public URL but is not yet generated", function(){
				var service = _getService();

				fail( "not yet implemented" );
			} );

			it( "should return public URL of asset derivative when the asset has no restrictions and public URL configured for its storage provider", function(){
				var service = _getService();

				fail( "not yet implemented" );
			} );

			it( "should return public URL of asset derivative when the derivate has no permissions, even when the asset it is based on _is_ permissioned", function(){
				var service = _getService();

				fail( "not yet implemented" );
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

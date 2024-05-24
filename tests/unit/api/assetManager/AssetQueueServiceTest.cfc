component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "queueAssetGeneration()", function(){
			it( "it should insert a record into the queue with the given parameters", function(){
				var service = _getService();
				var deets   = {
					  assetId        = CreateUUId()
					, versionId      = CreateUUId()
					, derivativeName = CreateUUId()
					, configHash     = Hash( CreateUUid() )
				};
				var expectedDeets = {
					  asset           = deets.assetId
					, asset_version   = deets.versionId
					, derivative_name = deets.derivativeName
					, config_hash     = deets.configHash
					, retry_count     = 0
					, queue_status    = "pending"
					, context         = SerializeJSON( { site=NullValue() } )
				};

				mockQueueDao.$( "dataExists", false );
				mockQueueDao.$( "insertData" );

				service.queueAssetGeneration( argumentCollection=deets );

				var callLog = mockQueueDao.$callLog().insertData;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( { data=expectedDeets } );
			} );

			it( "it should NOT insert a record into the queue when the item is already in the queue", function(){
				var service = _getService();
				var deets   = {
					  assetId        = CreateUUId()
					, versionId      = CreateUUId()
					, derivativeName = CreateUUId()
					, configHash     = Hash( CreateUUid() )
				};

				mockQueueDao.$( "dataExists", true );
				mockQueueDao.$( "insertData" );

				service.queueAssetGeneration( argumentCollection=deets );

				var insertCallLog = mockQueueDao.$callLog().insertData;
				expect( insertCallLog.len() ).toBe( 0 );

				var existsCallLog = mockQueueDao.$callLog().dataExists;
				expect( existsCallLog.len() ).toBe( 1 );
				expect( existsCallLog[ 1 ].filter ).toBe( {
					  asset           = deets.assetId
					, asset_version   = deets.versionId
					, derivative_name = deets.derivativeName
					, config_hash     = deets.configHash
					, context         = SerializeJSON( { site=NullValue() } )
				} );
			} );
		} );

		describe( "getNextQueuedAsset()", function(){
			it( "should return the first queued asset from the asset queue table", function(){
				var service     = _getService();
				var dummyRecord = QueryNew( "id,test", "varchar,varchar", [ [ CreateUUId(), CreateUUId() ] ] );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "id", "asset", "asset_version", "derivative_name", "retry_count", "context" ]
					, orderBy      = "retry_count,datecreated"
					, filter       = "queue_status = :queue_status"
					, filterParams = { queue_status="pending" }
					, maxRows      = 1
				).$results( dummyRecord );
				mockQueueDao.$( "updateData", 1 )

				expect( service.getNextQueuedAsset() ).toBe( { id=dummyRecord.id, test=dummyRecord.test, context={} } );
			} );

			it( "should return an empty struct when no record is returned", function(){
				var service     = _getService();
				var dummyRecord = QueryNew( "id,test" );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "id", "asset", "asset_version", "derivative_name", "retry_count", "context" ]
					, orderBy      = "retry_count,datecreated"
					, filter       = "queue_status = :queue_status"
					, filterParams = { queue_status="pending" }
					, maxRows      = 1
				).$results( dummyRecord );


				expect( service.getNextQueuedAsset() ).toBe( {} );
			} );

			it( "should update the queue_status of the queued asset to ensure no other processes attempt to process the same asset", function(){
				var service     = _getService();
				var dummyRecord = QueryNew( "id,test", "varchar,varchar", [ [ CreateUUId(), CreateUUId() ] ] );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "id", "asset", "asset_version", "derivative_name", "retry_count", "context" ]
					, orderBy      = "retry_count,datecreated"
					, filter       = "queue_status = :queue_status"
					, filterParams = { queue_status="pending" }
					, maxRows      = 1
				).$results( dummyRecord );
				mockQueueDao.$( "updateData", 1 )

				expect( service.getNextQueuedAsset() ).toBe( { id=dummyRecord.id, test=dummyRecord.test, context={} } );

				var updateCallLog = mockQueueDao.$callLog().updateData;

				expect( updateCallLog.len()  ).toBe( 1 );
				expect( updateCallLog[ 1 ]  ).toBe( {
					  filter       = "id = :id and queue_status = :queue_status"
					, filterParams = { id=dummyRecord.id, queue_status="pending" }
					, data         = { queue_status = "running" }
				} );
			} );
		} );

		describe( "processQueue()", function(){
			it( "should repeatedly retrieve assets from the queue and process them, stopping when the rate limit of 10 is reached", function(){
				var service   = _getService();
				var rateLimit = 10;
				var assets    = [];

				for( var i=1; i<=rateLimit+5; i++ ) {
					assets.append({
						  id              = CreateUUId()
						, asset           = CreateUUId()
						, asset_version   = CreateUUId()
						, derivative_name = CreateUUId()
						, retry_count     = 0
					});
				}

				var resultsList = "";
				for( var i=1; i<=rateLimit+5; i++ ){
					resultsList = resultsList.listAppend( "assets[#i#]" );
				}
				Evaluate( "service.$( ""getNextQueuedAsset"" ).$results( #resultsList# )" );

				mockAssetManagerService.$( "createAssetDerivative", 1 );
				service.$( "removeFromQueue", 1 );

				service.processQueue();

				expect( mockAssetManagerService.$callLog().createAssetDerivative.len() ).toBe( rateLimit );
				expect( service.$callLog().removeFromQueue.len() ).toBe( rateLimit );
				for( var i=1; i<=rateLimit; i++ ){
					expect( mockAssetManagerService.$callLog().createAssetDerivative[i] ).toBe( {
						  assetId        = assets[i].asset
						, versionId      = assets[i].asset_version
						, derivativeName = assets[i].derivative_name
						, forceIfExists  = true
					} );
					expect( service.$callLog().removeFromQueue[i] ).toBe( [ assets[i].id ] );
				}
			} );
		} );
	}


	private any function _getService() {
		mockAssetManagerService      = CreateStub();
		mockAssetManagerServiceProxy = CreateStub();
		mockSiteService              = CreateStub();
		mockQueueDao                 = CreateStub();
		mockPoService                = CreateStub();
		mockRequestContext           = CreateStub();

		mockAssetManagerServiceProxy.$( "get", mockAssetManagerService );
		mockSiteService.$( "getSite", {} );
		mockPoService.$( "clearRelatedCaches" );
		mockRequestContext.$( "getSiteId" );

		var service = new preside.system.services.assetManager.AssetQueueService(
			  assetManagerService = mockAssetManagerServiceProxy
			, siteService         = mockSiteService
			, queueBatchSize      = 10
		);

		service = CreateMock( object=service );

		service.$( "$getPresideObject" ).$args( "asset_generation_queue" ).$results( mockQueueDao );
		service.$( "$getPresideObjectService", mockPoService );
		service.$( "$isInterrupted", false );
		service.$( "$getRequestContext", mockRequestContext );

		return service;
	}

}

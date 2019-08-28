/**
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.services.assetManager.IAssetQueue" {

// CONSTRUCTOR
	/**
	 * @assetManagerService.inject delayedInjector:assetManagerService
	 * @queueBatchSize.inject      coldbox:setting:assetManager.queue.batchSize
	 */
	public any function init( required any assetManagerService, required numeric queueBatchSize ) {
		_setAssetManagerService( arguments.assetManagerService );
		_setQueueBatchSize( arguments.queueBatchSize );

		return this;
	}

// PUBLIC API METHODS
	public void function queueAssetGeneration(
		  required string assetId
		,          string versionId      = ""
		,          string derivativeName = ""
		,          string configHash     = ""
	) {
		try {
			$getPresideObject( "asset_generation_queue" ).insertData( data={
				  asset           = arguments.assetId
				, asset_version   = arguments.versionId
				, derivative_name = arguments.derivativeName
				, config_hash     = arguments.configHash
				, retry_count     = 0
				, queue_status    = "pending"
			} );
		} catch( any e ) {}
	}

	public void function processQueue() {
		var batchSize           = _getQueueBatchSize();
		var processedCount      = 0;
		var assetManagerService = _getAssetManagerService();
		var poService           = $getPresideObjectService();
		var queuedAsset         = "";

		do {
			queuedAsset = getNextQueuedAsset();

			if ( !queuedAsset.count() ) {
				break;
			}

			try {
				assetManagerService.createAssetDerivative(
					  assetId        = queuedAsset.asset
					, versionId      = queuedAsset.asset_version
					, derivativeName = queuedAsset.derivative_name
					, forceIfExists  = true
				);

				removeFromQueue( queuedAsset.id );
			} catch ( any e ) {
				var err = SerializeJson( e );

				if ( queuedAsset.retry_count >= 3 ) {
					failQueue( queuedAsset, err );
				} else {
					reQueue( queuedAsset, err );
				}
			}

		} while( ++processedCount < batchSize && !$isInterrupted() );

		if ( processedCount ) {
			poService.clearRelatedCaches( "asset_generation_queue" );
		}
	}

	/**
	 * Returns the next pending asset derivative ready for generating.
	 *
	 * @autodoc true
	 */
	public struct function getNextQueuedAsset() {
		transaction {
			var takenByOtherProcess = false;
			var queueDao            = $getPresideObject( "asset_generation_queue" );
			var queuedAsset         = queueDao.selectData(
				  selectFields = [ "id", "asset", "asset_version", "derivative_name", "retry_count" ]
				, filter       = "queue_status = :queue_status"
				, filterParams = { queue_status="pending" }
				, orderby      = "retry_count,datecreated"
				, maxRows      = 1
			);

			for( var q in queuedAsset ) {
				var updated = queueDao.updateData(
					  filter       = "id = :id and queue_status = :queue_status"
					, filterParams = { id=q.id, queue_status="pending" }
					, data         = { queue_status = "running" }
				);

				if ( updated ) {
					return q;
				}

				takenByOtherProcess = true;
				break;
			}
		}

		if ( takenByOtherProcess ) {
			return getNextQueuedAsset();
		}

		return {};
	}

	/**
	 * Removes the given queued asset (by id) from the queue.
	 *
	 * @autodoc true
	 * @id.hint ID of the queued asset
	 */
	public numeric function removeFromQueue( required string id ) {
		return $getPresideObject( "asset_generation_queue" ).deleteData( id=arguments.id );
	}

	public numeric function failQueue( required struct asset, required string error ) {
		return $getPresideObject( "asset_generation_queue" ).updateData( id=arguments.asset.id, data={
			  last_error   = arguments.error
			, queue_status = "failed"
		} );
	}

	public numeric function reQueue( required struct asset, required string error ) {
		return $getPresideObject( "asset_generation_queue" ).updateData( id=arguments.asset.id, data={
			  last_error = arguments.error
			, queue_status = "pending"
			, retry_count = arguments.asset.retry_count+1
		} );
	}

	public boolean function isQueued(
		  required string assetId
		, required string derivativeName
		, required string versionId
		, required string configHash
	) {
		return $getPresideObject( "asset_generation_queue" ).dataExists( filter={
			  asset           = arguments.assetId
			, asset_version   = arguments.versionId
			, derivative_name = arguments.derivativeName
			, config_hash     = arguments.configHash
			, queue_status    = [ "pending", "running" ]
		} );
	}

	public query function getFailedItems( string assetId="", numeric maxrows=0 ) {
		var filter = { queue_status = "failed" };

		if ( Len( Trim( arguments.assetId ) ) ) {
			filter.asset = arguments.assetId;
		}

		return $getPresideObject( "asset_generation_queue" ).selectData(
			  selectFields = [ "id", "asset", "asset_version", "derivative_name", "last_error" ]
			, filter       = filter
			, maxRows      = arguments.maxRows
			, orderBy      = "datemodified desc"
		);
	}

	public numeric function dismissFailedItems( string assetId="" ) {
		var filter = { queue_status = "failed" };

		if ( Len( Trim( arguments.assetId ) ) ) {
			filter.asset = arguments.assetId;
		}

		return $getPresideObject( "asset_generation_queue" ).deleteData( filter=filter );
	}

// GETTERS AND SETTERS
	private any function _getAssetManagerService() {
	    return _assetManagerService.get();
	}
	private void function _setAssetManagerService( required any assetManagerService ) {
	    _assetManagerService = arguments.assetManagerService;
	}

	private numeric function _getQueueBatchSize() {
	    return _queueBatchSize;
	}
	private void function _setQueueBatchSize( required numeric queueBatchSize ) {
	    _queueBatchSize = arguments.queueBatchSize;
	}

}
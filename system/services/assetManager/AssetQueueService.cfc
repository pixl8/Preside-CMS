/**
 * @presideService true
 * @singleton      true
 * @feature        assetManager
 */
component implements="preside.system.services.assetManager.IAssetQueue" {

// CONSTRUCTOR
	/**
	 * @assetManagerService.inject delayedInjector:assetManagerService
	 * @siteService.inject         delayedInjector:siteService
	 * @queueBatchSize.inject      coldbox:setting:assetManager.queue.batchSize
	 */
	public any function init(
		  required any     assetManagerService
		, required any     siteService
		, required numeric queueBatchSize
	) {
		_setAssetManagerService( arguments.assetManagerService );
		_setSiteService( arguments.siteService );
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
		var assetContext  = SerializeJson( { site=$getRequestContext().getSiteId() } );
		var alreadyExists = $getPresideObject( "asset_generation_queue" ).dataExists(
			  filter = {
				  asset           = arguments.assetId
				, asset_version   = arguments.versionId
				, derivative_name = arguments.derivativeName
				, config_hash     = arguments.configHash
				, context         = assetContext
			  }
			, extraFilters = [ {
				  filter       = "datecreated > :datecreated"
				, filterParams = { datecreated=DateAdd( "h", -1, Now() ) }
			  } ]
		);

		if ( !alreadyExists ) {
			try {
				$getPresideObject( "asset_generation_queue" ).insertData( data={
					  asset           = arguments.assetId
					, asset_version   = arguments.versionId
					, derivative_name = arguments.derivativeName
					, config_hash     = arguments.configHash
					, context         = assetContext
					, retry_count     = 0
					, queue_status    = "pending"
				} );
			} catch( any e ) {}
		}
	}

	public void function processQueue() {
		var event               = $getRequestContext();
		var currentSiteId       = event.getSiteId();
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
				if ( Len( Trim( queuedAsset.context.site ?: "" ) ) && ( queuedAsset.context.site != currentSiteId ) ) {
					event.setSite( _getSiteService().getSite( queuedAsset.context.site ) );
				}

				assetManagerService.createAssetDerivative(
					  assetId        = queuedAsset.asset
					, versionId      = queuedAsset.asset_version
					, derivativeName = queuedAsset.derivative_name
					, forceIfExists  = true
				);

				removeFromQueue( queuedAsset.id );
			} catch ( any e ) {
				var err = {};
				var errKeys = [ "type", "message", "detail" ];
				for( var k in errKeys ) {
					if ( IsSimpleValue( e[ k ] ?: {} ) ) {
						err[ k ] = e[ k ];
					}
				}

				err = SerializeJson( err );

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
				  selectFields = [ "id", "asset", "asset_version", "derivative_name", "retry_count", "context" ]
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
					q.context = IsJSON( q.context ?: "" ) ? DeserializeJSON( q.context ) : {};

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

	public boolean function deleteExpiredQueuedItems( any logger ) {
		var canLog  = StructKeyExists( arguments, "logger" );
		var canInfo = canLog && arguments.logger.canInfo();

		if ( canInfo ) {
			arguments.logger.info( "Clearing out stuck queued asset derivatives..." );
		}

		var result = $getPresideObject( "asset_generation_queue" ).deleteData(
			  filter = "datecreated < :datecreated and queue_status = :queue_status"
			, filterParams = { datecreated = dateAdd( "d", -1, Now() ), queue_status="running" }
		);

		if ( canInfo ) {
			if ( result ) {
				arguments.logger.info( "Cleared [#NumberFormat( result )#] stuck queued asset derivatives." );

			} else {
				arguments.logger.info( "0 stuck queued asset derivatives to clear." );
			}

			arguments.logger.info( "Clearing out errored generations over 1 month old..." );
		}

		result = $getPresideObject( "asset_generation_queue" ).deleteData(
			  filter       = "datecreated < :datecreated and queue_status = :queue_status"
			, filterParams = { datecreated = dateAdd( "m", -1, Now() ), queue_status="failed" }
		);

		if ( canInfo ) {
			if ( result ) {
				arguments.logger.info( "Cleared [#NumberFormat( result )#] old failed asset derivative generations." );
			} else {
				arguments.logger.info( "0 stuck failed asset derivatives to clear." );
			}
			arguments.logger.info( "Finished cleaning the asset generation queue." );
		}

		return true;
	}

// GETTERS AND SETTERS
	private any function _getAssetManagerService() {
	    return _assetManagerService.get();
	}
	private void function _setAssetManagerService( required any assetManagerService ) {
	    _assetManagerService = arguments.assetManagerService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private numeric function _getQueueBatchSize() {
	    return _queueBatchSize;
	}
	private void function _setQueueBatchSize( required numeric queueBatchSize ) {
	    _queueBatchSize = arguments.queueBatchSize;
	}

}
/**
 * Service to provide batch operation logic. i.e. logic for batch record
 * operations kicked off from datamanager datatables.
 *
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 * @feature        admin
 */
component displayName="Data manager batch operation service" {

// CONSTRUCTOR
	/**
	 *
	 * @customizationService.inject datamanagerCustomizationService
	 * @sessionStorage.inject       sessionStorage
	 */
	public any function init(
		  required any customizationService
		, required any sessionStorage
	) {
		_setCustomizationService( arguments.customizationService );
		_setSessionStorage( arguments.sessionStorage );

		return this;
	}

// PUBLIC METHODS
	public boolean function batchEditField(
		  required string  objectName
		, required string  fieldName
		, required string  value
		,          array   sourceIds          = []
		,          boolean batchAll           = false
		,          struct  batchSrcArgs       = {}
		,          string  multiEditBehaviour = "append"
		,          string  auditAction        = "datamanager_batch_edit_record"
		,          string  auditCategory      = "datamanager"
		,          string  auditUserId        = ""
		,          any     logger
		,          any     progress
	) {
		var pobjService       = $getPresideObjectService();
		var isMultiValue      = pobjService.isManyToManyProperty( arguments.objectName, arguments.fieldName );
		var canLog            = StructKeyExists( arguments, "logger" );
		var canInfo           = canLog && arguments.logger.canInfo();
		var canWarn           = canLog && arguments.logger.canWarn();
		var canReportProgress = StructKeyExists( arguments, "progress" );
		var totalrecords      = ArrayLen( sourceIds );
		var hasLabelField     = Len( pobjService.getLabelField( arguments.objectName ) );
		var processed         = 0;
		var objectTitle       = "";
		var fieldTitle        = "";
		var uriRoot           = "";
		var moreToFetch       = arguments.batchAll;
		var queueId           = "";

		if ( arguments.batchAll ) {
			queueId      = queueBatchOperation( arguments.objectName, arguments.batchSrcArgs );
			totalRecords = getBatchSourceRecordCount( arguments.objectName, arguments.batchSrcArgs );
		}

		if ( canInfo ) {
			uriRoot = pobjService.getResourceBundleUriRoot( arguments.objectName );
			objectTitle = $translateResource( uri=uriRoot & "title.singular", defaultValue=arguments.objectName );
			fieldTitle  = $translateResource( uri=uriRoot & "field.#arguments.fieldName#.title", defaultValue=arguments.fieldName );
			arguments.logger.info( $translateResource( uri="cms:datamanager.batchedit.task.starting.message", data=[ objectTitle, fieldTitle, NumberFormat( totalRecords ) ] ) );
		}

		try {
			do {
				if ( arguments.batchAll ) {
					sourceIds = getNextBatchRecordsFromQueue( queueId );

					if ( !ArrayLen( sourceIds ) ) {
						break;
					}

					if ( canInfo ) {
						arguments.logger.info( $translateResource( uri="cms:datamanager.batchedit.fetched.records", data=[ NumberFormat( ArrayLen( sourceIds ) ) ] ) );
					}

					moreToFetch = ArrayLen( sourceIds ) == 100;
				}

				for( var sourceId in sourceIds ) {
					if ( $isInterrupted() ) {
						if ( canWarn ) { arguments.logger.warn( "Task interrupted. Cancelling." ); }
						break;
					}
					if ( !isMultiValue ) {
						pobjService.updateData(
							  objectName              = objectName
							, data                    = { "#arguments.fieldName#" = value }
							, filter                  = { id=sourceId }
							, clearCaches             = false
							, skipTrivialInterceptors = true
						);
					} else {
						var existingIds  = [];
						var targetIdList = [];
						var newChoices   = ListToArray( arguments.value );

						if ( arguments.multiEditBehaviour != "overwrite" ) {
							var previousData = pobjService.getDeNormalizedManyToManyData(
								  objectName   = objectName
								, id           = sourceId
								, selectFields = [ arguments.fieldName ]
							);
							existingIds = ListToArray( previousData[ arguments.fieldName ] ?: "" );
						}

						switch( arguments.multiEditBehaviour ) {
							case "overwrite":
								targetIdList = newChoices;
								break;
							case "delete":
								targetIdList = existingIds;
								for( var id in newChoices ) {
									targetIdList.delete( id )
								}
								break;
							default:
								targetIdList = existingIds;
								targetIdList.append( newChoices, true );
						}

						targetIdList = targetIdList.toList();
						targetIdList = ListRemoveDuplicates( targetIdList );

						pobjService.updateData(
							  objectName              = objectName
							, id                      = sourceId
							, data                    = { "#arguments.fieldName#" = targetIdList }
							, updateManyToManyRecords = true
							, clearCaches             = false
							, skipTrivialInterceptors = true
						);
					}

					$audit(
						  action   = arguments.auditAction
						, type     = arguments.auditCategory
						, userId   = arguments.auditUserId
						, recordId = sourceid
						, detail   = {
							  objectName = arguments.objectName
							, id         = sourceid
							, fieldName  = arguments.fieldName
							, value      = arguments.value
						}
					);

					processed++
					if ( canReportProgress ) {
						arguments.progress.setProgress( Int( ( 100 / totalrecords ) * processed ) ) ;
					}
				}

				pobjService.clearRelatedCaches( arguments.objectName );

				if ( $isInterrupted() ) {
					break;
				}
			} while( moreToFetch );
		} catch( any e ) {
			if ( Len( queueId ) ) {
				var cleared = clearBatchOperationQueue( queueId );
				if ( canWarn && cleared ) {
					arguments.logger.warn( $translateResource( uri="cms:datamanager.batchedit.task.queue.cancelled", data=[ NumberFormat( cleared ) ] ) );
				}
			}

			rethrow;
		}

		if ( Len( queueId ) ) {
			var cleared = clearBatchOperationQueue( queueId );
			if ( canWarn && cleared ) {
				arguments.logger.warn( $translateResource( uri="cms:datamanager.batchedit.task.queue.cancelled", data=[ NumberFormat( cleared ) ] ) );
			}
		}
		if ( canInfo ) {
			arguments.logger.info( $translateResource( uri="cms:datamanager.batchedit.task.finished.message", data=[ objectTitle, fieldTitle, NumberFormat( processed ) ] ) );
		}

		return true;
	}

	public boolean function batchDeleteRecords(
		  required string  objectName
		,          array   sourceIds    = []
		,          boolean batchAll     = false
		,          struct  batchSrcArgs = {}
		,          boolean audit        = false
		,          string  auditAction  = ""
		,          string  auditType    = ""
		,          string  auditUserId  = ""
		,          any     logger
		,          any     progress
	) {
		var pobjService          = $getPresideObjectService();
		var customizationService = _getCustomizationService();
		var canLog               = StructKeyExists( arguments, "logger" );
		var canInfo              = canLog && arguments.logger.canInfo();
		var canWarn              = canLog && arguments.logger.canWarn();
		var canError             = canLog && arguments.logger.canError();
		var canReportProgress    = StructKeyExists( arguments, "progress" );
		var totalrecords         = ArrayLen( sourceIds );
		var uriRoot              = canLog ? pobjService.getResourceBundleUriRoot( arguments.objectName ) : "";
		var objectTitle          = canLog ? $translateResource( uri=uriRoot & "title.singular", defaultValue=arguments.objectName ) : "";
		var audited              = 0;
		var batchProgress        = 0;
		var args                 = StructCopy( arguments );
		var hasLabelField        = Len( Trim( pobjService.getLabelField( arguments.objectName ) ) );
		var moreToFetch          = arguments.batchAll;
		var recordIds            = [];
		var queueId              = [];

		if ( arguments.batchAll ) {
			queueId      = queueBatchOperation( arguments.objectName, arguments.batchSrcArgs );
			totalRecords = getBatchSourceRecordCount( arguments.objectName, arguments.batchSrcArgs );
		}

		if ( canInfo ) {
			arguments.logger.info( $translateResource( uri="cms:datamanager.batchdelete.task.starting.message", data=[ objectTitle, NumberFormat( totalRecords ) ] ) );
		}

		do {
			if ( $isInterrupted() ) {
				if ( canWarn ) { arguments.logger.warn( "Task interrupted. Cancelling." ); }
				if ( Len( queueId ) ) {
					var cleared = clearBatchOperationQueue( queueId );
					if ( canWarn && cleared ) {
						arguments.logger.warn( $translateResource( uri="cms:datamanager.batchdelete.task.queue.cancelled", data=[ NumberFormat( cleared ) ] ) );
					}
				}
				return false;
			}

			if ( arguments.batchAll ) {
				args.records = pobjService.selectData(
					  objectName    = arguments.objectName
					, filter        = { id=getNextBatchRecordsFromQueue( queueId ) }
					, selectFields  = [ "id", hasLabelField ? "${labelfield} as label" : "id as label" ]
					, useCache      = false
				);
				if ( $isInterrupted() ) {
					if ( canWarn ) { arguments.logger.warn( "Task interrupted. Cancelling." ); }
					var cleared = clearBatchOperationQueue( queueId );
					if ( canWarn && cleared ) {
						arguments.logger.warn( $translateResource( uri="cms:datamanager.batchdelete.task.queue.cancelled", data=[ NumberFormat( cleared ) ] ) );
					}
					return false;
				}

				moreToFetch = args.records.recordCount == 100;

				if ( !args.records.recordCount ) {
					break;
				}

				if ( canInfo ) {
					arguments.logger.info( $translateResource( uri="cms:datamanager.batchdelete.task.fetched.next.batch", data=[ args.records.recordCount ] ) );
				}
			} else {
				// fetch records before deleting (useful for labels rendering in audit logs, etc.)
				args.records = pobjService.selectData( objectName=arguments.objectName, filter={ id=arguments.sourceIds }, selectFields=[
					  "id"
					, hasLabelField ? "${labelfield} as label" : "id as label"
				] );
			}

			// pre delete hooks
			if ( customizationService.objectHasCustomization( arguments.objectName, "preBatchDeleteRecordsAction" ) ) {
				customizationService.runCustomization(
					  objectName = arguments.objectName
					, action     = "preBatchDeleteRecordsAction"
					, args       = args
				);
			}

			recordIds = ValueArray( args.records.id );

			if ( !ArrayLen( recordIds ) ) {
				continue; // interceptor may have blocked these records from being deleted. Let's continue and get the next batch.
			}

			// delete related data
			try {
				pobjService.deleteRelatedData( objectName=objectName, recordId=recordIds );
			} catch( "PresideObjectService.CascadeDeleteTooDeep" e ) {
				if ( canError ) {
					arguments.logger.error( $translateResource( uri="cms:datamanager.cascadeDelete.cascade.too.deep.error", data=[ objectTitle ] ) );
				}
				return false;
			}
			if ( canReportProgress && !arguments.batchAll ) {
				arguments.progress.setProgress( 20 );
			}

			// delete the records
			var deletedCount = pobjService.deleteData( objectName=arguments.objectName, filter={ id = recordIds } );

			if ( !deletedCount ) {
				if ( canReportProgress && !arguments.batchAll ) {
					arguments.progress.setProgress( 100 );
				}
				if ( canWarn ) {
					arguments.logger.warn( $translateResource( uri="cms:datamanager.batchdelete.task.no.records.deleted.message" ) );
				}
			}
			if ( canReportProgress && !arguments.batchAll ) {
				arguments.progress.setProgress( arguments.audit ? 50 : 90 );
			}
			if ( canInfo ) {
				arguments.logger.info( $translateResource( uri="cms:datamanager.batchdelete.task.deleted.records.message", data=[ objectTitle, NumberFormat( deletedCount ) ] ) );
			}

			// audit
			if ( arguments.audit ) {
				for( var record in args.records ) {
					$audit(
						  action   = arguments.auditAction
						, type     = arguments.auditType
						, userId   = arguments.auditUserId
						, recordId = record.id
						, detail   = { id=record.id, label=record.label, objectName=arguments.objectName }
					);

					if ( canReportProgress && !arguments.batchAll ) {
						arguments.progress.setProgress( 50 + Int( ( 50/totalRecords ) * ++audited ) );
					}
				}
			}

			// post delete hooks
			if ( customizationService.objectHasCustomization( arguments.objectName, "postBatchDeleteRecordsAction" ) ) {
				customizationService.runCustomization(
					  objectName = arguments.objectName
					, action     = "postBatchDeleteRecordsAction"
					, args       = args
				);
			}

			// finish up
			if ( !moreToFetch ) {
				if ( canInfo ) {
					arguments.logger.info( $translateResource( uri="cms:datamanager.batchdelete.task.finished" ) );
				}
				if ( canReportProgress ) {
					arguments.progress.setProgress( 100 );
				}
			}

			if ( canReportProgress && moreToFetch ) {
				batchProgress += args.records.recordCount;
				arguments.progress.setProgress( ( 100 / totalRecords ) * batchProgress );
			}
		} while( moreToFetch );

		return true;
	}

	public numeric function getBatchSourceRecordCount( required string objectName, required struct sourceArgs ) {
		return $getPresideObjectService().selectData(
			  argumentCollection = arguments.sourceArgs
			, objectName         = arguments.objectName
			, recordCountOnly    = true
		);
	}

	public string function queueBatchOperation(
		  required string objectName
		, required struct batchSrcArgs
	) {
		var pobjService   = $getPresideObjectService();
		var queueDataArgs = StructCopy( arguments.batchSrcArgs );
		var dbAdapter     = pobjService.getDbAdapterForObject( arguments.objectName );
		var idField       = dbAdapter.escapeEntity( arguments.objectName & "." & pobjService.getIdField( arguments.objectName ) );
		var queueId       = CreateUUId();

		queueDataArgs.selectFields = [
			  "'#queueId#'"
			, idField
			, dbAdapter.getNowFunctionSql()
		];
		StructDelete( queueDataArgs, "extraSelectFields" );

		pobjService.insertDataFromSelect(
			  objectName     = "batch_operation_queue"
			, fieldList      = [ "queue_id", "record_id", "datecreated" ]
			, selectDataArgs = queueDataArgs
		);

		return queueId;
	}

	public numeric function getBatchOperationQueueSize( required string queueId ) {
		return $getPresideObjectService().selectData(
			  objectName      = "batch_operation_queue"
			, filter          = { queue_id=arguments.queueId }
			, recordCountOnly = true
		);
	}

	public numeric function clearBatchOperationQueue( required string queueId ) {
		return $getPresideObjectService().deleteData(
			  objectName              = "batch_operation_queue"
			, filter                  = { queue_id=arguments.queueId }
			, skipTrivialInterceptors = true
		);
	}

	public numeric function removeBatchOperationQueueItems( required string queueId, required any recordId ) {
		return $getPresideObjectService().deleteData(
			  objectName              = "batch_operation_queue"
			, filter                  = { queue_id=arguments.queueId, record_id=arguments.recordId }
			, skipTrivialInterceptors = true
		);
	}

	public array function getNextBatchRecordsFromQueue( required string queueId, numeric maxRows=100, boolean clearImmediately=true ) {
		var fetched = $getPresideObjectService().selectData(
			  objectname   = "batch_operation_queue"
			, selectFields = [ "record_id" ]
			, maxRows      = arguments.maxRows
			, filter       = { queue_id=arguments.queueId }
		);

		if ( !fetched.recordCount ) {
			return [];
		}

		var recordIds = ValueArray( fetched.record_id );
		if ( arguments.clearImmediately ) {
			removeBatchOperationQueueItems( arguments.queueId, recordIds );
		}

		return recordIds;
	}

	public boolean function deleteExpiredOperationQueues( any logger ) {
		var canLog       = StructKeyExists( arguments, "logger" );
		var canInfo      = canLog && arguments.logger.canInfo();
		var cutoffDate   = DateAdd( "d", -2, Now() );
		var deletedCount = $getPresideObjectService().deleteData(
			  objectName   = "batch_operation_queue"
			, filter       = "datecreated <= :datecreated"
			, filterParams = { datecreated=cutoffDate }
		);

		if ( canInfo ) {
			if ( deletedCount ) {
				arguments.logger.info( "[#NumberFormat( deletedCount )#] queued operations cleaned up." );
			} else {
				arguments.logger.info( "No queued operations to cleanup." );
			}
		}

		return true;
	}

	public string function prepareBatchSourceString( required struct selectDataArgs ) {
		StructDelete( arguments.selectDataArgs, "maxRows" );
		StructDelete( arguments.selectDataArgs, "startRow" );
		StructDelete( arguments.selectDataArgs, "orderBy" );

		var serialized        = SerializeJson( selectDataArgs );
		var obfuscated        = ToBase64( serialized );
		var hashForValidation = Hash( obfuscated );

		_getSessionStorage().setVar( hashForValidation, 1 ); // later we will validate inputs against present session vars

		return obfuscated;
	}

	public struct function deserializeBatchSourceString( required string batchSrcArgs ) {
		if ( areBatchSourceArgsValid( arguments.batchSrcArgs ) ) {
			try {
				return DeserializeJson( ToString( ToBinary( arguments.batchSrcArgs ) ) );
			} catch( any e ) {
				$raiseError( e );
			}
		}

		return {};
	}

	public boolean function areBatchSourceArgsValid( required string batchSrcArgs ) {
		if ( Len( Trim( arguments.batchSrcArgs ) ) ) {
			var hashForValidation = Hash( arguments.batchSrcArgs );

			return _getSessionStorage().exists( hashForValidation );
		}

		return false;
	}

// GETTERS AND SETTERS
	private any function _getCustomizationService() {
	    return _customizationService;
	}
	private void function _setCustomizationService( required any customizationService ) {
	    _customizationService = arguments.customizationService;
	}

	private any function _getSessionStorage() {
	    return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
	    _sessionStorage = arguments.sessionStorage;
	}
}

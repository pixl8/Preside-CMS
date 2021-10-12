/**
 * Service to provide batch operation logic. i.e. logic for batch record
 * operations kicked off from datamanager datatables.
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component displayName="Data manager batch operation service" {

// CONSTRUCTOR
	/**
	 *
	 * @customizationService.inject datamanagerCustomizationService
	 */
	public any function init(
		required any customizationService
	) {
		_setCustomizationService( arguments.customizationService );

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
					sourceIds = getNextBatchRecordsFromQueue( queueId, 100 );

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
							  objectName = objectName
							, data       = { "#arguments.fieldName#" = value }
							, filter     = { id=sourceId }
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
						);
					}

					$audit(
						  action   = arguments.auditAction
						, type     = arguments.auditCategory
						, userId   = arguments.auditUserId
						, recordId = sourceid
						, detail   = Duplicate( arguments )
					);

					if ( arguments.batchAll ) {
						removeBatchOperationQueueItem( queueId, sourceId );
					}

					if ( canReportProgress ) {
						arguments.progress.setProgress( Int( ( 100 / totalrecords ) * ++processed ) ) ;
					}
				}

				if ( $isInterrupted() ) {
					break;
				}
			} while( moreToFetch );
		} catch( any e ) {
			if ( Len( queueId ) ) {
				clearBatchOperationQueue( queueId );
			}

			rethrow;
		}

		if ( Len( queueId ) ) {
			clearBatchOperationQueue( queueId );
		}
		if ( canInfo ) {
			arguments.logger.info( $translateResource( uri="cms:datamanager.batchedit.task.finished.message", data=[ objectTitle, fieldTitle, NumberFormat( totalRecords ) ] ) );
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
					clearBatchOperationQueue( queueId );
				}
				return false;
			}

			if ( arguments.batchAll ) {
				args.records = pobjService.selectData(
					  objectName    = arguments.objectName
					, filter        = { id=getNextBatchRecordsFromQueue( queueId, 100 ) }
					, selectFields  = [ "id", hasLabelField ? "${labelfield} as label" : "id as label" ]
					, useCache      = false
				);
				if ( $isInterrupted() ) {
					if ( canWarn ) { arguments.logger.warn( "Task interrupted. Cancelling." ); }
					clearBatchOperationQueue( queueId )
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

			recordIds = ValueArray( args.records.id );


			// pre delete hooks
			if ( customizationService.objectHasCustomization( arguments.objectName, "preDeleteRecordAction" ) ) {
				if ( canInfo ) {
					arguments.logger.info( $translateResource( uri="cms:datamanager.batchdelete.task.pre.delete.hooks" ) );
				}
				customizationService.runCustomization(
					  objectName = arguments.objectName
					, action     = "preDeleteRecordAction"
					, args       = args
				);
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
				return true;
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
			if ( customizationService.objectHasCustomization( arguments.objectName, "postDeleteRecordAction" ) ) {
				customizationService.runCustomization(
					  objectName = arguments.objectName
					, action     = "postDeleteRecordAction"
					, args       = args
				);
			}

			// remove queued items
			if ( Len( queueId ) ) {
				removeBatchOperationQueueItem( queueId, recordIds );
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
		var idField       = dbAdapter.escapeEntity( pobjService.getIdField( arguments.objectName ) );
		var queueId       = CreateUUId();

		queueDataArgs.selectFields = [
			  "'#queueId#'"
			, idField
			, dbAdapter.getNowFunctionSql()
		];

		pobjService.insertDataFromSelect(
			  objectName     = "batch_operation_queue"
			, fieldList      = [ "queue_id", "record_id", "datecreated" ]
			, selectDataArgs = queueDataArgs
		);

		return queueId;
	}

	public numeric function clearBatchOperationQueue( required string queueId ) {
		return $getPresideObjectService().deleteData(
			  objectName = "batch_operation_queue"
			, filter     = { queue_id=arguments.queueId }
		);
	}

	public numeric function removeBatchOperationQueueItem( required string queueId, required any recordId ) {
		return $getPresideObjectService().deleteData(
			  objectName = "batch_operation_queue"
			, filter     = { queue_id=arguments.queueId, record_id=arguments.recordId }
		);
	}

	public array function getNextBatchRecordsFromQueue( required string queueId, numeric maxRows=100 ) {
		var fetched = $getPresideObjectService().selectData(
			  objectname   = "batch_operation_queue"
			, selectFields = [ "record_id" ]
			, maxRows      = arguments.maxRows
			, filter       = { queue_id=arguments.queueId }
		);

		if ( !fetched.recordCount ) {
			return [];
		}

		return ValueArray( fetched.record_id );
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

// GETTERS AND SETTERS
	private any function _getCustomizationService() {
	    return _customizationService;
	}
	private void function _setCustomizationService( required any customizationService ) {
	    _customizationService = arguments.customizationService;
	}
}

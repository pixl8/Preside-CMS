component {
	property name="dataManagerService"       inject="DataManagerService";
	property name="scheduledExportService"   inject="ScheduledExportService";
	property name="dataExportService"        inject="DataExportService";
	property name="rulesEngineFilterService" inject="RulesEngineFilterService";
	property name="reportStorageProvider"    inject="ScheduledExportStorageProvider";

	private boolean function runScheduledExport( event, rc, prc, args={} ) {
		var historyId = args.historyExportId   ?: "";
		var reportId  = args.scheduledExportId ?: "";

		if ( !isEmpty( reportId ) and !isEmpty( historyId ) ) {
			var savedReportDetail = scheduledExportService.getExportDetail( reportId );

			if ( !isEmpty( savedReportDetail ) ) {
				var exporterDetail    = dataExportService.getExporterDetails( savedReportDetail.exporter ?: "CSV" );
				var configArgs        = {
					  exporter       = savedReportDetail.exporter ?: "CSV"
					, objectName     = savedReportDetail.object_name
					, selectFields   = listToArray( savedReportDetail.fields       ?: "" )
					, savedFilters   = listToArray( savedReportDetail.saved_filter ?: "" )
					, autoGroupBy    = true
					, orderBy        = savedReportDetail.order_by
					, exportFileName = savedReportDetail.file_name
					, mimetype       = exporterDetail.mimeType
					, extraFilters   = []
				};

				try {
					configArgs.extraFilters.append( rulesEngineFilterService.prepareFilter(
						  objectName      = savedReportDetail.object_name
						, expressionArray = DeSerializeJson( savedReportDetail.filter )
					) );
				} catch( any e ){}

				for( var filter in configArgs.savedFilters ) {
						try {
							configArgs.extraFilters.append( rulesEngineFilterService.prepareFilter(
								  objectName = savedReportDetail.object_name
								, filterId   = filter
							) );
						} catch( any e ){}
					}

				if ( len( trim( savedReportDetail.search_query ?: "" ) ) ) {
					try {
						configArgs.extraFilters.append( {
		 					  filter       = dataManagerService.buildSearchFilter(
		 						  q            = savedReportDetail.search_query
		 						, objectName   = savedReportDetail.object_name
		 						, gridFields   = dataManagerService.listGridFields( savedReportDetail.object_name )
		 						, searchFields = dataManagerService.listSearchFields( savedReportDetail.object_name )
		 					  )
		 					, filterParams = { q = { type="varchar", value="%" & rc.searchQuery & "%" } }
		 				} );
					} catch (any e) {}
				}

				var exportedFile = dataExportService.exportData( argumentCollection=configArgs );

				if ( !isEmpty( exportedFile ) ) {
					var filePath = "#savedReportDetail.file_name# #dateTimeFormat( now() )#.#exporterDetail.fileExtension#";

					reportStorageProvider.putObject( object=fileReadBinary( exportedFile ), path=filePath );
					scheduledExportService.saveFilePathToHistoryExport( filepath=filePath, historyExportId=historyId );
					scheduledExportService.sendExportedFileToRecipient( historyExportId=historyId );

					return true;
				}
			}
		}

		return false;
	}
}
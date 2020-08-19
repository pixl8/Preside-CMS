component {
	property name="dataManagerService"       inject="DataManagerService";
	property name="scheduledExportService"   inject="ScheduledExportService";
	property name="dataExportService"        inject="DataExportService";
	property name="rulesEngineFilterService" inject="RulesEngineFilterService";
	property name="exportStorageProvider"    inject="ScheduledExportStorageProvider";

	private boolean function runScheduledExport( event, rc, prc, args={} ) {
		var historyId = args.historyExportId   ?: "";
		var exportId  = args.scheduledExportId ?: "";

		if ( !isEmpty( exportId ) and !isEmpty( historyId ) ) {
			var savedExportDetail = scheduledExportService.getExportDetail( exportId );

			if ( !isEmpty( savedExportDetail ) ) {
				var exporterDetail    = dataExportService.getExporterDetails( savedExportDetail.exporter ?: "CSV" );
				var configArgs        = {
					  exporter           = savedExportDetail.exporter ?: "CSV"
					, objectName         = savedExportDetail.object_name
					, selectFields       = listToArray( savedExportDetail.fields       ?: "" )
					, savedFilters       = listToArray( savedExportDetail.saved_filter ?: "" )
					, exportFilterString = savedExportDetail.filter_string ?: ""
					, autoGroupBy        = true
					, orderBy            = savedExportDetail.order_by
					, exportFileName     = savedExportDetail.file_name
					, mimetype           = exporterDetail.mimeType
					, extraFilters       = []
				};

				try {
					configArgs.extraFilters.append( rulesEngineFilterService.prepareFilter(
						  objectName      = savedExportDetail.object_name
						, expressionArray = DeSerializeJson( savedExportDetail.filter )
					) );
				} catch( any e ){}

				for( var filter in configArgs.savedFilters ) {
					try {
						configArgs.extraFilters.append( rulesEngineFilterService.prepareFilter(
							  objectName = savedExportDetail.object_name
							, filterId   = filter
						) );
					} catch( any e ){}
				}

				if ( len( trim( savedExportDetail.search_query ?: "" ) ) ) {
					try {
						configArgs.extraFilters.append(
		 					dataManagerService.buildSearchFilter(
		 						  q            = savedExportDetail.search_query
		 						, objectName   = savedExportDetail.object_name
		 						, gridFields   = dataManagerService.listGridFields( savedExportDetail.object_name )
		 						, searchFields = dataManagerService.listSearchFields( savedExportDetail.object_name )
		 						, expandTerms  = true
		 					)
		 				);
					} catch (any e) {}
				}

				var exportedFile = dataExportService.exportData( argumentCollection=configArgs );

				if ( !isEmpty( exportedFile ) ) {
					var filePath = "#savedExportDetail.file_name# #dateTimeFormat( now() )#.#exporterDetail.fileExtension#";

					exportStorageProvider.putObject( object=fileReadBinary( exportedFile ), path=filePath );
					scheduledExportService.saveFilePathToHistoryExport( filepath=filePath, historyExportId=historyId );
					scheduledExportService.sendExportedFileToRecipient( historyExportId=historyId );

					return true;
				}
			}
		}

		return false;
	}
}
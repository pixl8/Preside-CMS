component {
	property name="dataManagerService"       inject="DataManagerService";
	property name="scheduledReportService"   inject="ScheduledReportService";
	property name="savedReportService"       inject="SavedReportService";
	property name="dataExportService"        inject="DataExportService";
	property name="rulesEngineFilterService" inject="RulesEngineFilterService";
	property name="reportStorageProvider"    inject="ScheduledReportStorageProvider";

	private boolean function runScheduledReportExport( event, rc, prc, args={} ) {
		var historyId = args.historyExportId   ?: "";
		var reportId  = args.scheduledReportId ?: "";

		if ( !isEmpty( reportId ) and !isEmpty( historyId ) ) {
			var exportDetail    = getPresideObject( "scheduled_report_export" ).selectData( id=reportId );

			if ( exportDetail.recordcount ) {
				var savedReportDetail = savedReportService.getSavedReportDetail( exportDetail.saved_report );

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
						scheduledReportService.saveFilePathToHistoryExport( filepath=filePath, historyExportId=historyId );
						scheduledReportService.sendExportedReportToRecipient( historyExportId=historyId );

						return true;
					}
				}
			}
		}

		return false;
	}
}
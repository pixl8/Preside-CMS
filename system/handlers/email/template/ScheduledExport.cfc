component {
	private struct function prepareParameters( required string filepath, string savedExportName="" ) {
		var downloadLink = event.buildLink(
			  fileStorageProvider = "ScheduledExportStorageProvider"
			, fileStoragePath     = "/#arguments.filepath#"
		);

		return {
			  export_download_link = downloadLink
			, export_filename      = arguments.filepath
			, saved_export_name    = arguments.savedExportName
		};
	}

	private struct function getPreviewParameters() {
		return {
			  export_download_link = event.getBaseUrl() & "/dummy/exportedFile.csv"
			, export_filename      = "Active contact export"
			, saved_export_name    = "Contact Export"
		};
	}

	private string function defaultSubject() {
		return "Scheduled export: ${saved_export_name}";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/scheduledExport/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/scheduledExport/defaultTextBody" );
	}
}
component {
	private struct function prepareParameters( required string filepath ) {
		var downloadLink = event.buildLink(
			  fileStorageProvider = "ScheduledReportStorageProvider"
			, fileStoragePath     = "/#arguments.filepath#"
		);

		return { report_download_link=downloadLink };
	}

	private struct function getPreviewParameters() {
		return { report_download_link=event.getBaseUrl() & "/dummy/exportedReport.csv" };
	}

	private string function defaultSubject() {
		return "Scheduled report export";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/scheduledReportExport/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/scheduledReportExport/defaultTextBody" );
	}
}
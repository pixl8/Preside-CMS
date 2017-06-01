component {
	property name="dataExportService" inject="dataExportService";

	public string function index( event, rc, prc, args={} ) {
		args.exporters = dataExportService.listExporters();

		return renderView( view="formcontrols/dataExporterPicker/index", args=args );
	}
}
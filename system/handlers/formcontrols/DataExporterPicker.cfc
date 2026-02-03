/**
 * @feature presideForms and dataExport
 */
component {
	property name="dataExportService" inject="dataExportService";

	public string function index( event, rc, prc, args={} ) {
		var allowedExporters = ListToArray( args.allowedExporters ?: "" );

		args.exporters = Duplicate( dataExportService.listExporters() );

		if ( ArrayLen( allowedExporters ) ) {
			for( var i=ArrayLen( args.exporters ); i>0; i-- ) {
				if ( !ArrayFindNoCase( allowedExporters, args.exporters[ i ].id ) ) {
					ArrayDeleteAt( args.exporters, i );
				}
			}
		}

		return renderView( view="formcontrols/dataExporterPicker/index", args=args );
	}
}
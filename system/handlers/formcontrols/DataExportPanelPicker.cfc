component extends="preside.system.handlers.formcontrols.MultiSelectPanel" {
	property name="dataExportService" inject="DataExportService";

	public string function index( event, rc, prc, args={} ) {
		args.useObjProperties = true;
		args.sortable         = true;
		args.object           = args.exportObject ?: ( prc.record.object_name ?: ( rc.object ?: "" ) );

		if ( !isEmptyString( args.object ) ) {
			args.defaultValue = Len( args.defaultValue ?: "" ) ? args.defaultValue : dataExportService.getDefaultExportFieldsForObject( args.object ).selectFields.toList();
		}

		return super.index( argumentCollection=arguments );
	}
}
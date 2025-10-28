/**
 * @feature datamanagerworkflow
 */
component {

	property name="datamanagerWorkflowService" inject="datamanagerWorkflowService";

	private string function default( event, rc, prc, args={} ){
		if ( ListLen( args.data ?: "", "." ) > 1 ) {
			return datamanagerWorkflowService.renderStatus(
				  objectName  = ListFirst( args.data, "." )
				, recordId    = ListRest( args.data, "." )
			);
		}

		return args.data ?: "";
	}
}
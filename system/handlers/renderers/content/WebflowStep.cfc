/**
 * @feature webflow
 */
component {

	property name="webflowConfigurationService" inject="webflowConfigurationService";

	private string function default( event, rc, prc, args={} ){
		return args.data ?: "";
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		var stepId    = args.data ?: "";
		var webflowId = args.record.webflow_id ?: "";
		var posType   = args.record.position_type ?: "";
		var label     = webflowConfigurationService.getStepLabel( stepId, webflowId );
		var icon      = "fa-globe light-grey";

		if ( Len( Trim( webflowId ) ) && Len( Trim( posType ) ) ) {
			icon = translateResource( uri="enum.webflowPositionType:#posType#.iconClass", defaultValue=icon );
		}

		return '<i class="fa fa-fw #icon#"></i> &nbsp;' & label;
	}
}
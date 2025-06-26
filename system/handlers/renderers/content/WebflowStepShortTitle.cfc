/**
 * @feature webflow
 */
component {

	property name="webflowConfigurationService" inject="webflowConfigurationService";

	private string function default( event, rc, prc, args={} ){
		return args.data ?: "";
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		var title = args.data ?: "";

		if ( Len( Trim( title ) ) ) {
			return title;
		}

		try {
			var config = webflowConfigurationService.getStepCopy(
				  webflowId   = args.record.webflow_id   ?: ""
				, stepId      = args.record.step_id      ?: ""
				, instanceRef = args.record.instance_ref ?: ""
			);
		} catch( any e ) {}

		if ( Len( Trim( config.short_title ?: "" ) ) ) {
			return "<em class=""light-grey"">#config.short_title#</em>";
		}

		return "";
	}
}
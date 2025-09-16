/**
 * @feature webflow
 */
component {

	property name="webflowConfigurationService" inject="webflowConfigurationService";

	private string function default( event, rc, prc, args={} ){
		return renderContent( "richeditor", args.data ?: "" );
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		var intro = args.data ?: "";

		if ( !Len( Trim( intro ) ) ) {
			try {
				var config = webflowConfigurationService.getStepCopy(
					  webflowId   = args.record.webflow_id   ?: ""
					, stepId      = args.record.step_id      ?: ""
					, instanceRef = args.record.instance_ref ?: ""
				);
			} catch( any e ) {}

			if ( Len( Trim( config.intro ?: "" ) ) ) {
				return "<em class=""light-grey"">#abbreviate( config.intro, 60 )#</em>";
			}
		}

		return abbreviate( intro, 60 );
	}
}
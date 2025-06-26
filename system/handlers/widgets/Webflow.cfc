/**
 * @feature webflow
 */
component {

	property name="webflowConfigDao" inject="presidecms:object:webflow_configuration";

	private string function index( event, rc, prc, args={} ) {
		var webflow = webflowConfigDao.selectData( id=args.webflow_configuration ?: "", selectFields=[ "webflow_id", "instance_ref" ] );

		if ( webflow.recordCount ) {
			return renderWebflow(
				  webflowId   = webflow.webflow_id
				, instanceRef = webflow.instance_ref
			);
		}

		return "";
	}

	private string function placeholder( event, rc, prc, args={} ) {
		var webflowName = renderLabel( "webflow_configuration", args.webflow_configuration ?: "" );

		if ( Len( Trim( webflowName ) ) ) {
			return translateResource( uri="widgets.webflow:placeholder", data=[ webflowName ] );
		}
		return translateResource( uri="widgets.webflow:title" );
	}
}
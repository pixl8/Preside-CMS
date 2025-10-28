/**
 * @feature webflow
 */
component extends="preside.system.handlers.formcontrols.ObjectPicker" {

	property name="webflowSpecLibrary" inject="WebflowSpecLibrary";

	public string function index( event, rc, prc, args={} ) {
		var webflows = webflowSpecLibrary.getAllWebflows();

		if( !StructIsEmpty( webflows ) ) {
			arguments.args.filterBy  = "webflow_id";
			arguments.args.savedData = {
				webflow_id = StructKeyArray( webflows )
			};
		}

		return super.index( event=arguments.event, rc=arguments.rc, prc=arguments.prc, args=arguments.args );
	}

}

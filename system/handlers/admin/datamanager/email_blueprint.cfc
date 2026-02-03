/**
 * @feature admin and emailCenter
 */
component {

	property name="templateCache" inject="cachebox:emailTemplateCache";

	private void function postAddRecordAction( event, rc, prc, args={} ) {
		templateCache.clearAll();
	}
	private void function postEditRecordAction( event, rc, prc, args={} ) {
		templateCache.clearAll();
	}

}
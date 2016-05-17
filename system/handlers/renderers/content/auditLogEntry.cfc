component  {

	property name="AuditService" inject="AuditService";

	private string function default( event, rc, prc, args={} ) {
		return translateResource( uri="cms:auditTrail.#args.action#.message", data = [arguments.args.detail, datetimeformat(arguments.args.datecreated,"medium")] )
	}
}
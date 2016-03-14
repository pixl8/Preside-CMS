component  {

	property name="AuditService" inject="AuditService";

	private string function loginSuccess( event, rc, prc, args={} ) {
		var auditTrailId  = args.id ?: ""
		var records       = AuditService.getAuditTrail( auditTrailId );

		return renderView( view="/renderers/content/auditLogEntry/loginSuccess", args=args );
	}

}
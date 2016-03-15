component  {

	property name="AuditService" inject="AuditService";

	private string function default( event, rc, prc, args={} ) {
		var auditTrailId  = args.id ?: ""
		var records       = AuditService.getAuditTrail( auditTrailId );

		return renderView( view="/renderers/content/auditLogEntry/default", args=args );
	}

	private string function login_success( event, rc, prc, args={} ) {
		var auditTrailId  = args.id ?: ""
		var records       = AuditService.getAuditTrail( auditTrailId );

		return renderView( view="/renderers/content/auditLogEntry/default", args=args );
	}

	private string function logout_success( event, rc, prc, args={} ) {
		var auditTrailId  = args.id ?: ""
		var records       = AuditService.getAuditTrail( auditTrailId );

		return renderView( view="/renderers/content/auditLogEntry/default", args=args );
	}

	private string function deleteRecord( event, rc, prc, args={} ) {
		var auditTrailId  = args.id ?: ""
		var records       = AuditService.getAuditTrail( auditTrailId );

		return renderView( view="/renderers/content/auditLogEntry/default", args=args );
	}

}
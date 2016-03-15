component  {

	property name="AuditService" inject="AuditService";

	private string function default( event, rc, prc, args={} ) {
		var auditLogId  = args.id ?: ""
		var auditLog    = AuditService.getAuditLog( auditLogId );

		return renderView( view="/renderers/content/auditLogEntry/default", args=args );
	}
}
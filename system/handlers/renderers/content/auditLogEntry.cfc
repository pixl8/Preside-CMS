component  {

	property name="AuditService" inject="AuditService";

	private string function default( event, rc, prc, args={} ) {
		var data         = deserializeJSON(args.data);
		var auditTrailId = data.id ?: ""
		var records      = AuditService.getAuditTrail( auditTrailId );

        return renderView( view="/renderers/content/auditLogEntry/default", args=args );
    }

}
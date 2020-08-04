component extends="coldbox.system.Interceptor" {
	property name="loginService" inject="provider:LoginService";
	property name="auditService" inject="provider:AuditService";

	public void function configure() {}

	public void function preDownloadFile( event, interceptData ) {
		var rc              = event.getCollection();
		var storageProvider = rc.storageProvider ?: "";
		var storagePath     = rc.storagePath     ?: "";
		var filename        = rc.filename        ?: ListLast( storagePath, "/" );

		if ( storageProvider == "ScheduledExportStorageProvider" ) {
			if ( !loginService.isLoggedIn() ) {
				event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
			}

			auditService.log(
				  userId = loginService.getLoggedInUserId()
				, action = "download_exported_file"
				, type   = "savedexport"
				, detail = { file=filename }
			);
		}
	}
}
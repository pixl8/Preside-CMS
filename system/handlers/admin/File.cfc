/**
 * @feature admin and dataExport
 */

component extends="preside.system.base.adminHandler" {

	public void function download( event, rc, prc, args={} ) {
		var file = Trim( rc?.file );

		if ( Len( file ) ) {
			prc.requestedFile = ToString( ToBinary( file ) );
		}

		prc.pageIcon  = "download";
		prc.pageTitle = translateResource( uri="cms:file.download.title" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:file.download.title" )
			, link  = ""
		);
	}

}
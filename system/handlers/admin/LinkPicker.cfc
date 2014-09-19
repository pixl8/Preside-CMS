component extends="preside.system.base.AdminHandler" output=false {

	property name="presideObjectService" inject="presideObjectService";

	function index( event, rc, prc ) output=false {
		event.setLayout( "adminModalDialog" );
		event.setView( "admin/linkPicker/index" );
	}

	function quickAddForm( event, rc, prc ) output=false {
		if ( !hasCmsPermission( permissionKey="presideobject.link.add" ) ) {
			event.adminAccessDenied();
		}

		event.include( "/js/admin/specific/linkpicker/" );
		event.include( "/js/admin/specific/datamanager/quickAddForm/" );
		event.include( "/css/admin/specific/quickLinkForms/" );
		event.setView( view="/admin/linkpicker/quickAddForm", layout="adminModalDialog" );
	}

	function quickEditForm( event, rc, prc ) output=false {
		var id     = rc.id     ?: "";

		if ( !hasCmsPermission( permissionKey="presideobject.link.edit" ) ) {
			event.adminAccessDenied();
		}

		prc.record = presideObjectService.selectData( objectName="link", filter={ id=id }, useCache=false );
		if ( prc.record.recordCount ) {
			prc.record = queryRowToStruct( prc.record );
		} else {
			prc.record = {};
		}

		event.include( "/js/admin/specific/linkpicker/" );
		event.include( "/js/admin/specific/datamanager/quickEditForm/" );
		event.include( "/css/admin/specific/quickLinkForms/" );
		event.setView( view="/admin/linkpicker/quickEditForm", layout="adminModalDialog" );
	}

}
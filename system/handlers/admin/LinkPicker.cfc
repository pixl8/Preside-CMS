component extends="preside.system.base.AdminHandler" output=false {

	function index( event, rc, prc ) output=false {
		event.setLayout( "adminModalDialog" );
		event.setView( "admin/linkPicker/index" );
	}

	function quickAddForm( event, rc, prc ) output=false {
		if ( !hasPermission( permissionKey="presideobject.link.add" ) ) {
			event.adminAccessDenied();
		}

		event.include( "/js/admin/specific/linkpicker/" );
		event.include( "/js/admin/specific/datamanager/quickAddForm/" );
		event.setView( view="/admin/linkpicker/quickAddForm", layout="adminModalDialog" );
	}

	function quickEditForm( event, rc, prc ) output=false {
		if ( !hasPermission( permissionKey="presideobject.link.edit" ) ) {
			event.adminAccessDenied();
		}

		event.include( "/js/admin/specific/linkpicker/" );
		event.include( "/js/admin/specific/datamanager/quickEditForm/" );
		event.setView( view="/admin/linkpicker/quickEditForm", layout="adminModalDialog" );
	}

}
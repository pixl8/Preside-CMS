component extends="preside.system.base.AdminHandler" output=false {

	function index( event, rc, prc ) output=false {
		event.setLayout( "adminModalDialog" );
		event.setView( "admin/linkPicker/index" );
	}

	function quickAdd( event, rc, prc ) output=false {
		event.include( "/js/admin/specific/quicklinkpicker/" );
		event.setLayout( "adminModalDialog" );
		event.setView( "admin/linkPicker/quickAdd" );

	}

	function quickEdit( event, rc, prc ) output=false {
		event.include( "/js/admin/specific/quicklinkpicker/" );
		event.setLayout( "adminModalDialog" );
		event.setView( "admin/linkPicker/quickEdit" );
	}


}
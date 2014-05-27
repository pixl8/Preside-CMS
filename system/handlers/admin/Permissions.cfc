component extends="preside.system.base.AdminHandler" output=false {

	private function contextPermsForm( event, rc, prc, viewletArgs={} ) output=false {
		// TODO, get all the necessary data here
		return renderView( view="admin/permissions/contextPermsForm", args=viewletArgs );
	}

	function saveContextPermsAction( event, rc, prc ) output=false {

	}

}
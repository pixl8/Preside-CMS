component extends="preside.system.base.AdminHandler" output=false {

	function temporarilyStoreData( event, rc, prc ) output=false {
		var data  = event.getCollectionWithoutSystemVars();
		var flash = getController().getRequestService().getFlashScope();

		flash.putAll( map=data, saveNow=true );

		event.renderData( data={ ok=true }, type="JSON" );
	}

}
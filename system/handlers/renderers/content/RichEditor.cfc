component output=false {
	property name="widgetsService" inject="widgetsService";

	public string function default( event, rc, prc, viewletArgs={} ){
		return widgetsService.renderEmbeddedWidgets(
			richContent = ( viewletArgs.data ?: "" )
		);
	}

}
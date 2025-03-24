component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		return arguments.value;
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		return "answer";
	}

}
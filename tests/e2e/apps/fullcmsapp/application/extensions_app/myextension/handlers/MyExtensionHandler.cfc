component {

	function customTags() {
		var output = "";

		savecontent variable="output" {
			include "/application/extensions_app/myextension/views/customtags/index.cfm";
		}

		event.renderData( data=output, type="plain" );
	}

}

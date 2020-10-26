/**
 * Handler for rules engine to retrieve a select list of columns for a matrix question
 *
 */
component {

	property name="formBuilderService"   inject="formBuilderService";
	property name="presideObjectService" inject="presideObjectService";
	property name="assetManagerService"  inject="assetManagerService";
	property name="assetTypes" inject="coldbox:setting:assetManager.types";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var extensions = ListToArray( Trim( value ) );

		if ( !extensions.len() ) {
			return config.defaultLabel ?: "";
		}

		var labels=[];
		for (var extension in extensions) {
			var type = extension.replace(".", "");
			labels.append(translateResource( "filetypes:#type#.picker.label" ) );
		}

		return arrayToList(labels)
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var questionId = config.question ?: ( rc.question ?: "" );

		rc.delete( "value" );

		var theQuestion = formBuilderService.getQuestion( questionId );
		var label     = translateResource( "cms:rulesEngine.fieldtype.select.config.label" );

		if ( len( theQuestion ) ) {
			var questionConfig = DeserializeJson( theQuestion.item_type_config );
			var accept = [];
			if ( len( trim( questionConfig.accept?:"" ) ) ) {
				accept = ListToArray( questionConfig.accept ?: "", "," );
				accept = assetManagerService.expandTypeList( accept );
			} else {
				for (var assetType in assetTypes) {
					for (var type in assetTypes[assetType]) {
						accept.append( type );
					}
				}
			}

			var values = [];
			var labels = [];
			for ( var fileType in accept ) {
				arrayAppend( values, ".#fileType#" );
				arrayAppend( labels, translateResource( "filetypes:#fileType#.picker.label" )  );
			}


			return renderFormControl(
				  argumentCollection = arguments.config
				, name               = "value"
				, type               = "select"
				, values             = values
				, labels             = labels
				, multiple           = true
				, label              = label
				, savedValue         = arguments.value
				, defaultValue       = arguments.value
				, required           = true
			);

			//arrayAppend( labels, translateResource( “filetypes:#fileType#.picker.label” ) );
		}

		return '<p class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> #translateResource( "cms:rulesEngine.fieldtype.formbuilderQuestionFileUploadType.no.choices.warning" )#</p>'
	}
}


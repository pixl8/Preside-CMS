component singleton=true {

// CONSTRUCTOR
	/**
	 * @widgetsService.inject       WidgetsService
	 * @pageTypesService.inject     PageTypesService
	 * @presideObjectService.inject PresideObjectService
	 * @appMapping.inject           coldbox:setting:appMapping
	 * @notificationDao.inject      presidecms:object:admin_notification
	 * @configuredTopics.inject     coldbox:setting:notificationTopics
	 */
	public any function init(
		  required any    widgetsService
		, required any    pageTypesService
		, required any    presideObjectService
		, required string appMapping
		, required array  configuredTopics
		, required any    notificationDao
	) {
		_setWidgetsService( arguments.widgetsService );
		_setPageTypesService( arguments.pageTypesService );
		_setPresideObjectService( arguments.presideObjectService );
		_setConfiguredTopics( arguments.configuredTopics );
		_setAppMapping( arguments.appMapping );
		_setNotificationDao( arguments.notificationDao );

		return this;
	}

// PUBLIC API METHODS
	public array function scaffoldWidget( required string id, string name="",  string description="", string icon="fa-magic", string options="", string extension="", boolean createHandler=false ) {
		var filesCreated = _ensureExtensionExists( arguments.extension );
		var i18nProps    = StructNew( "linked" );

		if ( _getWidgetsService().widgetExists( arguments.id ) ) {
			throw( type="scaffoldwidget.widget.exists", message="The '#arguments.id#' widget already exists" );
		}

		if ( arguments.createHandler ) {
			filesCreated.append( scaffoldWidgetViewletHandler( handlerName=arguments.id, subDir="widgets", extension=arguments.extension ) );
			filesCreated.append( scaffoldView( viewName="index", subDir="widgets/#arguments.id#", extension=arguments.extension, args=ListToArray( arguments.options ) ) );
			filesCreated.append( scaffoldWidgetPlaceholderView( widgetId=arguments.id, extension=arguments.extension, args=ListToArray( arguments.options ) ) );
		} else {
			filesCreated.append( scaffoldView( viewName=arguments.id, subDir="widgets", extension=arguments.extension, args=ListToArray( arguments.options ) ) );
		}

		i18nProps["title"]=arguments.name;
		i18nProps["description"]=arguments.description;
		i18nProps["iconclass"]= arguments.icon;

		for( var option in ListToArray( arguments.options ) ) {
			i18nProps[ "field.#option#.title" ]       = _convertToReadableFormat( words = option );
			i18nProps[ "field.#option#.placeholder" ] = "";
			i18nProps[ "field.#option#.help" ]        = "";
		}
		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.id, subDir="widgets", extension=arguments.extension, properties=i18nProps ) );

		if ( Len( Trim( arguments.options ) ) ) {
			filesCreated.append( scaffoldSimpleForm( formName=arguments.id, subDir="widgets", extension=arguments.extension, fields=ListToArray( arguments.options ), i18nBaseUri="widgets.#arguments.id#:" ) );
		}

		_getWidgetsService().reload();

		return filesCreated;
	}

	public array function scaffoldPageType( required string id, string name="", string pluralName=arguments.name, string description="", string icon="page-o" string fields="", string extension="", boolean createHandler=false ) {
		var filesCreated = _ensureExtensionExists( arguments.extension );
		var i18nProps    = StructNew( "linked" );

		if ( _getPageTypesService().pageTypeExists( arguments.id ) ) {
			throw( type="scaffoldpagetype.pagetype.exists", message="The '#arguments.id#' page type already exists" );
		}

		if ( arguments.createHandler ) {
			filesCreated.append( scaffoldPageTypeViewletHandler( handlerName=arguments.id, subDir="page-types", extension=arguments.extension ) );
		}

		filesCreated.append( scaffoldPresideObjectCfc( objectName=arguments.id, subDir="page-types", extension=arguments.extension, properties=ListToArray( arguments.fields ) ) );
		filesCreated.append( scaffoldPageTypeView( viewName="index", subDir="page-types/#arguments.id#", extension=arguments.extension, args=ListToArray( arguments.fields ) ) );
		filesCreated.append( scaffoldPageTypeForm( pagetype=arguments.id, formName=arguments.id, subDir="page-types", extension=arguments.extension, fields=ListToArray( arguments.fields ) ) );


		i18nProps[ "name" ]        = arguments.name;
		i18nProps[ "description" ] = arguments.description;
		i18nProps[ "iconclass" ]   = arguments.icon;
		for( var field in ListToArray( arguments.fields ) ) {
			i18nProps[ "field.#field#.title" ] = _convertToReadableFormat( words = field );
		}
		i18nProps[ "tab.#arguments.id#.title" ] = _convertToReadableFormat( words = arguments.name );
		i18nProps[ "tab.#arguments.id#.description" ] = "";
		i18nProps[ "fieldset.#arguments.id#.title" ] = "";
		i18nProps[ "fieldset.#arguments.id#.description" ] = "";
		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.id, subDir="page-types", extension=arguments.extension, properties=i18nProps ) );


		return filesCreated;
	}

	public array function scaffoldPresideObject( required string objectName, string name="", string pluralName=arguments.name, string description="", string extension="", string properties="", string datamanagerGroup="" ) {
		var filesCreated   = _ensureExtensionExists( arguments.extension );
		var i18nProps      = { title=arguments.pluralName, "title.singular"=arguments.name, description=arguments.description };
		var i18nGroupProps = { title=arguments.datamanagerGroup, description=arguments.datamanagerGroup & " data manager group", iconclass="fa-square-o" };
		var root           = _getScaffoldRoot( arguments.extension );

		if ( _getPresideObjectService().objectExists( arguments.objectName ) ) {
			throw( type="scaffoldPresideObject.object.exists", message="The '#arguments.objectName#' object already exists" );
		}

		filesCreated.append( scaffoldPresideObjectCfc( objectName=arguments.objectName, extension=arguments.extension, properties=ListToArray( arguments.properties ), datamanagerGroup=arguments.datamanagerGroup ) );

		if( Len( Trim( arguments.datamanagerGroup ) ) && ! FileExists( root & "i18n/preside-objects/groups/" & arguments.datamanagerGroup & ".properties" ) ) {
			filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.datamanagerGroup, subDir="preside-objects/groups", extension=arguments.extension, properties=i18nGroupProps ) );
		}

		for( var field in ListToArray( arguments.properties ) ) {
			i18nProps[ "field.#field#.title" ] = _convertToReadableFormat( words = field );
		}
		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.objectName, subDir="preside-objects", extension=arguments.extension, properties=i18nProps ) );

		return filesCreated;
	}

	public array function scaffoldExtension( required string id, required string title, required string description ) {
		var filesCreated = [];

		filesCreated.append( scaffoldExtensionManifestFile( argumentCollection=arguments ) );
		filesCreated.append( scaffoldExtensionConfigFile( argumentCollection=arguments ) );

		return filesCreated;
	}

	public array function scaffoldSystemConfigForm(
		  required string id
		, required string fields
		, required string name
		, required string description
		, required string icon
		, required string extension
	) {
		var filesCreated = _ensureExtensionExists( arguments.extension );
		var i18nProps    = StructNew( "linked" );

		i18nProps[ "name" ]        = arguments.name;
		i18nProps[ "description" ] = arguments.description;
		i18nProps[ "iconclass" ]   = arguments.icon;
		for( var field in ListToArray( arguments.fields ) ) {
			i18nProps[ "field.#field#.title" ]       = _convertToReadableFormat( words = field );
			i18nProps[ "field.#field#.placeholder" ] = "";
			i18nProps[ "field.#field#.help" ]        = "";
		}

		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.id, subDir="system-config", extension=arguments.extension, properties=i18nProps ) );
		filesCreated.append( scaffoldSimpleForm( formName=arguments.id, subDir="system-config", extension=arguments.extension, fields=ListToArray( arguments.fields ), i18nBaseUri="system-config.#arguments.id#:" ) );

		return filesCreated;
	}

	public array function scaffoldFormControl(
		  required string  id
		, required boolean createHandler
		, required array   contexts
		, required string  extension
	) {
		var filesCreated = _ensureExtensionExists( arguments.extension );

		filesCreated.append( scaffoldFormControlViews(
			  formControl = arguments.id
			, contexts    = arguments.contexts
			, extension   = arguments.extension
		), true );

		if ( arguments.createHandler ) {
			filesCreated.append( scaffoldFormControlViewletHandler(
				  formControl = arguments.id
				, contexts    = arguments.contexts
				, extension   = arguments.extension
			) );
		}

		return filesCreated;
	}

	public array function scaffoldEmailTemplate(
		  required string  id
		, required string  extension
	) {
		var filesCreated = _ensureExtensionExists( arguments.extension );

		filesCreated.append( scaffoldEmailTemplateViewletHandler( id = arguments.id ) );

		return filesCreated;
	}

	public string function scaffoldFormControlViewletHandler( required string formControl, required array contexts, string extension="" ) {
		var root            = _getScaffoldRoot( arguments.extension );
		var filePath        = root & "handlers/formcontrols/" & formControl & ".cfc";
		var viewPath         =
		var fileContent     = "component {" & _nl() & _nl();

		for( var context in contexts ) {
			var viewPath = "formcontrols/" & formControl & "/" & context;

			fileContent &= "	private function #context#( event, rc, prc, args={} ) {" & _nl()
			             & "		// TODO: create your handler logic here" & _nl()
			             & "		return renderView( view='#viewPath#', args=args );" & _nl()
			             & "	}" & _nl() & _nl();
		}

		fileContent &= "}" & _nl();

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldWidgetViewletHandler( required string handlerName, string subDir="", string extension="" ) {
		var root            = _getScaffoldRoot( arguments.extension );
		var filePath        = root & "handlers/" & arguments.subDir & "/" & handlerName & ".cfc";
		var viewPath        = arguments.subDir & "/" & handlerName & "/index";
		var placeholderPath = arguments.subDir & "/" & handlerName & "/placeholder";
		var fileContent     = "component {" & _nl()
		                    & "	private function index( event, rc, prc, args={} ) {" & _nl()
		                    & "		// TODO: create your handler logic here" & _nl()
		                    & "		return renderView( view='#viewPath#', args=args );" & _nl()
		                    & "	}" & _nl() & _nl()
		                    & "	private function placeholder( event, rc, prc, args={} ) {" & _nl()
		                    & "		// TODO: create your handler logic here" & _nl()
		                    & "		return renderView( view='#placeholderPath#', args=args );" & _nl()
		                    & "	}" & _nl()
		                    & "}" & _nl();

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldPageTypeViewletHandler( required string handlerName, string subDir="", string extension="" ) {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "handlers/" & arguments.subDir & "/" & handlerName & ".cfc";
		var viewPath = arguments.subDir & "/" & handlerName & "/index";
		var fileContent = "component {" & _nl()
		                & "	private function index( event, rc, prc, args={} ) {" & _nl()
		                & "		// TODO: create your handler logic here" & _nl()
		                & "		return renderView(" & _nl()
		                & "			  view          = '#viewPath#'"              & _nl()
		                & "			, presideObject = '#arguments.handlerName#'" & _nl()
		                & "			, id            = event.getCurrentPageId()"  & _nl()
		                & "			, args          = args"                      & _nl()
		                & "		);" & _nl()
		                & "	}" & _nl()
		                & "}" & _nl();

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldEmailTemplateViewletHandler( required string id, string extension="" ) {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "handlers/emailTemplates/" & arguments.id & ".cfc";

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileCopy( "/preside/system/services/devtools/scaffoldingResources/emailtemplateHandler.cfc.txt", filePath );

		return filePath;
	}



	public string function scaffoldView( required string viewName, string subDir="", string extension="", array args=[] ) {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "views/" & arguments.subDir & "/" & arguments.viewName & ".cfm";
		var fileContent = "<!---" & _nl()
		                & "	This view file has been automatically created by the preside dev tools" & _nl()
		                & "	scaffolder. Please fill with meaningful content and remove this comment" & _nl()
		                & "--->" & _nl();

		for( var arg in args ) {
			fileContent &= '<cfparam name="args.#arg#" default="" />' & _nl();
		}

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public array function scaffoldFormControlViews( required string formControl, required array contexts, string extension="" ) {
		var root                = _getScaffoldRoot( arguments.extension ) & "views/formcontrols/" & formControl & "/";
		var formControlTemplate = FileRead( "/preside/system/services/devtools/scaffoldingResources/formcontrol.view.cfm.txt" );
		var filesCreated        = [];

		for( var context in contexts ) {
			var filePath    = root & context & ".cfm";
			var fileContent = Replace( formControlTemplate, "${id}", arguments.formControl, "all" );

			_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
			FileWrite( filePath, fileContent );
			filesCreated.append( filePath );
		}

		return filesCreated;
	}

	public string function scaffoldWidgetPlaceholderView( required string widgetId, string extension="", array args=[] ) {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "views/widgets/#arguments.widgetId#/placeholder.cfm";
		var fileContent = "<!---" & _nl()
		                & "	This view file has been automatically created by the preside dev tools" & _nl()
		                & "	scaffolder. The purpose of this file is to render the placeholder content" & _nl()
		                & "	for the #arguments.widgetId# widget." & _nl()
		                & "	Please fill with meaningful content and remove this comment" & _nl()
		                & "--->" & _nl();

		for( var arg in args ) {
			fileContent &= '<cfparam name="args.#arg#" default="" />' & _nl();
		}

		fileContent &= _nl() & _nl();
		fileContent &= "<cfoutput>##translateResource( uri='widgets.#arguments.widgetId#:title' )##</cfoutput>";

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldPageTypeView( required string viewName, string subDir="", string extension="", array args=[] ) {
		var root        = _getScaffoldRoot( arguments.extension );
		var filePath    = root & "views/" & arguments.subDir & "/" & arguments.viewName & ".cfm";
		var fileContent = FileRead( "/preside/system/services/devtools/scaffoldingResources/pageTypeView.cfm.txt" );
		var params      = "";

		for( var arg in args ) {
			params &= '<cf_presideparam name="args.#arg#" editable="true" />' & _nl();
		}

		fileContent = ReplaceNoCase( fileContent, "${params}", params )

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}



	public string function scaffoldI18nPropertiesFile( required string bundleName, string subDir="", string extension="", struct properties={} ) {
		var root        = _getScaffoldRoot( arguments.extension );
		var filePath    = root & "i18n/" & arguments.subDir & "/" & bundleName & ".properties";
		var fileContent = "";

		for( var prop in arguments.properties ) {
			fileContent &= prop & "=" & arguments.properties[ prop ] & _nl();
		}

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldSimpleForm( required string formName, string subDir="", string extension="", array fields=[], string i18nBaseUri="" ) {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "forms/" & arguments.subDir & "/" & arguments.formName & ".xml";
		var fileContent = '<?xml version="1.0" encoding="UTF-8"?>' & _nl()
		                & '<form i18nBaseUri="#arguments.i18nBaseUri#">' & _nl()
		                & '	<tab>' & _nl()
		                & '		<fieldset>' & _nl();

		for( var field in arguments.fields ) {
			fileContent &= '			<field name="#field#" />' & _nl();
		}

		fileContent &= '		</fieldset>' & _nl()
		            &  '	</tab>' & _nl()
		            &  '</form>';

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldPageTypeForm( required string pagetype, required string formName, string subDir="", string extension="", array fields=[] ) {
		var root           = _getScaffoldRoot( arguments.extension );
		var filePath       = root & "forms/" & arguments.subDir & "/" & arguments.formName & ".xml";
		var fileContent    = FileRead( "/preside/system/services/devtools/scaffoldingResources/pageTypeForm.xml.txt" );
		var renderedFields = "";

		for( var field in arguments.fields ) {
			renderedFields &= '			<field binding="#arguments.pageType#.#field#" />' & _nl();
		}

		fileContent = Replace( fileContent, "${custom_fields}", renderedFields );
		fileContent = Replace( fileContent, "${pagetype}", arguments.pagetype, "all" );

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldPresideObjectCfc( required string objectName, string subDir="", string extension="", array properties=[], string name="", string description="", boolean createI18nFile=false, string datamanagerGroup="" ) {
		var root        = _getScaffoldRoot( arguments.extension );
		var filePath    = root & "preside-objects/" & arguments.subDir & ( len( trim( arguments.subDir ) ) ? "/" : "" ) & arguments.objectName & ".cfc";
		var fileContent = FileRead( "/preside/system/services/devtools/scaffoldingResources/object.cfc.txt" );
		var props       = "";
		var dmGroup     = Len( Trim( arguments.datamanagerGroup ) ) ? 'dataManagerGroup="#arguments.datamanagerGroup#"' : "";

		for( var field in arguments.properties ) {
			props &= '	property name="#field#";' & _nl();
		}

		fileContent = Replace( fileContent, "${properties}", props );
		fileContent = Replace( fileContent, "${datamanagerGroup}", dmGroup );

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldExtensionManifestFile( required string id, required string title, required string description ) {
		var root        = _getScaffoldRoot( "" );
		var filePath    = root & "extensions/" & arguments.id & "/manifest.json";
		var fileContent = FileRead( "/preside/system/services/devtools/scaffoldingResources/manifest.json.txt" );

		fileContent = Replace( fileContent, "${id}"         , arguments.id          );
		fileContent = Replace( fileContent, "${title}"      , arguments.title       );
		fileContent = Replace( fileContent, "${description}", arguments.description );

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldExtensionConfigFile( required string id ) {
		var root        = _getScaffoldRoot( "" );
		var filePath    = root & "extensions/" & arguments.id & "/config/Config.cfc";
		var fileContent = FileRead( "/preside/system/services/devtools/scaffoldingResources/extension.Config.cfc.txt" );

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public array function scaffoldTerminalCommand( required string name, required string helpText, string extension="" ) {
		var filesCreated = _ensureExtensionExists( arguments.extension );
		var root         = _getScaffoldRoot( arguments.extension );
		var filePath     = root & "handlers/admin/devtools/terminalCommands/#arguments.name#.cfc";
		var fileContent  = 'component hint="#HtmlEditFormat( arguments.helpText )#" {' & _nl()
		                 & _nl()
		                 & '	property name="jsonRpc2Plugin" inject="JsonRpc2";' & _nl()
		                 & _nl()
		                 & '	private any function index( event, rc, prc ) {' & _nl()
		                 & '		var params  = jsonRpc2Plugin.getRequestParams();' & _nl()
		                 & '		var cliArgs = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];' & _nl()
		                 & _nl()
		                 & '		return "I am a scaffolded command, please finish me off!";' & _nl()
		                 & '	}' & _nl()
		                 & '}';

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		filesCreated.append( filePath );
		return filesCreated;
	}

	public array function scaffoldRuleExpression( required string id, required string label, required string text, required string context, string extension="" ) {
		var filesCreated = _ensureExtensionExists( arguments.extension );
		var i18nProps    = StructNew( "linked" );

		var root            = _getScaffoldRoot( arguments.extension );
		var filePath        = root & "handlers/rules/expressions/" & arguments.id & ".cfc";
		var fileContent     = "/**" & _nl()
		                    & " * Scaffolded rules engine expression. See " & _nl()
							& " * See the official documentation on Preside's rules engine for more" & _nl()
							& " * details on creating and using expressions." & _nl()
		                    & " *" & _nl()
							& " * @expressionContexts #arguments.context#" & _nl()
							& " */" & _nl()
		                    & "component {" & _nl() & _nl()
							& _tab() & "/**" & _nl()
							& _tab() & " * The evaluateExpression() action required for expression" & _nl()
							& _tab() & " * handlers to evaluate a configured expression at runtime." & _nl()
							& _tab() & " * See the official documentation on Preside's rules engine for more" & _nl()
							& _tab() & " * details on creating and using expressions." & _nl()
							& _tab() & " *" & _nl()
							& _tab() & " */" & _nl()
		                    & _tab() & "private boolean function evaluateExpression( " & _nl()
		                    & _tab() & _tab() & "  required string context" & _nl()
		                    & _tab() & _tab() & ", required struct payload" & _nl()
		                    & _tab() & _tab() & "/* add your own field arguments here */" & _nl()
		                    & _tab() & ") {" & _nl()
		                    & _tab() & _tab() & "// TODO: create your handler logic here to evaluate the expression" & _nl()
		                    & _tab() & _tab() & "return true; // or false, depending on the payload and your logic" & _nl()
		                    & _tab() & "}" & _nl() & _nl()
		                    & "}" & _nl();

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		filesCreated.append( filePath );

		i18nProps["label"] = arguments.label;
		i18nProps["text"]  = arguments.text;

		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.id, subDir="rules/expressions", extension=arguments.extension, properties=i18nProps ) );

		return filesCreated;
	}

	public array function scaffoldNotification( required string notificationId, string title="", string description="", string icon="fa-magic", string dataTableTitle="", string extension="" ) {
		var filesCreated = _ensureExtensionExists( arguments.extension );
		var i18nProps    = StructNew( "ordered" );
		var topics       = _getConfiguredTopics();

		if( arrayFindNoCase( topics, arguments.notificationId ) ){
			throw( type="scaffoldwidget.notification.exists", message="The '#arguments.notificationId#' notification already exists" );
		}

		filesCreated.append( scaffoldNotificationViewletHandler( handlerName=arguments.notificationId, subDir="renderers/notifications", extension=arguments.extension ) );
		filesCreated.append( scaffoldView( viewName="full", subDir="renderers/notifications/#arguments.notificationId#", extension=arguments.extension ) );

		i18nProps["title"]          = arguments.title;
		i18nProps["description"]    = arguments.description;
		i18nProps["iconclass"]      = arguments.icon;
		i18nProps["datatabletitle"] = arguments.dataTableTitle;

		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.notificationId, subDir="notifications", extension=arguments.extension, properties=i18nProps ) );

		// Append notification topic in config.cfc
		arrayAppend( topics, arguments.notificationId );

		return filesCreated;
	}

	public string function scaffoldNotificationViewletHandler( required string handlerName, string subDir="", string extension="" ) {
		var root            = _getScaffoldRoot( arguments.extension );
		var filePath        = root & "handlers/" & arguments.subDir & "/" & handlerName & ".cfc";
		var viewPath        = arguments.subDir & "/" & handlerName & "/dataTable";
		var fileContent     = "component {" & _nl()
		                    & "	private function dataTable( event, rc, prc, args={} ) {" & _nl()
		                    & "		// TODO: create your handler logic here" & _nl()
		                    & "		return " & "translateResource( uri='notifications.#arguments.handlerName#:dataTableTitle' );" & _nl()
		                    & "	}" & _nl()
		                    & " private string function full( event, rc, prc, args={} ) {" & _nl()
		                    & "		return renderView( view = '/renderers/notifications/#arguments.handlerName#/full', args = args );" & _nl()
		                    & " }" & _nl()
		                    & "}" & _nl();

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

// PRIVATE HELPERS
	private void function _ensureDirectoryExists( required string dir ) {
		var parentDir = "";
		if ( not DirectoryExists( arguments.dir ) ) {
			parentDir = ListDeleteAt( arguments.dir, ListLen( arguments.dir, "/" ), "/" );
			_ensureDirectoryExists( parentDir );
			DirectoryCreate( arguments.dir );
		}
	}

	private array function _ensureExtensionExists( required string extension ) {
		if ( !Len( Trim( arguments.extension ) ) || arguments.extension == "core" ) {
			return [];
		}

		var extensionRoot = _getScaffoldRoot( arguments.extension );
		if ( !DirectoryExists( extensionRoot ) ) {
			return scaffoldExtension( arguments.extension, arguments.extension, "" );
		}

		return [];
	}

	private string function _getScaffoldRoot( required string extension ) {
		switch( Trim( arguments.extension ) ) {
			case "":
				return "#_getAppMapping()#/";
			case "core":
				return "/preside/system/";
			default:
				return "#_getAppMapping()#/extensions/#arguments.extension#/";
		}
	}

	private string function _nl() {
		return Chr(13) & Chr(10);
	}

	private string function _tab() {
		return Chr(9);
	}

	private string function _convertToReadableFormat( required string words ){
		var removedNonChar = reReplace( arguments.words, "[^a-zA-Z0-9]+", " ", "all" );	
		return reReplaceNocase( removedNonChar, "\b(\w)", "\u\1", "all" );
	}


// GETTERS AND SETTERS
	private any function _getWidgetsService() {
		return _widgetsService;
	}
	private void function _setWidgetsService( required any widgetsService ) {
		_widgetsService = arguments.widgetsService;
	}

	private any function _getPageTypesService() {
		return _pageTypesService;
	}
	private void function _setPageTypesService( required any pageTypesService ) {
		_pageTypesService = arguments.pageTypesService;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private string function _getAppMapping() {
		return _appMapping;
	}
	private void function _setAppMapping( required string appMapping ) {
		_appMapping = "/" & arguments.appMapping.reReplace( "^/", "" );
	}

	private any function _getNotificationDao() {
		return _notificationDao;
	}
	private void function _setNotificationDao( required any notificationDao ) {
		_notificationDao = arguments.notificationDao;
	}

	private any function _getConfiguredTopics() {
		return _configuredTopics;
	}
	private void function _setConfiguredTopics( required any configuredTopics ) {
		_configuredTopics = arguments.configuredTopics;
	}
}

component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @widgetsService.inject       WidgetsService
	 * @pageTypesService.inject     PageTypesService
	 * @presideObjectService.inject PresideObjectService
	 */
	public any function init( required any widgetsService, required any pageTypesService, required any presideObjectService ) output=false {
		_setWidgetsService( arguments.widgetsService );
		_setPageTypesService( arguments.pageTypesService );
		_setPresideObjectService( arguments.presideObjectService );

		return this;
	}

// PUBLIC API METHODS
	public array function scaffoldWidget( required string id, string name="",  string description="", string icon="fa-magic", string options="", string extension="", boolean createHandler=false ) output=false {
		var filesCreated = [];
		var i18nProps    = StructNew( "linked" );

		if ( _getWidgetsService().widgetExists( arguments.id ) ) {
			throw( type="scaffoldwidget.widget.exists", message="The '#arguments.id#' widget already exists" );
		}

		if ( arguments.createHandler ) {
			filesCreated.append( scaffoldViewletHandler( handlerName=arguments.id, subDir="widgets", extension=arguments.extension ) );
			filesCreated.append( scaffoldView( viewName="index", subDir="widgets/#arguments.id#", extension=arguments.extension, args=ListToArray( arguments.options ) ) );

		} else {
			filesCreated.append( scaffoldView( viewName=arguments.id, subDir="widgets", extension=arguments.extension, args=ListToArray( arguments.options ) ) );
		}

		i18nProps["title"]=arguments.name;
		i18nProps["description"]=arguments.description;
		i18nProps["iconclass"]=arguments.icon;

		for( var option in ListToArray( arguments.options ) ) {
			i18nProps[ "form.#option#.label" ] = option;
		}
		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.id, subDir="widgets", extension=arguments.extension, properties=i18nProps ) );

		if ( Len( Trim( arguments.options ) ) ) {
			filesCreated.append( scaffoldSimpleForm( formName=arguments.id, subDir="widgets", extension=arguments.extension, fields=ListToArray( arguments.options ), labelPrefix="widgets.#arguments.id#:form." ) );
		}

		_getWidgetsService().reload();

		return filesCreated;
	}

	public array function scaffoldPageType( required string id, string name="", string pluralName=arguments.name, string description="", string icon="page-o" string fields="", string extension="", boolean createHandler=false ) output=false {
		var filesCreated = [];
		var i18nProps    = StructNew( "linked" );

		if ( _getPageTypesService().pageTypeExists( arguments.id ) ) {
			throw( type="scaffoldpagetype.pagetype.exists", message="The '#arguments.id#' page type already exists" );
		}

		if ( arguments.createHandler ) {
			filesCreated.append( scaffoldViewletHandler( handlerName=arguments.id, subDir="page-types", extension=arguments.extension ) );
		}

		filesCreated.append( scaffoldPresideObjectCfc( objectName=arguments.id, subDir="page-types", extension=arguments.extension, properties=ListToArray( arguments.fields ) ) );
		filesCreated.append( scaffoldPageTypeView( viewName="index", subDir="page-types/#arguments.id#", extension=arguments.extension, args=ListToArray( arguments.fields ) ) );
		filesCreated.append( scaffoldPageTypeForm( pagetype=arguments.id, formName=arguments.id, subDir="page-types", extension=arguments.extension, fields=ListToArray( arguments.fields ) ) );


		i18nProps[ "name" ]        = arguments.name;
		i18nProps[ "description" ] = arguments.description;
		i18nProps[ "iconclass" ]   = arguments.icon;
		for( var field in ListToArray( arguments.fields ) ) {
			i18nProps[ "field.#field#.title" ] = field;
		}
		i18nProps[ "form.tab.title" ] = arguments.name;
		i18nProps[ "form.tab.description" ] = "";
		i18nProps[ "form.fieldset.title" ] = "";
		i18nProps[ "form.fieldset.description" ] = "";
		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.id, subDir="page-types", extension=arguments.extension, properties=i18nProps ) );


		return filesCreated;
	}

	public array function scaffoldPresideObject( required string objectName, string name="", string pluralName=arguments.name, string description="", string extension="", string properties="", string datamanagerGroup="" ) output=false {
		var filesCreated = [];
		var i18nProps    = { title=arguments.pluralName, "title.singular"=arguments.name, description=arguments.description };

		if ( _getPresideObjectService().objectExists( arguments.objectName ) ) {
			throw( type="scaffoldpagetype.object.exists", message="The '#arguments.objectName#' object already exists" );
		}

		filesCreated.append( scaffoldPresideObjectCfc( objectName=arguments.objectName, extension=arguments.extension, properties=ListToArray( arguments.properties ), datamanagerGroup=arguments.datamanagerGroup ) );

		for( var field in ListToArray( arguments.properties ) ) {
			i18nProps[ "field.#field#.title" ] = field;
		}
		filesCreated.append( scaffoldI18nPropertiesFile( bundleName=arguments.objectName, subDir="preside-objects", extension=arguments.extension, properties=i18nProps ) );

		return filesCreated;
	}

	public string function scaffoldViewletHandler( required string handlerName, string subDir="", string extension="" ) output=false {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "handlers/" & arguments.subDir & "/" & handlerName & ".cfc";
		var viewPath = arguments.subDir & "/" & handlerName & "/index";
		var fileContent = "component output=false {" & _nl()
		                & "	private function index( event, rc, prc, viewletArgs={} ) output=false {" & _nl()
		                & "		// TODO: create your handler logic here" & _nl()
		                & "		return renderView( view='#viewPath#', args=viewletArgs );" & _nl()
		                & "	}" & _nl()
		                & "}" & _nl();

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldView( required string viewName, string subDir="", string extension="", array args=[] ) output=false {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "views/" & arguments.subDir & "/" & arguments.viewName & ".cfm";
		var fileContent = "<!---" & _nl()
		                & "	This view file has been automativally created by the preside dev tools" & _nl()
		                & "	scaffolder. Please fill with meaningful content and remove this comment" & _nl()
		                & "--->" & _nl();

		for( var arg in args ) {
			fileContent &= '<cfparam name="args.#arg#" default="" />' & _nl();
		}

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldPageTypeView( required string viewName, string subDir="", string extension="", array args=[] ) output=false {
		var root        = _getScaffoldRoot( arguments.extension );
		var filePath    = root & "views/" & arguments.subDir & "/" & arguments.viewName & ".cfm";
		var fileContent = FileRead( "/preside/system/services/devtools/scaffoldingResources/pageTypeView.cfm.txt" );
		var params      = "";

		for( var arg in args ) {
			params &= '<cfparam name="args.#arg#" editable="true" />' & _nl();
		}

		fileContent = ReplaceNoCase( fileContent, "${params}", params )

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}



	public string function scaffoldI18nPropertiesFile( required string bundleName, string subDir="", string extension="", struct properties={} ) output=false {
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

	public string function scaffoldSimpleForm( required string formName, string subDir="", string extension="", array fields=[], string labelPrefix="" ) output=false {
		var root     = _getScaffoldRoot( arguments.extension );
		var filePath = root & "forms/" & arguments.subDir & "/" & arguments.formName & ".xml";
		var fileContent = '<?xml version="1.0" encoding="UTF-8"?>' & _nl()
		                & '<form>' & _nl()
		                & '	<tab>' & _nl()
		                & '		<fieldset>' & _nl();

		for( var field in arguments.fields ) {
			fileContent &= '			<field name="#field#" label="#arguments.labelPrefix##field#.label" />' & _nl();
		}

		fileContent &= '		</fieldset>' & _nl()
		            &  '	</tab>' & _nl()
		            &  '</form>';

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

	public string function scaffoldPageTypeForm( required string pagetype, required string formName, string subDir="", string extension="", array fields=[], string labelPrefix="" ) output=false {
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

	public string function scaffoldPresideObjectCfc( required string objectName, string subDir="", string extension="", array properties=[], string name="", string description="", boolean createI18nFile=false, string datamanagerGroup="" ) output=false {
		var root        = _getScaffoldRoot( arguments.extension );
		var filePath    = root & "preside-objects/" & arguments.subDir & "/" & arguments.objectName & ".cfc";
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

	public string function scaffoldTerminalCommand( required string name, required string helpText, string extension="" ) output=false {
		var root        = _getScaffoldRoot( arguments.extension );
		var filePath    = root & "handlers/admin/devtools/terminalCommands/#arguments.name#.cfc";
		var fileContent = 'component output=false hint="#HtmlEditFormat( arguments.helpText )#" {' & _nl()
		                & _nl()
		                & '	property name="jsonRpc2Plugin" inject="coldbox:myPlugin:JsonRpc2";' & _nl()
		                & _nl()
		                & '	private any function index( event, rc, prc ) output=false {' & _nl()
		                & '		var params  = jsonRpc2Plugin.getRequestParams();' & _nl()
		                & '		var cliArgs = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];' & _nl()
		                & _nl()
		                & '		return "I am a scaffolded command, please finish me off!";' & _nl()
		                & '	}' & _nl()
		                & '}';

		_ensureDirectoryExists( GetDirectoryFromPath( filePath ) );
		FileWrite( filePath, fileContent );

		return filePath;
	}

// PRIVATE HELPERS
	private void function _ensureDirectoryExists( required string dir ) output=false {
		var parentDir = "";
		if ( not DirectoryExists( arguments.dir ) ) {
			parentDir = ListDeleteAt( arguments.dir, ListLen( arguments.dir, "/" ), "/" );
			_ensureDirectoryExists( parentDir );
			DirectoryCreate( arguments.dir );
		}
	}

	private string function _getScaffoldRoot( required string extension ) output=false {
		return Len( Trim( arguments.extension ) ) ? "/app/extensions/#arguments.extension#/" : "/app/";
	}

	private string function _nl() output=false {
		return Chr(13) & Chr(10);
	}


// GETTERS AND SETTERS
	private any function _getWidgetsService() output=false {
		return _widgetsService;
	}
	private void function _setWidgetsService( required any widgetsService ) output=false {
		_widgetsService = arguments.widgetsService;
	}

	private any function _getPageTypesService() output=false {
		return _pageTypesService;
	}
	private void function _setPageTypesService( required any pageTypesService ) output=false {
		_pageTypesService = arguments.pageTypesService;
	}

	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}

}
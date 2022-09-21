/**
 * @singleton      true
 * @autodoc        true
 * @presideservice true
 *
 * Service that discovers and reads available data export templates within a Preside application
 */
component {

// CONSTRUCTOR
	/**
	 * @formsService.inject formsService
	 *
	 */
	public any function init( required any formsService ) {
		_setFormsService( arguments.formsService );

		return this;
	}

// PUBLIC API METHODS
	public boolean function templateExists( required string templateId ) {
		return ArrayFindNoCase( _getTemplates(), arguments.templateId );
	}

	public string function renderConfigForm(
		  required string templateId
		, required string objectName
	) {
		var formName              = _getConfigFormName( argumentCollection=arguments );
		var allowedExporters      = _getAllowedExporters( argumentCollection=arguments );
		var defaultExporter       = _getDefaultExporter( argumentCollection=arguments, allowedExporters=allowedExporters );
		var defaultExportFilename = _getDefaultFileName( argumentCollection=arguments );
		var renderFormArgs        = {
			  formName       = formName
			, context        = "admin"
			, formId         = "export-config-form-#arguments.objectName#"
			, savedData      = { filename=defaultExportFilename, exporter=defaultExporter }
			, additionalArgs = { fields={ exporter = { allowedExporters=allowedExporters } } }
		};

		if ( _templateMethodExists( arguments.templateId, "preRenderConfigForm" ) ) {
			_runTemplateMethod( arguments.templateId, "preRenderConfigForm", { objectName=arguments.objectName, renderFormArgs=renderFormArgs } );
		}

		return _getFormsService().renderForm( argumentCollection=renderFormArgs );
	}

// PRIVATE HELPERS
	public array function _readTemplates() {
		var handlers = $getColdbox().listHandlers( thatStartWith="dataExportTemplates." );
		var templates = [];

		for( var handler in handlers ) {
			var templateId = ListRest( handler, "." );

			ArrayAppend( templates, templateId );
		}

		_setTemplates( templates );

		return templates;
	}

	public boolean function _templateMethodExists( required string templateId, required string customisation ) {
		return $getColdbox().handlerExists( "dataExportTemplates.#arguments.templateId#.#arguments.customisation#" );
	}

	public any function _runTemplateMethod(
		  required string templateId
		, required string customisation
		,          struct args = {}

	) {
		return $runEvent(
			  event          = "dataExportTemplates.#arguments.templateId#.#arguments.customisation#"
			, private        = true
			, prepostExempt  = true
			, eventArguments = args
		);
	}

	private string function _getConfigFormName( templateId, objectName ) {
		var formName  = "dataExport.exportConfiguration.base";
		var mergeWith = "";

		if ( _templateMethodExists( arguments.templateId, "getConfigFormName" ) ) {
			formName = _runTemplateMethod( arguments.templateId, "getConfigFormName", { objectName=arguments.objectName, baseFormName=formName } );

		} else if ( _getFormsService().formExists( "dataExportTemplate.#arguments.templateId#" ) ) {
			mergeWith = "dataExportTemplate.#arguments.templateId#";
		}

		if ( Len( Trim( mergeWith ) ) ) {
			formName = _getFormsService().getMergedFormName( formName, mergeWith );
		}

		return formName;
	}

	private string function _getAllowedExporters( templateId, objectName ) {
		if ( _templateMethodExists( arguments.templateId, "getAllowedExporters" ) ) {
			var exporters = _runTemplateMethod( arguments.templateId, "getAllowedExporters", { objectName=arguments.objectName } );
			if ( IsArray( exporters ) ) {
				return ArrayToList( exporters );
			}

			return exporters;
		}

		return "";

	}

	private string function _getDefaultExporter( templateId, objectName, allowedExporters ) {
		if ( ListLen( Trim( arguments.allowedExporters ) )==1 ) {
			return arguments.allowedExporters;
		}

		if ( _templateMethodExists( arguments.templateId, "getDefaultExporter" ) ) {
			return _runTemplateMethod( arguments.templateId, "getDefaultExporter", { objectName=arguments.objectName } );
		}

		return $getColdbox().getSetting( name="dataExport.defaultExporter" , defaultValue="" );
	}

	private string function _getDefaultFileName( templateId, objectName ) {
		if ( _templateMethodExists( arguments.templateId, "getDefaultFilename" ) ) {
			return _runTemplateMethod( arguments.templateId, "getDefaultFilename", { objectName=arguments.objectName } );
		}
		return $translateresource(
			  uri  = "cms:dataexport.config.form.field.title.default"
			, data = [ $helpers.translateObjectName( arguments.objectName ), DateTimeFormat( Now(), 'yyyy-mm-dd HH:nn' ) ]
		);
	}



// GETTERS AND SETTERS
	private any function _getTemplates() {
	    return variables._templates ?: _readTemplates();
	}
	private void function _setTemplates( required any templates ) {
	    variables._templates = arguments.templates;
	}

	private any function _getFormsService() {
	    return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
	    _formsService = arguments.formsService;
	}

}
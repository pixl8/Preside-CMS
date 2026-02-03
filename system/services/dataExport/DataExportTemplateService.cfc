/**
 * Service that discovers and reads available data export templates within a Preside application
 *
 * @singleton      true
 * @autodoc        true
 * @presideservice true
 * @feature        dataExport
 *
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

	/**
	 * Fired after app load to auto make an enum
	 * out of configured templates for i18n, etc.
	 *
	 */
	public void function setupTemplatesEnum() {
		var settings = $getColdbox().getSettingStructure();

		settings.enum.dataExportTemplate = settings.enum.dataExportTemplate ?: [];

		ArrayAppend( settings.enum.dataExportTemplate, "default" );
		for( var template in _getTemplates() ) {
			if ( !ArrayFindNoCase( settings.enum.dataExportTemplate, template ) ) {
				ArrayAppend( settings.enum.dataExportTemplate, template );
			}
		}
	}

	public string function renderConfigForm(
		  required string templateId
		, required string objectName
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		var formName              = _getConfigFormName( argumentCollection=arguments );
		var allowedExporters      = getAllowedExporters( argumentCollection=arguments );
		var defaultExporter       = getDefaultExporter( argumentCollection=arguments, allowedExporters=allowedExporters );
		var defaultExportFilename = _getDefaultFileName( argumentCollection=arguments );
		var renderFormArgs        = {
			  formName       = formName
			, context        = "admin"
			, formId         = "export-config-form-#arguments.objectName#"
			, savedData      = { filename=defaultExportFilename, exporter=defaultExporter }
			, additionalArgs = { fields={ exporter = { allowedExporters=allowedExporters } } }
		};

		if ( templateMethodExists( arguments.templateId, "preRenderConfigForm" ) ) {
			runTemplateMethod( arguments.templateId, "preRenderConfigForm", { objectName=arguments.objectName, renderFormArgs=renderFormArgs } );
		}

		return _getFormsService().renderForm( argumentCollection=renderFormArgs );
	}

	public struct function getSubmittedConfig( required string templateId, required string objectName ) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "getSubmittedConfig" ) ) {
			return runTemplateMethod( arguments.templateId, "getSubmittedConfig", { objectName=arguments.objectName } );
		}

		return {};
	}

	public string function renderSaveExportForm(
		  required string templateId
		, required string objectName
		,          boolean hasFilter = false
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		var formName              = getSaveExportFormName( argumentCollection=arguments );
		var allowedExporters      = getAllowedExporters( argumentCollection=arguments );
		var defaultExporter       = getDefaultExporter( argumentCollection=arguments, allowedExporters=allowedExporters );
		var defaultExportFilename = _getDefaultFileName( argumentCollection=arguments );

		if ( $helpers.IsTrue( arguments.hasFilter ?: "" ) ) {
			var mergeWithFilterForm = "dataExport.saveExportConfiguration.filter";
			formName = _getFormsService().getMergedFormName( formName, mergeWithFilterForm );
		}

		var renderFormArgs        = {
			  formName       = formName
			, context        = "admin"
			, formId         = "save-export-config-form"
			, savedData      = { filename=defaultExportFilename, exporter=defaultExporter }
			, additionalArgs = { fields={ exporter = { allowedExporters=allowedExporters } } }
		};

		if ( templateMethodExists( arguments.templateId, "preRenderSaveExportForm" ) ) {
			runTemplateMethod( arguments.templateId, "preRenderSaveExportForm", { objectName=arguments.objectName, renderFormArgs=renderFormArgs } );
		}

		return _getFormsService().renderForm( argumentCollection=renderFormArgs );
	}

	public struct function getExportMeta(
		  required string templateId
		, required string objectName
		, required struct templateConfig
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "getExportMeta" ) ) {
			return runTemplateMethod( arguments.templateId, "getExportMeta", {
				  objectName     = arguments.objectName
				, templateConfig = arguments.templateConfig
			} );
		}

		return {};
	}

	public any function getSelectFields(
		  required string templateId
		, required string objectName
		, required struct templateConfig
		, required array  suppliedFields
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "getSelectFields" ) ) {
			return runTemplateMethod( arguments.templateId, "getSelectFields", {
				  objectName     = arguments.objectName
				, templateConfig = arguments.templateConfig
				, suppliedFields = arguments.suppliedFields
			} );
		}

		return arguments.suppliedFields;
	}

	public struct function prepareFieldTitles(
		  required string templateId
		, required string objectName
		, required struct templateConfig
		, required array  selectFields
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "prepareFieldTitles" ) ) {
			return runTemplateMethod( arguments.templateId, "prepareFieldTitles", {
				  objectName     = arguments.objectName
				, templateConfig = arguments.templateConfig
				, selectFields   = arguments.selectFields
			} );
		}

		return {};
	}

	public void function prepareSelectDataArgs(
		  required string templateId
		, required string objectName
		, required struct templateConfig
		, required struct selectDataArgs
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "prepareSelectDataArgs" ) ) {
			runTemplateMethod( arguments.templateId, "prepareSelectDataArgs", {
				  objectName     = arguments.objectName
				, templateConfig = arguments.templateConfig
				, selectDataArgs = arguments.selectDataArgs
			} );
		}
	}


	public void function renderRecords(
		  required string templateId
		, required string objectName
		, required struct templateConfig
		, required query  records
	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "renderRecords" ) ) {
			runTemplateMethod( arguments.templateId, "renderRecords", {
				  objectName     = arguments.objectName
				, templateConfig = arguments.templateConfig
				, records        = arguments.records
			} );
		}
	}

	public boolean function templateMethodExists( required string templateId, required string methodName ) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		return $getColdbox().handlerExists( "dataExportTemplates.#arguments.templateId#.#arguments.methodName#" );
	}

	public any function runTemplateMethod(
		  required string templateId
		, required string methodName
		,          struct args = {}

	) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		return $runEvent(
			  event          = "dataExportTemplates.#arguments.templateId#.#arguments.methodName#"
			, private        = true
			, prepostExempt  = true
			, eventArguments = args
		);
	}

	public string function getSaveExportFormName( templateId, objectName, baseForm="dataExport.saveExportConfiguration.base" ) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		var formName  = arguments.baseForm;
		var mergeWith = "";

		if ( templateMethodExists( arguments.templateId, "getSaveExportFormName" ) ) {
			formName = runTemplateMethod( arguments.templateId, "getSaveExportFormName", { objectName=arguments.objectName, baseFormName=formName } );
		} else if ( _getFormsService().formExists( "dataExportTemplate.#arguments.templateId#.save" ) ) {
			mergeWith = "dataExportTemplate.#arguments.templateId#.save";
		}

		if ( Len( Trim( mergeWith ) ) ) {
			formName = _getFormsService().getMergedFormName( formName, mergeWith );
		}

		return formName;
	}

	public string function getAllowedExporters( templateId, objectName ) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( templateMethodExists( arguments.templateId, "getAllowedExporters" ) ) {
			var exporters = runTemplateMethod( arguments.templateId, "getAllowedExporters", { objectName=arguments.objectName } );
			if ( IsArray( exporters ) ) {
				return ArrayToList( exporters );
			}

			return exporters;
		}

		return "";

	}

	public string function getDefaultExporter( templateId, objectName, allowedExporters ) {
		arguments.templateId = _getValidTemplateId( arguments.templateId );

		if ( ListLen( Trim( arguments.allowedExporters ) )==1 ) {
			return arguments.allowedExporters;
		}

		if ( templateMethodExists( arguments.templateId, "getDefaultExporter" ) ) {
			return runTemplateMethod( arguments.templateId, "getDefaultExporter", { objectName=arguments.objectName } );
		}

		return $getColdbox().getSetting( name="dataExport.defaultExporter" , defaultValue="" );
	}

// PRIVATE HELPERS
	private array function _readTemplates() {
		var handlers = $getColdbox().listHandlers( thatStartWith="dataExportTemplates." );
		var templates = [];

		for( var handler in handlers ) {
			var templateId = ListRest( handler, "." );

			ArrayAppend( templates, templateId );
		}

		_setTemplates( templates );

		return templates;
	}

	private string function _getConfigFormName( templateId, objectName ) {
		var formName  = "dataExport.exportConfiguration.base";
		var mergeWith = "";

		if ( templateMethodExists( arguments.templateId, "getConfigFormName" ) ) {
			formName = runTemplateMethod( arguments.templateId, "getConfigFormName", { objectName=arguments.objectName, baseFormName=formName } );

		} else if ( _getFormsService().formExists( "dataExportTemplate.#arguments.templateId#.config" ) ) {
			mergeWith = "dataExportTemplate.#arguments.templateId#.config";
		}

		if ( Len( Trim( mergeWith ) ) ) {
			formName = _getFormsService().getMergedFormName( formName, mergeWith );
		}

		return formName;
	}

	private string function _getDefaultFileName( templateId, objectName ) {
		if ( templateMethodExists( arguments.templateId, "getDefaultFilename" ) ) {
			return runTemplateMethod( arguments.templateId, "getDefaultFilename", { objectName=arguments.objectName } );
		}
		return $translateresource(
			  uri  = "cms:dataexport.config.form.field.title.default"
			, data = [ $helpers.translateObjectName( arguments.objectName ), DateTimeFormat( Now(), 'yyyy-mm-dd HH:nn' ) ]
		);
	}

	private string function _getValidTemplateId( templateId ) {
		if ( !Len( Trim( arguments.templateId ) ) || !templateExists( arguments.templateId ) ) {
			return "default";
		}

		return Trim( arguments.templateId );
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
component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required array configuredTemplates, required array autoDiscoverDirectories ) output=false {
		super.init( argumentCollection = arguments );

		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		_setConfiguredTemplates( arguments.configuredTemplates );

		reload();

		return this;
	}

// PUBLIC API
	public array function listTemplates() output=false {
		var templates = _getRegisteredTemplates();
		var id        = "";
		var arr = [];

		for( id in templates ){
			ArrayAppend( arr, templates[ id ] );
		}

		return arr;
	}

	public boolean function templateExists( required string id ) output=false {
		return StructKeyExists( _getRegisteredTemplates(), arguments.id );
	}

	public Template function getTemplate( required string id ) output=false {
		var templates = _getRegisteredTemplates();

		if ( not StructKeyExists( templates, arguments.id ) ) {
			throw(
				  type    = "PageTemplatesService.missingTemplate"
				, message = "The template, [#arguments.id#], was not registered with the Preside page templates system"
			);
		}

		return templates[ arguments.id ];
	}

	public void function reload() output=false {
		_setRegisteredTemplates({});
		_autoDiscoverTemplates();
		_registerConfiguredTemplates();
	}

// PRIVATE HELPERS
	private void function _autoDiscoverTemplates() output=false {
		var viewsPath               = "/views/templates";
		var handlersPath            = "/handlers/templates";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir   = ReReplace( dir, "/$", "" );
			var views    = DirectoryList( dir & viewsPath   , false, "query" );
			var handlers = DirectoryList( dir & handlersPath, false, "query", "*.cfc" );

			for ( var view in views ) {
				if ( views.type eq "Dir" ) {
					ids[ views.name ] = 1;
				} elseif ( views.type eq "File" and ReFindNoCase( "\.cfm$", views.name ) ) {
					ids[ ReReplaceNoCase( views.name, "\.cfm$", "" ) ] = 1;
				}
			}

			for ( var handler in handlers ) {
				if ( handlers.type eq "File" ) {
					ids[ ReReplace( handlers.name, "\.cfc$", "" ) ] = 1;
				}
			}
		}

		for( var id in ids ) {
			_registerTemplate(
				  id            = id
				, name          = _getTemplateNameByConvention( id )
				, handler       = _getTemplateHandlerByConvention( id )
				, configForm    = _getTemplateConfigFormByConvention( id )
				, defaultAction = _getDefaultTemplateHandlerAction()
			);
		}
	}

	private void function _registerConfiguredTemplates() output=false {
		var templates = _getConfiguredTemplates();
		var template  = "";

		for( template in templates ) {
			if ( not Len( Trim( template.id ?: "" ) ) ) {
				throw(
					  type    = "PresidePageTemplates.invalidTemplateDefinition"
					, message = "Page templates defined in config must have an id."
					, detail  = "Erroneous definition: #serializeJson( template )#"
				);
			}

			_registerTemplate(
				  id            = template.id
				, name          = template.name          ?: _getTemplateNameByConvention( template.id )
				, handler       = template.handler       ?: _getTemplateHandlerByConvention( template.id )
				, configForm    = template.configForm    ?: _getTemplateConfigFormByConvention( template.id )
				, defaultAction = template.defaultAction ?: _getDefaultTemplateHandlerAction()
			);
		}
	}

	private void function _registerTemplate( required string id, required string name, required string handler, required string defaultAction, string configForm="page-templates.#arguments.id#" ) output=false {
		var templates = _getRegisteredTemplates();

		templates[ arguments.id ] = new Template(
			  id            = arguments.id
			, name          = arguments.name
			, handler       = arguments.handler
			, defaultAction = arguments.defaultAction
			, configForm    = arguments.configForm
		);
	}

	private string function _getTemplateNameByConvention( required string templateId ) output=false {
		return "templates.#arguments.templateId#:name";
	}

	private string function _getTemplateHandlerByConvention( required string templateId ) output=false {
		return "templates.#arguments.templateId#";
	}

	private string function _getTemplateConfigFormByConvention( required string templateId ) output=false {
		return "page-templates.#arguments.templateId#";
	}

	private string function _getDefaultTemplateHandlerAction() output=false {
		return "";
	}

// PRIVATE GETTERS AND SETTERS
	private struct function _getRegisteredTemplates() output=false {
		param name="_registeredTemplates" default=StructNew( "linked" );
		return _registeredTemplates;
	}
	private void function _setRegisteredTemplates( required struct registeredTemplates ) output=false {
		_registeredTemplates = arguments.registeredTemplates;
	}

	private array function _getAutoDiscoverDirectories() output=false {
		return _autoDiscoverDirectories;
	}
	private void function _setAutoDiscoverDirectories( required array autoDiscoverDirectories ) output=false {
		_autoDiscoverDirectories = arguments.autoDiscoverDirectories;
	}

	private array function _getConfiguredTemplates() output=false {
		return _configuredTemplates;
	}
	private void function _setConfiguredTemplates( required array configuredTemplates ) output=false {
		_configuredTemplates = arguments.configuredTemplates;
	}
}
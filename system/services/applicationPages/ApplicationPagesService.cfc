/**
 * Service for interacting with application pages. See :doc:`/devguides/applicationpages`.
 *
 */
component output=false singleton=true autodoc=true {

// CONSTRUCTOR
	/**
	 * @formsService.inject    formsService
	 * @siteService.inject     siteService
	 * @pageConfigDao.inject   presidecms:object:application_page_config
	 * @configuredPages.inject coldbox:setting:applicationPages
	 */
	public any function init( required any formsService, required any siteService, required any pageConfigDao, required struct configuredPages ) output=false {
		_setFormsService( arguments.formsService );
		_setSiteService( arguments.siteService );
		_setPageConfigDao( arguments.pageConfigDao );
		_setConfiguredPages( arguments.configuredPages );
		_processConfiguredPages();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of ids of all the registered application pages
	 */
	public array function listPages() output=false autodoc=true {
		return _getConfiguredPages().keyArray();
	}

	/**
	 * Returns configured details of the page referred to in the passed 'id' argument
	 *
	 * @id.hint ID of the page who's details you wish to retrieve
	 *
	 */
	public struct function getPage( required string id ) output=false autodoc=true {
		var pages = _getConfiguredPages();

		return pages[ arguments.id ] ?: throw(
			  type    = "ApplicationPagesService.page.notFound"
			, message = "The application page, [#arguments.id#], is not registered with the system."
		);
	}

	/**
	 * Returns whether or not the passed in page is registered with the system
	 *
	 * @id.hint ID of the page that we wish to check
	 */
	public boolean function pageExists( required string id ) output=false autodoc=true {
		return _getConfiguredPages().keyExists( arguments.id );
	}

	/**
	 * Returns the id of the page who's coldbox handler is registered as the passed handler
	 *
	 * @handler.hint The ColdBox handler with which to match the page
	 */
	public string function getPageIdByHandler( required string handler ) output=false autodoc=true {
		var pages = _getConfiguredPages();

		for( var pageId in pages ) {
			var pageHandler = pages[ pageId ].handler ?: "";
			if ( pageHandler == arguments.handler ) {
				return pageId;
			}
		}
		return "";
	}

	/**
	 * Returns all the application pages in a tree array. Returns just ids and ids of children.
	 */
	public array function getTree() output=false autodoc=true {
		var tree = Duplicate( _getTree() );
		var removeInactiveNodes = function( array nodes ){
			for( var i=nodes.len(); i > 0; i-- ){
				if ( !isPageAvailableInActiveSiteTemplate( nodes[ i ].id ) ) {
					nodes.deleteAt( i );
					continue;
				}
				nodes[ i ].children = removeInactiveNodes( nodes[ i ].children ?: [] );
			}

			return nodes;
		}

		return removeInactiveNodes( tree );
	}

	/**
	 * Returns the name of the form to use for configuring a given application page
	 *
	 * @id.hint ID of the page who's configuration form name we wish to retrieve
	 */
	public string function getPageConfigFormName( required string id ) output=false autodoc=true {
		var formsService = _getFormsService();
		var defaultFormName = "application-pages.default";
		var customFormName  = "application-pages.#arguments.id#";

		if ( formsService.formExists( customFormName ) ) {
			return formsService.getMergedFormName( defaultFormName, customFormName );
		}

		return defaultFormName;
	}

	/**
	 * Returns the stored page configuration for the given page merged
	 * with any defaults saved in the form definition of the page
	 *
	 * @id.hint ID of the page who's config we wish to get
	 */
	public struct function getPageConfiguration( required string id, boolean includeDefaults=true ) output=false autodoc=true {
		var page         = getPage( arguments.id );
		var formName     = getPageConfigFormName( arguments.id );
		var formFields   = _getFormsService().listFields( formName );
		var config       = {};
		var storedConfig = _getPageConfigDao().selectData(
			  selectFields = [ "setting_name", "value" ]
			, filter       = { setting_name=formFields, page_id=arguments.id }
		);

		for( var setting in storedConfig ){
			config[ setting.setting_name ] = setting.value;
		}

		for( var setting in formFields ) {
			if ( !config.keyExists( setting ) || !Len( Trim( config[ setting ] ) ) ) {
				var fieldDefinition = _getFormsService().getFormField( formName, setting );
				config[ setting ] = fieldDefinition.default ?: "";
			}
		}

		for( var setting in config ) {
			if ( !Len( Trim( config[ setting ] ) ) ) {
				config.delete( setting );
			}
		}

		if ( arguments.includeDefaults ) {
			config.append( ( page.defaults ?: {} ), false );
		}

		return config;
	}

	/**
	 * Saves the passed page configuration to the database
	 *
	 * @id.hint     ID of the page who's config we are saving
	 * @config.hint Structure of configuration data
	 */
	public void function savePageConfiguration( required string id, required struct config ) output=false autodoc=true {
		transaction {
			var existingConfig = getPageConfiguration( id=arguments.id, includeDefaults=false );
			var dao            = _getPageConfigDao();

			for( var setting in arguments.config ){
				if ( !Len( Trim( arguments.config[ setting ] ) ) ) {
					dao.deleteData( filter = { page_id = arguments.id, setting_name = setting } );
					continue;
				}

				if ( existingConfig.keyExists( setting ) && Len( Trim( existingConfig[ setting ] ) ) ) {
					dao.updateData(
						  filter = { page_id = arguments.id, setting_name = setting }
						, data   = { value = arguments.config[ setting ] }
					);
				} else {
					dao.insertData( data={
						  page_id      = arguments.id
						, setting_name = setting
						, value        = arguments.config[ setting ]
					} );
				}
			}
		}

		return;
	}

	/**
	 * Gets all the ancestors of the given page, including their configuration
	 *
	 * @id.hint ID of the page who's ancestors we are to get
	 */
	public array function getAncestors( required string id ) output=false {
		if ( !pageExists( arguments.id ) ) {
			return [];
		}

		var ancestors = [];
		var parentId = arguments.id;

		while( ListLen( parentId, "." ) > 1 ){
			parentId = ListDeleteAt( parentId, ListLen( parentId, "." ), "." );

			var parent = Duplicate( getPage( parentId ) );

			parent.id     = parentId;
			parent.config = getPageConfiguration( parentId );

			ancestors.append( parent );
		}

		return ancestors;
	}

	/**
	 * Returns whether or not the page can be used within the current site template
	 *
	 * @id.hint ID of the page that we want to check site template availability
	 */
	public boolean function isPageAvailableInActiveSiteTemplate( required string id ) output=false {
		var activeTemplate = _getSiteService().getActiveSiteTemplate();
		var page           = getPage( arguments.id );

		if ( !Len( Trim( activeTemplate ) ) ) {
			return true;
		}

		if ( !page.keyExists( "siteTemplates" ) ) {
			var ancestors = getAncestors( arguments.id );

			for( var ancestor in ancestors ){
				if( !ancestor.keyExists( "siteTemplates" ) ) {
					continue;
				}

				return ancestor.siteTemplates.find( activeTemplate ) || ancestor.siteTemplates.find( "*" );
			}

			return true;
		}

		return page.siteTemplates.find( activeTemplate ) || page.siteTemplates.find( "*" );
	}



// PRIVATE HELPERS
	private void function _processConfiguredPages() output=false {
		var configuredPages = _getConfiguredPages();
		var processed       = {};
		var tree            = [];
		var processPage     = function( pageName, page, treeNode ){
			processed[ pageName ] = Duplicate( page );
			processed[ pageName ].delete( "children" );
			var node = { id=pageName, children=[] };

			if ( page.keyExists( "children" ) ) {
				for( var child in page.children ) {
					processPage( pageName & "." & child, page.children[child], node.children );
				}
			}

			node.children.sort( function( a, b ){
				return a.id > b.id ? 1 : -1;
			} );

			treeNode.append( node );
		};

		for( var page in configuredPages ){
			processPage( page, configuredPages[ page ], tree );
		}

		_setConfiguredPages( processed );

		tree.sort( function( a, b ){
			return a.id > b.id ? 1 : -1;
		} );
		_setTree( tree );
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredPages() output=false {
		return _configuredPages;
	}
	private void function _setConfiguredPages( required struct configuredPages ) output=false {
		_configuredPages = arguments.configuredPages;
	}

	private any function _getFormsService() output=false {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) output=false {
		_formsService = arguments.formsService;
	}

	private any function _getPageConfigDao() output=false {
		return _pageConfigDao;
	}
	private void function _setPageConfigDao( required any PpgeConfigDao ) output=false {
		_pageConfigDao = arguments.PpgeConfigDao;
	}

	private array function _getTree() output=false {
		return _tree;
	}
	private void function _setTree( required array tree ) output=false {
		_tree = arguments.tree;
	}

	private any function _getSiteService() output=false {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) output=false {
		_siteService = arguments.siteService;
	}

}
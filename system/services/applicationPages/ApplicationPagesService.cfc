/**
 * Service for interacting with application pages. See :doc:`/devguides/applicationpages`.
 *
 */
component output=false autodoc=true {

// CONSTRUCTOR
	/**
	 * @formsService.inject    formsService
	 * @pageConfigDao.inject   presidecms:object:application_page_config
	 * @configuredPages.inject coldbox:setting:applicationPages
	 */
	public any function init( required any formsService, required any pageConfigDao, required struct configuredPages ) output=false {
		_setFormsService( arguments.formsService );
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
	 * Returns all the application pages in a tree array. Returns just ids and ids of children.
	 */
	public array function getTree() output=false autodoc=true {
		return _getTree();
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
	public struct function getPageConfiguration( required string id ) output=false autodoc=true {
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

		config.append( ( page.defaults ?: {} ), false );

		return config;
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

}
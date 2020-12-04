/**
 * The system configuration service provides the API layer
 * for interacting with Preside' [[editablesystemsettings]].
 *
 * @singleton
 * @presideService
 * @autodoc
 */
component displayName="System configuration service" {

// CONSTRUCTOR
	/**
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @dao.inject                     presidecms:object:system_config
	 * @env.inject                     coldbox:setting:env
	 * @formsService.inject            delayedInjector:formsService
	 * @siteService.inject             delayedInjector:siteService
	 * @tenancyService.inject          delayedInjector:tenancyService
	 * @settingsCache.inject           cachebox:PresideSystemSettingsCache
	 */
	public any function init(
		  required array  autoDiscoverDirectories
		, required any    dao
		, required struct env
		, required any    formsService
		, required any    siteService
		, required any    tenancyService
		, required any    settingsCache
	) {
		_setAutoDiscoverDirectories( arguments.autoDiscoverDirectories );
		_setDao( arguments.dao );
		_setEnv( arguments.env );
		_setFormsService( arguments.formsService );
		_setSiteService( arguments.siteService );
		_setTenancyService( arguments.tenancyService );
		_setSettingsCache( arguments.settingsCache );
		_setLoaded( false );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns a setting that has been saved.
	 * See [[editablesystemsettings]] for a full guide.
	 *
	 * @autodoc
	 * @category.hint  Category name of the setting to get
	 * @setting.hint   Name of the setting to get
	 * @default.hint   A default value to return should no value be saved for the setting
	 *
	 */
	public string function getSetting( required string category, required string setting, string default="" ) {
		_reloadCheck();

		var tenantId   = getCurrentTenantIdForCategory( arguments.category );
		var cache      = _getSettingsCache();
		var cacheKey   = "setting.#arguments.category#.#arguments.setting#.#arguments.default#.#tenantId#";
		var fromCache  = cache.get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var injected = _getEnv();
		var tenancy  = getConfigCategoryTenancy( arguments.category );

		if ( Len( tenancy ) && Len( tenantId ) ) {
			var filter = {
				  category = arguments.category
				, setting  = arguments.setting
			};

			if ( tenancy == "site" ) {
				filter.site = tenantId;
			} else {
				filter.tenant_id = tenantId;
			}

			var result = _getDao().selectData(
				  selectFields = [ "value" ]
				, filter       = filter
			);

			if ( result.recordCount ) {
				cache.set( cacheKey, result.value );
				return result.value;
			}
		}

		var result = _getDao().selectData(
			  selectFields = [ "value" ]
			, filter       = "category = :category and setting = :setting and site is null and tenant_id is null"
			, filterParams = {
				  category = arguments.category
				, setting  = arguments.setting
			  }
		);

		if ( result.recordCount ) {
			cache.set( cacheKey, result.value );
			return result.value;
		}

		result = injected[ "#arguments.category#.#arguments.setting#" ] ?: arguments.default;
		cache.set( cacheKey, result );

		return result;
	}

	/**
	 * Returns all the saved settings for a given category.
	 * See [[editablesystemsettings]] for a full guide.
	 *
	 * @autodoc
	 * @category.hint           The name of the category whose settings you wish to get
	 * @includeDefaults.hint    Whether to include default global and injected settings or whether to just return the settings for the current site
	 * @globalDefaultsOnly.hint Whether to only include default global and injected settings or whether to include all amalgamated settings
	 * @siteId.hint             Deprecated (use tenantId from now on) - indicates the site for which you'd like to get settings
	 * @tenantId.hint           ID of the tenant for which you'd like to get settings (tenancy object source can be different per category)
	 */
	public struct function getCategorySettings(
		  required string  category
		,          boolean includeDefaults    = true
		,          boolean globalDefaultsOnly = false
		,          string  siteId             = getCurrentTenantIdForCategory( arguments.category )
		,          string  tenantId           = arguments.siteId
	) {
		_reloadCheck();
		var cache      = _getSettingsCache();
		var cacheKey   = "setting.#arguments.category#.category.#arguments.includeDefaults#.#arguments.globalDefaultsOnly#.#arguments.tenantId#";
		var fromCache  = cache.get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var result = {};
		var tenancy = getConfigCategoryTenancy( arguments.category );
		var globalOnly = !Len( tenancy ) || !Len( arguments.tenantId ) || arguments.globalDefaultsOnly;

		if ( !globalOnly ) {
			var filter = { category=arguments.category };
			if ( tenancy == "site" ) {
				filter.site = arguments.tenantId;
			} else {
				filter.tenant_id = arguments.tenantId;
			}
			var rawSiteResult = _getDao().selectData(
				  selectFields = [ "setting", "value" ]
				, filter       = filter
			);

			for( var record in rawSiteResult ){
				result[ record.setting ] = record.value;
			}
		}

		if ( globalOnly || arguments.includeDefaults ) {
			var rawGlobalResult = _getDao().selectData(
				  selectFields = [ "setting", "value" ]
				, filter       = "category = :category and site is null and tenant_id is null"
				, filterParams = { category = arguments.category }
			);

			for( var record in rawGlobalResult ){
				if ( !StructKeyExists( result, record.setting ) ) {
					result[ record.setting ] = record.value;
				}
			}

			var injectedStartsWith = "^#arguments.category#\.";
			var injected = _getEnv().filter( function( key ){ return key.reFindNoCase( injectedStartsWith ) } );
			for( var key in injected ) {
				var setting = ListRest( key, "." );

				if ( !StructKeyExists( result, setting ) ) {
					result[ setting ] = injected[ key ];
				}
			}
		}

		cache.set( cacheKey, result );

		return result;
	}

	/**
	 * Saves the value of a setting.
	 * See [[editablesystemsettings]] for a full guide.
	 *
	 * @autodoc
	 * @category.hint  Category name of the setting to save
	 * @setting.hint   Name of the setting to save
	 * @value.hint     Value to save
	 * @siteId.hint    Deprecated (use tenantId): ID of site to which the setting applies (optional, if empty setting is treated as system wide default)
	 * @tenantId.hint  ID of the tenant to which the setting applies (optional, if empty setting is treated as system wide default)
	 *
	 */
	public any function saveSetting(
		  required string category
		, required string setting
		, required string value
		,          string siteId = ""
		,          string tenantId = arguments.siteId
	)  {
		_reloadCheck();

		var dao    = _getDao();
		var result = "";
		var tenancy = getConfigCategoryTenancy( arguments.category );

		transaction {
			var filter = "category = :category and setting = :setting";
			var params = { category = arguments.category, setting = arguments.setting };
			var data   = {
				  category  = arguments.category
				, setting   = arguments.setting
				, value     = arguments.value
				, site      = ""
				, tenant_id = ""
			};

			if ( Len( tenancy ) && Len( Trim( arguments.tenantId ) ) ) {
				if ( tenancy == "site" ) {
					filter &= " and site = :site";
					params.site = arguments.tenantId;

					data.site = arguments.tenantId;
				} else {
					filter &= " and tenant_id = :tenant_id";
					params.tenant_id = arguments.tenantId;
					data.tenant_id = arguments.tenantId;
				}
			} else {
				filter &= " and site is null and tenant_id is null";
			}

			result = dao.updateData(
				  data         = { value = arguments.value }
				, filter       = filter
				, filterParams = params
			);

			if ( !result ) {
				result = dao.insertData( data );
			}
		}

		clearSettingsCache( arguments.category );

		return result;
	}

	public any function deleteSetting(
		  required string category
		, required string setting
		,          string siteId   = ""
		,          string tenantId = arguments.siteId
	)  {
		_reloadCheck();

		var dao    = _getDao();
		var filter = "category = :category and setting = :setting";
		var params = { category = arguments.category, setting = arguments.setting };

		if ( Len( Trim( arguments.tenantId ) ) ) {
			var tenancy = getConfigCategoryTenancy( arguments.category );

			if ( tenancy == "site" ) {
				filter &= " and site = :site";
				params.site = arguments.tenantId;
			} else {
				filter &= " and tenant_id = :tenant_id";
				params.tenant_id = arguments.tenantId;
			}
		}

		var result = dao.deleteData(
			  filter       = filter
			, filterParams = params
		);

		clearSettingsCache( arguments.category );

		return result;
	}

	public array function listConfigCategories() {
		_reloadCheck();

		var categories = _getConfigCategories();
		var result    = [];

		for( var id in categories ){
			ArrayAppend( result, categories[ id ] );
		}

		return result;
	}

	public ConfigCategory function getConfigCategory( required string id ) {
		_reloadCheck();

		var categories = _getConfigCategories();

		if ( StructKeyExists( categories, arguments.id ) ) {
			return categories[ arguments.id ];
		}

		categories = categories.keyArray();
		categories.sort( "textnocase" );
		categories = SerializeJson( categories );

		throw(
			  type    = "SystemConfigurationService.category.notFound"
			, message = "The configuration category [#arguments.id#] could not be found. Configured categories are: #categories#"
		);
	}

	public boolean function configCategoryExists( required string id ) {
		_reloadCheck();

		var categories = _getConfigCategories();

		return StructKeyExists( categories, arguments.id );
	}

	public string function getConfigCategoryTenancy( required string id ) {
		if ( configCategoryExists( arguments.id ) ) {
			var cat = getConfigCategory( arguments.id );
			if ( cat.getNoTenancy() ) {
				return "";
			}

			return cat.getTenancy();
		}

		return "site";
	}

	public string function getCurrentTenantIdForCategory( required string id ) {
		var tenancy = getConfigCategoryTenancy( arguments.id );

		if ( Len( tenancy ) ) {
			return _getTenancyService().getTenantId( tenancy );
		}

		return "";
	}

	public void function reload() {
		_setConfigCategories({});
		_autoDiscoverCategories();

		$announceInterception( "onReloadConfigCategories", { categories=_getConfigCategories() } );
	}

	public void function clearSettingsCache( required string category ) {
		_getSettingsCache().clearByKeySnippet(
			  keySnippet = "^setting\.#arguments.category#\."
			, regex      = true
			, async      = false
		);
		$announceInterception( "onClearSettingsCache", arguments );
	}

// PRIVATE HELPERS
	private void function _autoDiscoverCategories() {
		var objectsPath             = "/forms/system-config";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDiscoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir   = ReReplace( dir, "/$", "" );
			var objects = DirectoryList( dir & objectsPath, false, "query", "*.xml" );

			for ( var obj in objects ) {
				if ( obj.type eq "File" ) {
					ids[ ReReplace( obj.name, "\.xml$", "" ) ] = true;
				}
			}
		}

		for( var id in ids ) {
			if ( _getFormsService().formExists( formName="system-config." & id, checkSiteTemplates=false ) ) {
				_registerCategory( id = LCase( id ) );
			}
		}
	}

	private void function _registerCategory( required string id ) {
		var categories     = _getConfigCategories();
		var formName       = _getConventionsBaseCategoryForm( arguments.id );
		var formAttributes = _getFormsService().getForm( formName );

		categories[ arguments.id ] = new ConfigCategory(
			  id               = arguments.id
			, name             = _getConventionsBaseCategoryName( arguments.id )
			, description      = _getConventionsBaseCategoryDescription( arguments.id )
			, icon             = _getConventionsBaseCategoryIcon( arguments.id )
			, form             = formName
			, siteForm         = _getConventionsBaseSiteCategoryForm( arguments.id )
			, tenancy          = formAttributes.tenancy ?: "site"
			, noTenancy        = $helpers.isTrue( formAttributes.notenancy ?: "" )
			, siteForm         = _getConventionsBaseSiteCategoryForm( arguments.id )
		);
	}

	private string function _getConventionsBaseCategoryName( required string id ) {
		return "system-config.#arguments.id#:name";
	}
	private string function _getConventionsBaseCategoryDescription( required string id ) {
		return "system-config.#arguments.id#:description";
	}
	private string function _getConventionsBaseCategoryIcon( required string id ) {
		return "system-config.#arguments.id#:iconClass";
	}
	private string function _getConventionsBaseCategoryForm( required string id ) {
		return "system-config.#arguments.id#";
	}
	private string function _getConventionsBaseSiteCategoryForm( required string id ) {
		var fullFormName = _getConventionsBaseCategoryForm( arguments.id );

		return _getFormsService().createForm( basedOn=fullFormName, generator=function( definition ){
			var rawForm = definition.getRawDefinition();
			var tabs    = rawForm.tabs ?: [];

			for( var tab in tabs ) {
				var fieldsets = tab.fieldsets ?: [];

				for ( var fieldset in tab.fieldsets ) {
					var fields = fieldset.fields ?: [];

					for( var field in fields ) {
						definition.modifyField( name=field.name ?: "", fieldset=fieldset.id ?: "", tab=tab.id ?: "", required=false );
					}
				}
			}
		} );
	}

	private void function _reloadCheck() {
		if ( !_isLoaded() ) {
			reload();
			_setLoaded( true );
		}
	}

// GETTERS AND SETTERS
	private array function _getAutoDiscoverDirectories() {
		return _autoDiscoverDirectories;
	}
	private void function _setAutoDiscoverDirectories( required array autoDiscoverDirectories ) {
		_autoDiscoverDirectories = arguments.autoDiscoverDirectories;
	}

	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}

	private struct function _getConfigCategories() {
		return _configCategories;
	}
	private void function _setConfigCategories( required struct configCategories ) {
		_configCategories = arguments.configCategories;
	}

	private struct function _getEnv() {
		return _injectedConfig;
	}
	private void function _setEnv( required struct env ) {
		_injectedConfig = arguments.env;
	}

	private struct function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required struct formsService ) {
		_formsService = arguments.formsService;
	}

	private boolean function _isLoaded() {
		return _loaded;
	}
	private void function _setLoaded( required boolean loaded ) {
		_loaded = arguments.loaded;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private any function _getSettingsCache() {
	    return _settingsCache;
	}
	private void function _setSettingsCache( required any settingsCache ) {
	    _settingsCache = arguments.settingsCache;
	}

	private any function _getTenancyService() {
	    return _tenancyService;
	}
	private void function _setTenancyService( required any tenancyService ) {
	    _tenancyService = arguments.tenancyService;
	}
}
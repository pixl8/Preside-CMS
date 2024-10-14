/**
* Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* The system web renderer
* @author Luis Majano <lmajano@ortussolutions.com>
*/
component accessors="true" serializable="false" singleton="true" extends="coldbox.system.FrameworkSupertype" {

	/************************************** DI *********************************************/

	/**
	* Template cache provider
	*/
	property name="templateCache" 	inject="cachebox:template";
	/**
	* HTML Helper
	*/
	property name="html"			inject="HTMLHelper@coldbox";

	/************************************** PROPERTIES *********************************************/

	// Location of layouts
	property name="layoutsConvention";
	// Location of external layouts
	property name="LayoutsExternalLocation";
	// Location of views
	property name="viewsConvention";
	// Location of external views
	property name="ViewsExternalLocation";
	// Location of application
	property name="appMapping";
	// Modules configuration
	property name="moduleConfig" type="struct";
	// Views Helper Setting
	property name="viewsHelper";
	// View helper include bit
	property name="isViewsHelperIncluded" default="false" type="boolean";
	// Are we rendering a layout+view combination
	property name="explicitView";
	// Rendered helpers metadata
	property name="renderedHelpers" type="struct";
	// Internal locking name
	property name="lockName";
	// Discovery caching is tied to handlers for discovery.
	property name="isDiscoveryCaching";

	// View/Layout Properties
	property name="event";
	property name="rc";
	property name="prc";

	/************************************** CONSTRUCTOR *********************************************/

	/**
	* Constructor
	* @controller The ColdBox main controller
	* @controller.inject coldbox
	*/
	function init( required controller ){
		// setup controller
		variables.controller = arguments.controller;
		// Register LogBox
		variables.logBox = arguments.controller.getLogBox();
		// Register Log object
		variables.log = variables.logBox.getLogger( this );
		// Register Flash RAM
		variables.flash = arguments.controller.getRequestService().getFlashScope();
		// Register CacheBox
		variables.cacheBox = arguments.controller.getCacheBox();
		// Register WireBox
		variables.wireBox = arguments.controller.getWireBox();
		// Register thread utils
		variables.threadUtil = wirebox.getInstance( "threadUtil" );

		// Set Conventions, Settings and Properties
		variables.layoutsConvention 		= variables.controller.getSetting( "layoutsConvention", true );
		variables.viewsConvention 			= variables.controller.getSetting( "viewsConvention", true );
		variables.appMapping 				= variables.controller.getSetting( "AppMapping" );
		variables.viewsExternalLocation 	= variables.controller.getSetting( "ViewsExternalLocation" );
		variables.layoutsExternalLocation 	= variables.controller.getSetting( "LayoutsExternalLocation" );
		variables.modulesConfig				= variables.controller.getSetting( "modules" );
		variables.viewsHelper				= variables.controller.getSetting( "viewsHelper" );
		variables.viewCaching				= variables.controller.getSetting( "viewCaching" );
		variables.isViewsHelperIncluded		= false;

		// Verify View Helper Template extension + location
		if( len( variables.viewsHelper ) ){
			// extension detection
			variables.viewsHelper = ( listLast( variables.viewsHelper, "." ) eq "cfm" ? variables.viewsHelper : variables.viewsHelper & ".cfm" );
			// Append mapping to it.
			variables.viewsHelper = "/#variables.appMapping#/#variables.viewsHelper#";
		}

		// Template Cache & Caching Maps
		variables.renderedHelpers	= {};
		variables.lockName			= "rendering.#variables.controller.getAppHash()#";

		// Discovery caching is tied to handlers for discovery.
		variables.isDiscoveryCaching = controller.getSetting( "handlerCaching" );

		// Load global UDF Libraries into target
		loadApplicationHelpers();

		return this;
	}

	/************************************** VIEW METHODS *********************************************/

	/**
	* Render out a view
	* @view The the view to render, if not passed, then we look in the request context for the current set view.
	* @args A struct of arguments to pass into the view for rendering, will be available as 'args' in the view.
	* @module The module to render the view from explicitly
	* @cache Cached the view output or not, defaults to false
	* @cacheTimeout The time in minutes to cache the view
	* @cacheLastAccessTimeout The time in minutes the view will be removed from cache if idle or requested
	* @cacheSuffix The suffix to add into the cache entry for this view rendering
	* @cacheProvider The provider to cache this view in, defaults to 'template'
	* @collection A collection to use by this Renderer to render the view as many times as the items in the collection (Array or Query)
	* @collectionAs The name of the collection variable in the partial rendering.  If not passed, we will use the name of the view by convention
	* @collectionStartRow The start row to limit the collection rendering with
	* @collectionMaxRows The max rows to iterate over the collection rendering with
	* @collectionDelim  A string to delimit the collection renderings by
	* @prePostExempt If true, pre/post view interceptors will not be fired. By default they do fire
	*/
	function renderView(
		view="",
		struct args=getRequestContext().getCurrentViewArgs(),
		module="",
		boolean cache=false,
		cacheTimeout="",
		cacheLastAccessTimeout="",
		cacheSuffix="",
		cacheProvider="template",
		collection,
		collectionAs="",
		numeric collectionStartRow="1",
		numeric collectionMaxRows=0,
		collectionDelim="",
		boolean prePostExempt=false,
		numeric _counter,
		numeric _records
	){
		if ( Len( Trim( arguments.presideObject ?: "" ) ) ) {
			return wireBox.getInstance( "presideObjectViewService" ).renderView(
				argumentCollection = arguments
			);
		}

		var viewCacheKey 		= "";
		var viewCacheEntry 		= "";
		var viewCacheProvider 	= variables.templateCache;
		var iData 				= arguments;
		var explicitModule 		= false;
		var viewLocations		= "";
		var event               = getRequestContext();

		// If no incoming explicit module call, default the value to the one in the request context for convenience
		if( NOT len( arguments.module ) ){
			// check for an explicit view module
			arguments.module = event.getCurrentViewModule();
			// if module is still empty check the event pattern
			// if no module is execution, this will be empty anyways.
			if( NOT len(arguments.module) ){
				arguments.module = event.getCurrentModule();
			}
		} else {
			explicitModule = true;
		}

		// Rendering an explicit view or do we need to get the view from the context or explicit context?
		if( NOT len( arguments.view ) ){
			if ( event.valueExists( name="__layoutExplicitView" ) ) {
				arguments.view = event.getValue( name="__layoutExplicitView", private=true );
				event.removeValue( name="__layoutExplicitView", private=true );
			} else {
				arguments.view = event.getCurrentView();
			}
		}

		// Do we have a view To render? Else throw exception
		if( NOT len( arguments.view ) ){
			throw( message="The ""currentview"" variable has not been set, therefore there is no view to render.",
				   detail="Please remember to use the 'event.setView()' method in your handler or pass in a view to render.",
				   type="Renderer.ViewNotSetException" );
		}

		// Cleanup leading / in views, just in case
		arguments.view = reReplace( arguments.view, "^(\\|/)", "" );

		// Announce preViewRender interception
		if( NOT arguments.prepostExempt ){ announceInterception( "preViewRender", iData ); }

		// Prepare caching arguments if doing implicit caching, and the view to render is the same as the implicitly cached.
		viewCacheEntry = event.getViewCacheableEntry();
		if( event.isViewCacheable() AND ( arguments.view EQ viewCacheEntry.view ) ){
			arguments.cache						= true;
			arguments.cacheTimeout				= viewCacheEntry.timeout;
			arguments.cacheLastAccessTimeout	= viewCacheEntry.lastAccessTimeout;
			arguments.cacheSuffix 				= viewCacheEntry.cacheSuffix;
			arguments.cacheProvider				= viewCacheEntry.cacheProvider;
		}

		// Prepare caching key
		viewCacheKey = variables.templateCache.VIEW_CACHEKEY_PREFIX;
		// If we have a module, incorporate it
		if( len( arguments.module ) ){ viewCacheKey &= arguments.module & ":"; }
		// Incorporate view and suffix
		viewCacheKey &= arguments.view & arguments.cacheSuffix;

		// Are we caching?
		if ( arguments.cache && variables.viewCaching){
			// Which provider you want to use?
			if( arguments.cacheProvider neq "template" ){
				viewCacheProvider = getCache( arguments.cacheProvider );
			}
			// Try to get from cache
			iData.renderedView = viewCacheProvider.get( viewCacheKey );
			// Verify it existed
			if( structKeyExists(iData, "renderedView") ){
				// Post View Render Interception
				if( NOT arguments.prepostExempt ){ announceInterception("postViewRender", iData); }
				// Return it
				return iData.renderedView;
			}
		}

		// No caching, just render
		// Discover and cache view/helper locations
		viewLocations = discoverViewPaths( view=arguments.view, module=arguments.module, explicitModule=explicitModule );

		// Render collection views
		if( structKeyExists( arguments, "collection" ) ){
			// render collection in next context
			iData.renderedView = renderViewCollection(arguments.view, viewLocations.viewPath, viewLocations.viewHelperPath, arguments.args, arguments.collection, arguments.collectionAs, arguments.collectionStartRow, arguments.collectionMaxRows, arguments.collectionDelim);
		}
		// Render simple composite view
		else{
			iData.renderedView = renderViewComposite(
				  view           = arguments.view
				, viewPath       = viewLocations.viewPath
				, viewHelperPath = viewLocations.viewHelperPath
				, args           = arguments.args
				, _counter       = arguments._counter
				, _records       = arguments._records
			);
		}

		// Post View Render Interception point
		if( NOT arguments.prepostExempt ){ announceInterception( "postViewRender", iData ); }

		// Are we caching view
		if ( arguments.cache && variables.viewCaching){
			viewCacheProvider.set( viewCacheKey, iData.renderedView, arguments.cacheTimeout, arguments.cacheLastAccessTimeout );
		}

		// Return view content
		return iData.renderedView;
	}

	/**
	* Render a view composed of collections, mostly used internally, use at your own risk.
	*/
	function renderViewCollection(
		view,
		viewPath,
		viewHelperPath,
		args,
		collection,
		collectionAs,
		numeric collectionStartRow=1,
		numeric collectionMaxRows=0,
		collectionDelim=""
	){
		var buffer 	= createObject( "java", "java.lang.StringBuilder" ).init();
		var x 		= 1;
		var recLen 	= 0;
		var viewArgs = {
			  view           = arguments.view
			, viewpath       = arguments.viewpath
			, viewHelperPath = arguments.viewHelperPath
			, args           = arguments.args
		};


		// Determine the collectionAs key
		if ( !len( arguments.collectionAs ) ) {
			arguments.collectionAs = listLast( arguments.view, "/" );
		}

		// Array Rendering
		if ( isArray( arguments.collection ) ) {
			recLen = arrayLen( arguments.collection );
			// adjust item count for collectionStartRow
			if ( arguments.collectionStartRow > 1 ) {
				recLen = max( 0, recLen - arguments.collectionStartRow + 1 );
			}
			// is max rows passed?
			if ( arguments.collectionMaxRows != 0 && arguments.collectionMaxRows <= recLen ) {
				recLen = arguments.collectionMaxRows;
			}
			// Create local marker
			viewArgs._items	= recLen;
			// iterate and present
			for( x=arguments.collectionStartRow; x<=recLen; x++ ){
				// setup local variables
				viewArgs._counter = x;
				viewArgs[ arguments.collectionAs ] = arguments.collection[ x ];
				// prepend the delim
				if ( x != arguments.collectionStartRow ) {
					buffer.append( arguments.collectionDelim );
				}
				// render item composite
				buffer.append( renderViewComposite( argumentCollection=viewArgs ) );
			}
			return buffer.toString();
		}

		// Query Rendering
		viewArgs._items = arguments.collection.recordCount;
		// Adjust item count for collectionStartRow
		if ( arguments.collectionStartRow > 1 ) {
			viewArgs._items = max( 0, viewArgs._items - arguments.collectionStartRow + 1 );
		}
		// Max Rows
		if ( arguments.collectionMaxRows != 0 && arguments.collectionMaxRows <= viewArgs._items ) {
			viewArgs._items = arguments.collectionMaxRows;
		}
		//local counter when using startrow is greater than one and x values is reletive to lookup
		var _localCounter = 1;
		for( x=arguments.collectionStartRow; x<=( arguments.collectionStartRow + viewArgs._items ) - 1; x++ ) {
			// setup local cvariables
			viewArgs._counter = _localCounter;

			var columnList = arguments.collection.columnList;
			for( var j=1; j <= listLen( columnList ); j++ ) {
				viewArgs[ arguments.collectionAs ][ ListGetAt( columnList, j ) ] = arguments.collection[ ListGetAt( columnList, j ) ][ x ];
			}

			// prepend the delim
			if ( viewArgs._counter != 1 ) {
				buffer.append( arguments.collectionDelim );
			}

			// render item composite
			buffer.append( renderViewComposite( argumentCollection=viewArgs ) );
			_localCounter++;
		}

		return buffer.toString();
	}

	function outputView(
		  view
		, args = {}
		, rendererVariables = {}
	) output=true {
		if ( StructKeyExists( arguments, "cache" ) && arguments.cache == true ) {
			echo( renderView( argumentCollection=arguments ) );// caching means intermediary variables no matter what
			return;
		}
		if ( StructKeyExists( arguments, "collection" ) ) {
			outputViewCollection( argumentCollection=arguments );
			return;
		}
		silent {
			var event             = getRequestContext();
			var moduleArgs        = {
				  template          = "RendererEncapsulator.cfm"
				, rendererVariables = ( isNull( attributes.rendererVariables ) ? getRendererVariables() : attributes.rendererVariables )
				, event             = event
				, rc                = event.getCollection()
				, prc               = event.getPrivateCollection()
				, viewPath          = locateView( arguments.view )
			};
			StructAppend( moduleArgs, arguments, false );
			StructAppend( moduleArgs.rendererVariables, arguments.rendererVariables );
		}

		module attributeCollection=moduleArgs;
	}

	function outputViewCollection(
		view,
		args,
		collection,
		collectionAs,
		numeric collectionStartRow=1,
		numeric collectionMaxRows=0,
		collectionDelim=""
	) output=true {
		silent {
			var coll   = IsArray( arguments.collection ) ? arguments.collection : queryToArray( arguments.collection );
			var recLen = ArrayLen( coll );

			// Determine the collectionAs key
			if ( !len( arguments.collectionAs ) ) {
				arguments.collectionAs = listLast( arguments.view, "/" );
			}
			if ( arguments.collectionStartRow > 1 ) {
				recLen = max( 0, recLen - arguments.collectionStartRow + 1 );
			}
			// is max rows passed?
			if ( arguments.collectionMaxRows != 0 && arguments.collectionMaxRows <= recLen ) {
				recLen = arguments.collectionMaxRows;
			}

			var viewArgs = { _items=recLen };
		}
		for( var x=arguments.collectionStartRow; x<=recLen; x++ ){
			silent {
				viewArgs._counter = x;
				viewArgs[ arguments.collectionAs ] = coll[ x ];
			}
			if ( x != arguments.collectionStartRow && Len( arguments.collectionDelim ) ) {
				echo( arguments.collectionDelim );
			}
			outputView( view=arguments.view, args=arguments.args, rendererVariables=viewArgs );
		}
		return;
	}

	/**
	* Render a view alongside its helpers, used mostly internally, use at your own risk.
	*/
	private function renderViewComposite(
		view,
		viewPath,
		viewHelperPath,
		args
	){
		var cbox_renderedView = "";
		var event             = getRequestContext();
		var moduleArgs        = {
			  template          = "RendererEncapsulator.cfm"
			, rendererVariables = ( isNull( attributes.rendererVariables ) ? getRendererVariables() : attributes.rendererVariables )
			, event             = event
			, rc                = event.getCollection()
			, prc               = event.getPrivateCollection()
		};
		structAppend( moduleArgs, arguments, false );

		savecontent variable="cbox_renderedView" {
			module attributeCollection=moduleArgs;
		}

		return cbox_renderedView;
	}

	/**
	* Renders an external view anywhere that cfinclude works.
	* @view The the view to render
	* @args A struct of arguments to pass into the view for rendering, will be available as 'args' in the view.
	* @cache Cached the view output or not, defaults to false
	* @cacheTimeout The time in minutes to cache the view
	* @cacheLastAccessTimeout The time in minutes the view will be removed from cache if idle or requested
	* @cacheSuffix The suffix to add into the cache entry for this view rendering
	* @cacheProvider The provider to cache this view in, defaults to 'template'
	*/
	function renderExternalView(
		required view,
		struct args=getRequestContext().getCurrentViewArgs(),
		boolean cache=false,
		cacheTimeout="",
		cacheLastAccessTimeout="",
		cacheSuffix="",
		cacheProvider="template"
	){
		var cbox_renderedView = "";
		// Cache Entries
		var cbox_cacheKey 		= "";
		var cbox_cacheEntry 	= "";
		var cbox_cacheProvider 	= variables.templateCache;
		var viewLocations 		= "";

		// Setup the cache key
		cbox_cacheKey = variables.templateCache.VIEW_CACHEKEY_PREFIX & "external-" & arguments.view & arguments.cacheSuffix;
		// Setup the cache provider
		if( arguments.cacheProvider neq "template" ){ cbox_cacheProvider = getCache( arguments.cacheProvider ); }
		// Try to get from cache
		cbox_renderedView 	= cbox_cacheProvider.get( cbox_cacheKey );
		if( !isNull( local.cbox_renderedView ) ){
			return cbox_renderedView;
		}
		// Not in cache, render it
		// Get view locations
		viewLocations = discoverViewPaths( view=arguments.view, module="", explicitModule=false );
		// Render External View
		cbox_renderedView = renderViewComposite( view=view,
												 viewPath=viewLocations.viewPath,
												 viewHelperPath=viewLocations.viewHelperPath,
												 args=args,
												 renderer=this );
		// Are we caching it
		if( arguments.cache && variables.viewCaching ){
			cbox_cacheProvider.set( cbox_cacheKey, cbox_renderedView, arguments.cacheTimeout, arguments.cacheLastAccessTimeout );
		}
		return cbox_renderedView;
	}

	/************************************** LAYOUT METHODS *********************************************/

	/**
	* Render a layout or a layout + view combo
	* @layout The layout to render out
	* @module The module to explicitly render this layout from
	* @view The view to render within this layout
	* @args An optional set of arguments that will be available to this layouts/view rendering ONLY
	* @viewModule The module to explicitly render the view from
	* @prePostExempt If true, pre/post layout interceptors will not be fired. By default they do fire
	*/
	function renderLayout(
		layout,
		module="",
		view="",
		struct args=getRequestContext().getCurrentViewArgs(),
		viewModule="",
		boolean prePostExempt=false
	){
		var cbox_implicitLayout 	= implicitViewChecks();
		var cbox_currentLayout 		= cbox_implicitLayout;
		var cbox_locateUDF			= variables.locateLayout;
		var cbox_explicitModule 	= false;
		var cbox_layoutLocationKey 	= "";
		var cbox_layoutLocation		= "";
		var iData 					= arguments;
		var viewLocations			= "";
		var event                   = getRequestContext();
		var site                    = event.getSite()
		var layoutsRefMap           = "";

		// Are we doing a nested view/layout explicit combo or already in its rendering algorithm?
		if( len( trim( arguments.view ) )  ){
			event.setValue( name="__layoutExplicitView", value=arguments.view, private=true );
		}

		// If no passed layout, then get it from implicit values
		if( not structKeyExists( arguments, "layout" ) ){
			//Strip off the .cfm extension if it is set
			if( len( cbox_implicitLayout ) gt 4 AND right( cbox_implicitLayout, 4 ) eq '.cfm' ){
				cbox_implicitLayout = left( cbox_implicitLayout, len( cbox_implicitLayout ) - 4 );
			}
			arguments.layout = cbox_implicitLayout;
		}

		// module default value
		if( not len( arguments.module ) ){
			arguments.module = event.getCurrentModule();
		} else {
			cbox_explicitModule = true;
		}

		// Announce
		if( not arguments.prePostExempt ){
			announceInterception( "preLayoutRender", iData );
		}

		// Check explicit layout rendering
		if( structKeyExists( arguments, "layout" ) ){
			// Check if any length on incoming layout
			if( len ( arguments.layout ) ){
				// Cleanup leading / in views, just in case
				arguments.layout = reReplace( arguments.layout, "^(\\|/)", "" );
				cbox_currentLayout = arguments.layout & ".cfm";
			} else {
				cbox_currentLayout = "";
			}
		}

		// Choose location algorithm if in module mode
		if( len( arguments.module ) ){
			cbox_locateUDF = variables.locateModuleLayout;
		}

		// If Layout is blank, then just delegate to the view
		if( len( cbox_currentLayout ) eq 0 ){
			iData.renderedLayout = renderView();
		}
		else{
			// Layout location key
			cbox_layoutLocationKey = ( site.template ?: "" ) & cbox_currentLayout & arguments.module & cbox_explicitModule;
			layoutsRefMap          = controller.getSetting( "layoutsRefMap" );
			// Check cached paths first
			if( structkeyExists( layoutsRefMap, cbox_layoutLocationKey ) AND variables.isDiscoveryCaching ){
				cbox_layoutLocation = layoutsRefMap[ cbox_layoutLocationKey ];
			} else {
				cbox_layoutLocation = cbox_locateUDF( layout=cbox_currentLayout, module=arguments.module, explicitModule=cbox_explicitModule );
				layoutsRefMap[ cbox_layoutLocationKey ] = cbox_layoutLocation;
			}
			// Get the view locations
			var viewLocations = discoverViewPaths( view=reverse ( listRest( reverse( cbox_layoutLocation ), "." ) ),
												   module=arguments.module,
												   explicitModule=cbox_explicitModule );
			// RenderLayout
			iData.renderedLayout = renderViewComposite( view=cbox_currentLayout,
														viewPath=viewLocations.viewPath,
														viewHelperPath=viewLocations.viewHelperPath,
														args=args );
		}

		// Announce
		if( not arguments.prePostExempt ){
			announceInterception( "postLayoutRender", iData );
		}

		return iData.renderedLayout;
	}

	/**
	* Locate a layout in the conventions system
	* @layout The layout name
	*/
	function locateLayout( required layout ){
		var moduleName       = getRequestContext().getCurrentModule();
		var layoutDirs       = _getLayoutDirectories();
		var layoutPath       = "";
		var moduleLayoutPath = "";

		if ( len( moduleName ) && StructKeyExists( variables.modulesConfig, moduleName ) ){
			moduleLayoutPath = "#variables.modulesConfig[moduleName].mapping#/#layoutsConvention#/#arguments.layout#";
			if ( FileExists( ExpandPath( moduleLayoutPath ) ) ) {
				return moduleLayoutPath;
			}
		}

		for( var i=layoutDirs.len(); i>0; i-- ){
			layoutPath = layoutDirs[i] & "/" & arguments.layout;
			if ( FileExists( layoutPath ) ) {
				return layoutPath;
			}
		}

		return "/#appMapping#/#layoutsConvention#/#arguments.layout#";
	}

	/**
	* Locate a layout in the conventions system
	* @layout The layout name
	* @module The name of the module we are searching for
	* @explicitModule Are we locating explicitly or implicitly for a module layout
	*/
	function locateModuleLayout(
		  required string  layout
		,          string  module=""
		,          boolean explicitModule=false
	){
		var parentModuleLayoutPath = "";
		var parentCommonLayoutPath = "";
		var moduleLayoutPath       = "";
		var moduleName             = "";

		// Explicit Module layout lookup?
		if ( len( arguments.module ) and arguments.explicitModule ){
			return "#variables.modulesConfig[ arguments.module ].mapping#/#variables.modulesConfig[ arguments.module ].conventions.layoutsLocation#/#arguments.layout#";
		}

		// Declare Locations
		moduleName              = getRequestContext().getCurrentModule();
		parentModuleLayoutPath 	= "/#variables.appMapping#/#variables.layoutsConvention#/modules/#moduleName#/#arguments.layout#";
		parentCommonLayoutPath 	= "/#variables.appMapping#/#variables.layoutsConvention#/modules/#arguments.layout#";

		if ( StructKeyExists( variables.modulesConfig, moduleName ) ) {
			moduleLayoutPath = "#variables.modulesConfig[ moduleName ].mapping#/#variables.modulesConfig[ moduleName ].conventions.layoutsLocation#/#arguments.layout#";

			// Check parent view order setup
			if ( variables.modulesConfig[ moduleName ].layoutParentLookup ){
				// We check if layout is overriden in parent first.
				if ( fileExists( expandPath( parentModuleLayoutPath ) ) ) {
					return parentModuleLayoutPath;
				}
				// Check if parent has a common layout override
				if ( fileExists( expandPath( parentCommonLayoutPath ) ) ) {
					return parentCommonLayoutPath;
				}
				// Check module
				if ( fileExists( expandPath( moduleLayoutPath ) ) ) {
					return moduleLayoutPath;
				}
				// Return normal layout lookup
				return locateLayout( arguments.layout );
			}

			// If we reach here then we are doing module lookup first then if not parent.
			if ( fileExists( expandPath( moduleLayoutPath ) ) ) {
				return moduleLayoutPath;
			}
			// We check if layout is overriden in parent first.
			if ( fileExists( expandPath( parentModuleLayoutPath ) ) ) {
				return parentModuleLayoutPath;
			}
			// Check if parent has a common layout override
			if ( fileExists( expandPath( parentCommonLayoutPath ) ) ) {
				return parentCommonLayoutPath;
			}
		}

		// Return normal layout lookup
		return locateLayout( arguments.layout );
	}

	/**
	* Locate a view in the conventions or external paths
	* @view The view to locate
	*/
	function locateView( required view ){
		var viewMappings = _getViewMappings();
		var viewMapping  = ReReplace( arguments.view, "^/", "" );

		return viewMappings[ viewMapping ] ?: "/#appMapping#/#viewsConvention#/#arguments.view#";
	}

	/**
	* Locate a view in the conventions system
	* @view The view name
	* @module The name of the module we are searching for
	* @explicitModule Are we locating explicitly or implicitly for a module layout
	*/
	function locateModuleView(
		  required string  view
		,          string  module=""
		,          boolean explicitModule=false
	){
		var parentModuleViewPath = "";
		var parentCommonViewPath = "";
		var moduleViewPath       = "";
		var moduleName           = "";

		// Explicit Module view lookup?
		if ( len( arguments.module ) and arguments.explicitModule ) {
			return "#variables.modulesConfig[ arguments.module ].mapping#/#variables.modulesConfig[ arguments.module ].conventions.viewsLocation#/#arguments.view#";
		}

		// Declare Locations
		moduleName           = arguments.module;
		parentModuleViewPath = "/#variables.appMapping#/#variables.viewsConvention#/modules/#moduleName#/#arguments.view#";
		parentCommonViewPath = "/#variables.appMapping#/#variables.viewsConvention#/modules/#arguments.view#";

		if ( StructKeyExists( variables.modulesConfig, moduleName ) ) {
			moduleViewPath = "#variables.modulesConfig[ moduleName ].mapping#/#variables.modulesConfig[ moduleName ].conventions.viewsLocation#/#arguments.view#";

			// Check parent view order setup
			if ( variables.modulesConfig[ moduleName ].viewParentLookup ) {
				// We check if view is overriden in parent first.
				if ( fileExists( expandPath( parentModuleViewPath & ".cfm" ) ) ) {
					return parentModuleViewPath;
				}
				// Check if parent has a common view override
				if ( fileExists( expandPath( parentCommonViewPath & ".cfm" ) ) ) {
					return parentCommonViewPath;
				}
				// Check module for view
				if ( fileExists( expandPath( moduleViewPath & ".cfm" ) ) ) {
					return moduleViewPath;
				}
				// Return normal view lookup
				return locateView( arguments.view );
			}

			// If we reach here then we are doing module lookup first then if not parent.
			if ( fileExists( expandPath( moduleViewPath & ".cfm" ) ) ) {
				return moduleViewPath;
			}
			// We check if view is overriden in parent first.
			if ( fileExists( expandPath( parentModuleViewPath & ".cfm" ) ) ) {
				return parentModuleViewPath;
			}
			// Check if parent has a common view override
			if ( fileExists( expandPath( parentCommonViewPath & ".cfm" ) ) ) {
				return parentCommonViewPath;
			}
		}

		// Return normal view lookup
		return locateView( arguments.view );
	}

	/************************************** PRIVATE *********************************************/

	/**
	* Discover view+helper path locations
	* @view The view to discover
	* @module The module address
	* @explicitModule Is the module explicit or discoverable.
	*/
	private function discoverViewPaths( required view, module, boolean explicitModule=false ){
		var site            = getRequestContext().getSite();
		var locationKey 	= ( site.template ?: "" ) & arguments.view & arguments.module & arguments.explicitModule;
		var locationUDF 	= variables.locateView;
		var dPath			= "";
		var refMap			= "";
		var viewsRefMap     = controller.getSetting("viewsRefMap");

		// Check cached paths first --->
		if( structkeyExists( viewsRefMap ,locationKey ) AND variables.isDiscoveryCaching ){
			return viewsRefMap[ locationKey ];
		}

		if( left( arguments.view, 1 ) EQ "/" ){

			refMap = {
				viewPath = arguments.view,
				viewHelperPath = ""
			};

		} else { // view discovery based on relative path

			// module change mode
			if( len( arguments.module ) ){ locationUDF = variables.locateModuleView; }

			// Locate the view to render according to discovery algorithm and create cache map
			refMap = {
				viewPath = locationUDF( arguments.view, arguments.module, arguments.explicitModule ),
				viewHelperPath = ""
			};

		}

		// Check for view helper convention
		dPath = getDirectoryFromPath( refMap.viewPath );
		if( fileExists(expandPath( refMap.viewPath & "Helper.cfm")) ){
			refMap.viewHelperPath = refMap.viewPath & "Helper.cfm";
		}
		// Check for directory helper convention
		else if( fileExists( expandPath( dPath & listLast(dPath,"/") & "Helper.cfm" ) ) ){
			refMap.viewHelperPath = dPath & listLast(dPath,"/") & "Helper.cfm";
		}

		// Lock and create view entry
		if( NOT structkeyExists( viewsRefMap, locationKey ) ) {
			viewsRefMap[ locationKey ] = refMap;
		}

		return refMap;
	}

	/**
	* Checks if implicit views are turned on and if so, calculate view according to event.
	*/
	private function implicitViewChecks(){
		var event  = getRequestContext();
		var layout = event.getCurrentLayout();
		var cEvent = event.getCurrentEvent();

		// Is implicit views enabled?
		if( not controller.getSetting( name="ImplicitViews" ) ){ return layout; }

		// Cleanup for modules
		cEvent = reReplaceNoCase( cEvent, "^([^:.]*):", "" );

		//Check if no view set?
		if( NOT len( event.getCurrentView() ) ){

			// Implicit views
			if( controller.getSetting( name="caseSensitiveImplicitViews", defaultValue=false ) ){
				event.setView( replace( cEvent, ".", "/", "all" ) );
			} else {
				event.setView( lcase( replace( cEvent, ".", "/", "all" ) ) );
			}

			// reset layout according to newly set views;
			layout = event.getCurrentLayout();
		}

		return layout;
	}

	private array function _getViewDirectories() {
		var subDir      = viewsConvention;
		var directories = [ "/preside/system/#subDir#" ];
		var extensions  = getController().getSetting( name="activeExtensions", defaultValue=[] );
		var site        = getRequestContext().getSite();

		for( var i=1; i<=extensions.len(); i++ ){
			directories.append( extensions[i].directory & "/" & subDir );
		}

		directories.append( "#_getAppMapping()#/#subDir#" );

		if ( Len( Trim( site.template ?: "" ) ) ) {
			for( var i=1; i<=extensions.len(); i++ ){
				directories.append( extensions[i].directory & "/site-templates/#site.template#/" & subDir );
			}

			directories.append( "#_getAppMapping()#/site-templates/#site.template#/#subDir#" );
		}

		return directories;
	}

	private array function _getLayoutDirectories() {
		var subDir      = layoutsConvention;
		var directories = [ "/preside/system/#subDir#" ];
		var extensions  = getController().getSetting( name="activeExtensions", defaultValue=[] );
		var site        = getRequestContext().getSite();

		for( var i=1; i<=extensions.len(); i++ ){
			ArrayAppend( directories, extensions[i].directory & "/" & subDir );
		}

		ArrayAppend( directories, "#_getAppMapping()#/#subDir#" );
		if ( Len( Trim( site.template ?: "" ) ) ) {
			for( var i=1; i<=extensions.len(); i++ ){
				directories.append( extensions[i].directory & "/site-templates/#site.template#/" & subDir );
			}

			directories.append( "#_getAppMapping()#/site-templates/#site.template#/#subDir#" );
		}

		return directories;
	}

	private struct function _getViewMappings() {
		var site          = getRequestContext().getSite();
		var cacheKey      = "viewsFullMappings" & ( site.template ?: "" );
		var ignoreFileSvc = getModel( "ignoreFileService" );

		lock name="#lockName#" type="readonly" timeout="15" throwontimeout="true" {
			if ( controller.settingExists( cacheKey ) ) {
				return controller.getSetting( cacheKey )
			}
		}

		var viewDirs = _getViewDirectories();
		var mappings = {};

		for( var viewDir in viewDirs ){
			var fullDirPath = Replace( ExpandPath( viewDir ), "\", "/", "all" )
			var viewFiles   = DirectoryList( fullDirPath, true, "path", "*.cfm" );

			for ( var filePath in viewFiles ) {
				if ( ignoreFileSvc.isIgnored( "view", filePath ) || ( ignoreFileSvc.getWrite() && _isViewFeatureDisabled( filePath ) ) ) {
					ignoreFileSvc.ignore( "view", filePath );
					continue;
				}

				var mapping = ReReplaceNoCase( filePath, "\.cfm$", "" );
					mapping = Replace( mapping, "\", "/", "all" );
					mapping = Replace( mapping, fullDirPath, "" );
					mapping = ReReplace( mapping, "^/", "" );

				var mappings[ mapping ] = viewDir & "/" & mapping;
			}
		}

		lock name="#lockName#" type="readonly" timeout="15" throwontimeout="true" {
			controller.setSetting( cacheKey, mappings )
		}

		return mappings;
	}

	private string function _getAppMapping() {
		return "/" & controller.getSetting( name="appMapping", defaultValue="/app" ).reReplace( "^/", "" );
	}

	private function _isViewFeatureDisabled( filePath ) {
		var cfmFile           = FileOpen( arguments.filePath, "read" );
		var isFeatureDisabled = false;
		var featureRegex      = "^<!---@feature (.*)--->$";

		try {
			while( !FileIsEoF( cfmFile ) ) {
				var featureLine = FileReadLine( cfmFile );
				if ( ReFindNoCase( featureRegex, featureLine ) ) {
					var feature = ReReplaceNoCase( featureLine, featureRegex, "\1" );
					isFeatureDisabled = !isFeatureEnabled( Trim( feature ) );
				}
				break;
			}
		} catch( any e ) {
			rethrow;
			isFeatureDisabled = false;
		} finally {
			FileClose( cfmFile );
		}

		return isFeatureDisabled;
	}

	public function getRendererVariables() {
		if ( areLuceeGlobalUdfsAvailable() ) {
			return {
				  appMapping              = variables.appMapping
				, cacheBox                = variables.cacheBox
				, controller              = variables.controller
				, flash                   = variables.flash
				, isDiscoveryCaching      = variables.isDiscoveryCaching
				, isViewsHelperIncluded   = variables.isViewsHelperIncluded
				, layoutsConvention       = variables.layoutsConvention
				, layoutsExternalLocation = variables.layoutsExternalLocation
				, modulesConfig           = variables.modulesConfig
				, renderedHelpers         = variables.renderedHelpers
				, threadUtil              = variables.threadUtil
				, viewCaching             = variables.viewCaching
				, viewsConvention         = variables.viewsConvention
				, viewsExternalLocation   = variables.viewsExternalLocation
				, viewsHelper             = variables.viewsHelper
				, wireBox                 = variables.wireBox
			}
		}

		return variables;
	}

	function initLuceeGlobalUdfAvailabilityCheck() {
		try {
			setLuceeGlobalUdfsAvailable( testOnMissingFunctionAvailability() );
		} catch( any e ) {
			setLuceeGlobalUdfsAvailable( false );
		}

		return variables._luceeGlobalUdfsAvailable;
	}

	function setLuceeGlobalUdfsAvailable( available ) {
		variables._luceeGlobalUdfsAvailable = arguments.available;
	}

	function areLuceeGlobalUdfsAvailable( available ) {
		return variables._luceeGlobalUdfsAvailable ?: initLuceeGlobalUdfAvailabilityCheck();
	}
}
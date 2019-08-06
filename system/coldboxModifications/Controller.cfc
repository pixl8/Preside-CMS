component extends="coldbox.system.web.Controller" {

	public any function init() {
		super.init( argumentCollection = arguments );

		services.handlerService     = new preside.system.coldboxModifications.services.HandlerService( this );
		services.moduleService      = new preside.system.coldboxModifications.services.ModuleService( this );
		services.interceptorService = new preside.system.coldboxModifications.services.InterceptorService( this );
		services.requestService     = new preside.system.coldboxModifications.services.RequestService( this );
		services.routingService     = new preside.system.coldboxModifications.services.RoutingService( this );
		variables.wireBox           = CreateObject( "preside.system.coldboxModifications.ioc.Injector" );
		variables.cacheBox          = CreateObject( "preside.system.coldboxModifications.cachebox.CacheFactory" );
	}

	function getRenderer(){
		try {
			return variables._renderer;
		} catch( any e ) {
			variables._renderer = variables.wireBox.getInstance( "presideRenderer" );
		}
		return variables._renderer;
	}

	public array function listHandlers( string thatStartWith="" ) {
		return getHandlerService().listHandlers( argumentCollection=arguments );
	}

	public boolean function handlerExists( required string event ) {
		variables._handlerExistsCache = variables._handlerExistsCache ?: {};
		if ( StructKeyExists( variables._handlerExistsCache, arguments.event ) ) {
			return variables._handlerExistsCache[ arguments.event ];
		}

		var handlerSvc = "";
		var handler    = "";
		var action     = ListLast( arguments.event, "." );
		var exists     = false;

		try {
			handlerSvc = getHandlerService();
			handler = handlerSvc.getHandlerBean( event=arguments.event );

			if ( handler.getViewDispatch() ) {
				exists = false;
			} else {
				var fullEvent = handler.getFullEvent();
				if ( fullEvent != arguments.event && fullEvent != ( arguments.event & ".index" ) ) {
					exists = false;
				} else {
					handler = handlerSvc.getHandler( handler, getRequestContext() );
					handler = GetMetaData( handler );

					if ( Right( handler.fullname ?: "", Len( arguments.event ) ) eq arguments.event ) {
						action = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
					}

					exists = _actionExistsInHandler( handler, action );
				}
			}


		} catch( "HandlerService.EventHandlerNotRegisteredException" e ) {
			exists = false;
		}

		variables._handlerExistsCache[ arguments.event ] = exists;
		return exists;
	}

	public boolean function viewExists( required string view ) {
		variables._viewExistsCache = variables._viewExistsCache ?: {};
		if ( StructKeyExists( variables._viewExistsCache, arguments.view ) ) {
			return variables._viewExistsCache[ arguments.view ];
		}

		var targetView = getRenderer().locateView( ListChangeDelims( arguments.view, "/", "." ) );
		var exists     = Len( Trim( targetView ) ) and FileExists( ExpandPath( targetView & ".cfm" ) );

		variables._viewExistsCache[ arguments.view ] = exists;

		return exists;
	}

	public boolean function viewletExists( required string event ) {
		return handlerExists( arguments.event ) or viewExists( arguments.event );
	}

	public any function renderViewlet(
		  required string  event
		,          struct  args                   = {}
		,          boolean private                = true
		,          boolean prepostExempt          = true
		,          boolean delayed                = _getDelayedViewletRendererService().isViewletDelayedByDefault( arguments.event )
		,          boolean cache                  = false
		,          string  cacheTimeout           = ""
		,          string  cacheLastAccessTimeout = ""
		,          string  cacheSuffix            = ""
		,          string  cacheProvider          = "template"
	) {
		if ( arguments.delayed && getRequestContext().cachePage() ) {
			return _getDelayedViewletRendererService().renderDelayedViewletTag(
				  event         = arguments.event
				, args          = arguments.args
				, private       = arguments.private
				, prepostExempt = arguments.prepostExempt
			);
		}

		var useCache = arguments.cache && !_isAdminLoggedIn();
		if ( useCache ) {
			var cache    = getCachebox().getCache( arguments.cacheProvider );
			var cacheKey = "renderViewletCache:" & arguments.event & arguments.cacheSuffix;
			var rendered = cache.get( cacheKey );

			if ( IsNull( rendered ) ) {
				rendered = renderViewlet( argumentCollection=arguments, cache=false );
				cache.set(
					  objectKey         = cacheKey
					, object            = rendered
					, timeout           = arguments.cacheTimeout
					, lastAccessTimeout = arguments.cacheLastAccessTimeout
				);
			}

			return rendered;
		}

		var result        = "";
		var view          = "";
		var handler       = arguments.event;
		var defaultAction = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
		var hndlrExists   = handlerExists( handler );

		if ( !hndlrExists ) {
			handler = ListAppend( handler, defaultAction, "." );
			hndlrExists = handlerExists( handler );
		}

		if ( hndlrExists ) {
			return runEvent(
				  event          = handler
				, prepostExempt  = arguments.prepostExempt
				, private        = arguments.private
				, eventArguments = { args = arguments.args }
			);
		}

		view = ListChangeDelims( arguments.event, "/", "." );
		if ( !viewExists( view ) ) {
			view = ListAppend( view, defaultAction, "/" );
		}

		return getRenderer().renderView(
			  view = view
			, args = arguments.args
		);
	}

	public any function getRequestContext() {
		return getRequestService().getContext();
	}

	public any function getSetting( required string name, boolean fwSetting=false, any defaultValue ) {
		var target = arguments.fwSetting ? variables.coldboxSettings : variables.configSettings;

		if ( StructKeyExists( target, arguments.name ) ) {
			return target[ arguments.name ];
		}

		if ( IsDefined( "target.#arguments.name#" ) ) {
			return Evaluate( "target.#arguments.name#" );
		}

		if ( StructKeyExists( arguments, "defaultValue" ) ) {
			return arguments.defaultValue;
		}

		throw( message="The setting #arguments.name# does not exist.",
			   detail="FWSetting flag is #arguments.FWSetting#",
			   type="Controller.SettingNotFoundException");
	}

// private helpers
	private boolean function _actionExistsInHandler( required struct handlerMeta, required string action ) {
		if ( StructKeyExists( arguments.handlerMeta, "extends" ) and _actionExistsInHandler( arguments.handlerMeta.extends, arguments.action ) ) {
			return true;
		}

		var functions = arguments.handlerMeta.functions ?: [];

		for( var func in functions ) {
			if ( ( func.name ?: "" ) eq arguments.action ) {
				return true;
			}
		}

		return false;
	}

	private any function _getDelayedViewletRendererService() {
		if ( !StructKeyExists( variables, "_delayedViewletRendererService" ) ) {
			variables._delayedViewletRendererService = wireBox.getInstance( "delayedViewletRendererService" );
		}

		return variables._delayedViewletRendererService;
	}

	private boolean function _isAdminLoggedIn() {
		return wireBox.getInstance( "loginService" ).isLoggedIn();
	}

	private function invoker(
		  required any     target
		, required string  method
		,          struct  argCollection = {}
		,          boolean private       = false
	){
		if ( arguments.private ) {
			return arguments.target._privateInvoker( method=arguments.method, argCollection=arguments.argCollection );
		} else {
			return arguments.target[ arguments.method ]( argumentCollection=arguments.argCollection );
		}
	}
}
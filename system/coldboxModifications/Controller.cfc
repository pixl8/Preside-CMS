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
		var site     = getRequestContext().getSite();
		var cacheKey = arguments.event & ( site.template ?: "" );
		variables._handlerExistsCache = variables._handlerExistsCache ?: {};
		if ( StructKeyExists( variables._handlerExistsCache, cacheKey ) ) {
			return variables._handlerExistsCache[ cacheKey ];
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


		} catch( HandlerService.EventHandlerNotRegisteredException e ) {
			exists = false;
		} catch( HandlerService.InvalidEventHandlerException e ) {
			exists = false;
		}


		variables._handlerExistsCache[ cacheKey ] = exists;
		return exists;
	}

	public boolean function viewExists( required string view ) {
		var site     = getRequestContext().getSite();
		var cacheKey = arguments.view & ( site.template ?: "" );

		variables._viewExistsCache = variables._viewExistsCache ?: {};
		if ( StructKeyExists( variables._viewExistsCache, cacheKey ) ) {
			return variables._viewExistsCache[ cacheKey ];
		}

		var targetView = getRenderer().locateView( ListChangeDelims( arguments.view, "/", "." ) );
		var exists     = Len( Trim( targetView ) ) and FileExists( ExpandPath( targetView & ".cfm" ) );

		variables._viewExistsCache[ cacheKey ] = exists;

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
		,          boolean throwOnMissing         = true
	) {
		if ( arguments.delayed && _getDelayedViewletRendererService().isDelayableContext() ) {
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

		var result          = "";
		var view            = ListChangeDelims( arguments.event, "/", "." );
		var deferredViewlet = "";
		var viewletArgs     = arguments.args;
		var handler         = arguments.event;
		var defaultAction   = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
		var hndlrExists     = handlerExists( handler );

		if ( !hndlrExists ) {
			handler = ListAppend( handler, defaultAction, "." );
			hndlrExists = handlerExists( handler );
		}

		if ( hndlrExists ) {
			var requestContext = getRequestContext();
			requestContext.pushViewletContext( view );

			var result = runEvent(
				  event          = handler
				, prepostExempt  = arguments.prepostExempt
				, private        = arguments.private
				, eventArguments = { args = viewletArgs }
			);

			if ( IsNull( local.result ) ) {
				view            = requestContext.getViewletView();
				deferredViewlet = requestContext.getDeferredViewlet();
				viewletArgs     = requestContext.getViewletArgs( viewletArgs );
			}
			requestContext.popViewletContext();

			if ( !IsNull( local.result ) ) {
				return result;
			}

			if ( Len( Trim( deferredViewlet ) ) ) {
				return renderViewlet( event=deferredViewlet, args=viewletArgs );
			}
			if ( !Len( Trim( view ) ) ) {
				return "";
			}
		}


		var vwExists = viewExists( view )
		if ( !vwExists ) {
			view = ListAppend( view, defaultAction, "/" );
			vwExists = viewExists( view );
		}

		if ( !vwExists && ( !arguments.throwOnMissing || hndlrExists ) ) {
			return "";
		}

		return getRenderer().renderView(
			  view = view
			, args = viewletArgs
		);
	}

	public void function outputViewlet(
		  required string  event
		,          struct  args = {}
		,          boolean delayed = _getDelayedViewletRendererService().isViewletDelayedByDefault( arguments.event )
		,          boolean throwOnMissing = false
		,          boolean cache = false
	) output=true {
		if ( arguments.cache || ( arguments.delayed && _getDelayedViewletRendererService().isDelayableContext() ) ) {
			echo( renderViewlet( argumentCollection=arguments ) );
			return;
		}
		silent {
			var view            = "";
			var handler         = arguments.event;
			var defaultAction   = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
			var hndlrExists     = handlerExists( handler );
			var requestContext  = getRequestContext();
			var view            = ListChangeDelims( arguments.event, "/", "." );
			var deferredViewlet = "";
			var viewletArgs     = {};

			if ( !hndlrExists ) {
				handler = ListAppend( handler, defaultAction, "." );
				hndlrExists = handlerExists( handler );
			}

			if ( hndlrExists ) {
				requestContext.pushViewletContext( view );
				var handlerResult = runEvent(
					  event          = handler
					, private        = true
					, prePostExempt  = true
					, eventArguments = { args=arguments.args, bufferedViewlet=true }
				);
				if ( !IsSimpleValue( local.handlerResult ?: "" ) ) {
					handlerResult = NullValue();
				} else {
					view            = requestContext.getViewletView();
					deferredViewlet = requestContext.getDeferredViewlet();
					viewletArgs     = requestContext.getViewletArgs( args );
				}
				requestContext.popViewletContext();
			}

			if ( IsNull( local.handlerResult ) && Len( view ) && !viewExists( view ) ) {
				view = ListAppend( view, defaultAction, "/" );
			}
		}

		if ( !IsNull( handlerResult ) ) {
			echo( handlerResult );
		} else if ( Len( Trim( deferredViewlet ) ) ) {
			outputViewlet( event=deferredViewlet, args=viewletArgs );
		} else if ( Len( view ) ) {
			if ( arguments.throwOnMissing || viewExists( view ) ) {
				getRenderer().outputView( view=view, args=viewletArgs );
			}
		}
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
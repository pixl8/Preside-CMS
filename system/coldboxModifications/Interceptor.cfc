/**
 * Preside Interceptor shim for ColdBox 6.0+/7.0+
 *
 * 1. ColdBox 6.0+ moved loadApplicationHelpers() from the constructor to a
 *    lazy cbLoadInterceptorHelpers event. This shim eagerly loads helpers
 *    via cbLoadInterceptorHelpers so they're available for startup interceptions.
 *
 * 2. ColdBox 6.0 removed getModel() from FrameworkSupertype. This shim
 *    restores it as a passthrough to getInstance().
 */
component extends="coldbox.system.Interceptor" {

	/**
	 * Override cbLoadInterceptorHelpers to ensure helpers are loaded
	 * immediately when called, restoring CB 5.4 eager-loading behaviour.
	 */
	function cbLoadInterceptorHelpers( event, interceptData ){
		loadApplicationHelpers( force: true );
	}

	/**
	 * Compatibility shim: getModel() was removed in ColdBox 6.0
	 */
	function getModel( name, dsl, initArguments={} ){
		return getInstance( argumentCollection=arguments );
	}

	/**
	 * CB 7.0: renderView() deprecated and no longer returns a value.
	 */
	function renderView(){
		return getRenderer().renderView( argumentCollection=arguments );
	}

	function renderLayout(){
		return getRenderer().renderLayout( argumentCollection=arguments );
	}

	function renderExternalView(){
		return getRenderer().renderExternalView( argumentCollection=arguments );
	}

}

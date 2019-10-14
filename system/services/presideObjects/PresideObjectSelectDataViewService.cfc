/**
 * Service to provide API methods into the Preside
 * selectDataView system
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS

	/**
	 * Gets the arguments to be passed to selectData()
	 * for the given view by running the view's convention
	 * based handler and returning the result
	 *
	 * @view.hint The name of the view whose arguments you wish to get
	 */
	public struct function getViewArgs( required string view ) {
		var conventionBasedHandler = "selectDataViews.#arguments.view#";
		var coldbox = $getColdbox();

		if ( coldbox.handlerExists( conventionBasedHandler ) ) {
			var result = coldbox.runEvent(
				  event         = conventionBasedHandler
				, private       = true
				, prePostExempt = true
			);

			if ( !IsStruct( local.result ?: "" ) ) {
				throw( type="presideobjectselectdataviews.bad.view.result", message="The select data view, [#arguments.view#], returned an invalid result (see detail). Handler is expected to return a struct of arguments to be passed to selectData().", detail=SerializeJson( local.result ?: "[null]" ) );
			}

			return result;
		}

		throw( type="presideobjectselectdataviews.missing.view", message="The select data view, [#arguments.view#], does not exist. Expecting a coldbox handler event at [#conventionBasedHandler#]." );

	}

	/**
	 * Gets SQL and params for the given view. This struct can then be used when forming subquery
	 * joins, etc. (or whatever you wish to do with it)
	 *
	 * @view.hint The name of the view whose SQL and params you wish to get
	 */
	public struct function getSqlAndParams( required string view ) {
		var args = getViewArgs( arguments.view );

		args.getSqlAndParamsOnly = true;

		for( var arg in arguments ) {
			if ( arg != "view" ) {
				args[ arg ] = arguments[ arg ];
			}
		}

		var sqlAndParams = $getPresideObjectService().selectData( argumentCollection=args );

		return makeUniqueParams( sqlAndParams );
	}

	public struct function makeUniqueParams( required struct sqlAndParams ) {
		var uid = _uuid();
		for( var param in sqlAndParams.params ) {
			sqlAndParams.sql = ReplaceNoCase( sqlAndParams.sql, ":#param.name#", ":#param.name##uid#", "all" );
			param.name &= uid;
		}

		return sqlAndParams;
	}

	public string function _uuid() {
		return Replace( CreateUUId(), "-", "", "all" );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS

}
/**
 * The tenancy service provides the mostly invisible logic
 * for auto filtering data based on custom defined tenants.
 *
 * @presideService true
 * @singleton      true
 */
component displayName="Tenancy service" {

// CONSTRUCTOR
	/**
	 * @tenancyConfig.inject coldbox:setting:tenancy
	 *
	 */
	public any function init( required struct tenancyConfig ) {
		_setTenancyConfig( arguments.tenancyConfig );
		return this;
	}

// PUBLIC API
	public void function injectObjectTenancyProperties( required struct objectMeta ) {
		var tenants = ListToArray( objectMeta.tenants ?: "" );

		if ( tenants.len() ) {
			objectMeta.tenancyConfig = {};
			for( var tenant in tenants ) {
				objectMeta.tenancyConfig[ tenant ] = { fk=findObjectTenancyForeignKey( tenant, objectMeta ) };
			}
		}
	}


	public string function findObjectTenancyForeignKey( required string tenant, required struct objectMeta ) {
		var props = objectMeta.properties ?: {};
		for( var propName in props ) {
			var prop = props[ propName ];
			var fkForTenant = ListToArray( prop.fkForTenant ?: "" );

			if ( fkForTenant.findNoCase( arguments.tenant ) ) {
				return propName;
			}
		}

		return getDefaultFkForTenant( arguments.tenant );
	}

	public string function getDefaultFkForTenant( required string tenant ) {
		var config = _getTenancyConfig();

		return config[ tenant ].defaultFk ?: "";
	}

// GETTERS AND SETTERS
	private struct function _getTenancyConfig() {
		return _tenancyConfig;
	}
	private void function _setTenancyConfig( required struct tenancyConfig ) {
		_tenancyConfig = arguments.tenancyConfig;
	}

}
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
		var tenant = ( objectMeta.tenant ?: "" ).trim();

		if ( tenant.len() ) {
			var config = _getTenancyConfig();

			if ( !config.keyExists( tenant ) ) {
				throw( type="preside.tenancy.invalid.tenant", message="The tenant, [#tenant#], could not be found in the configured tenants." );
			}

			var fk            = findObjectTenancyForeignKey( tenant, objectMeta );
			var tenancyObject = config[ tenant ].object;
			var fkProperty    = { name=fk, relationship="many-to-one", relatedTo=tenancyObject, required=false, indexes="_#fk#", ondelete="cascade", onupdate="cascade" };

			objectMeta.propertyNames    = objectMeta.propertyNames ?: [];
			objectMeta.tenancyConfig    = { fk=fk };
			objectMeta.properties       = objectMeta.properties ?: {};
			objectMeta.properties[ fk ] = objectMeta.properties[ fk ] ?: {};

			StructAppend( objectMeta.properties[ fk ], fkProperty, false );

			if ( !objectMeta.propertyNames.findNoCase( fk ) ) {
				objectMeta.propertyNames.append( fk );
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
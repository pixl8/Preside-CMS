/**
 * Service that allows creation/update of datasources
 *
 * @singleton
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
   /**
	* Updates a specific datasource defined for current context
	*
	* @name                              name of the datasouce to be updated
	* @type                              type of the datasource to be updated
	* @host                              Host name where the database server is located
	* @database                          Name of the database to connect
	* @port                              The port to connect the database
	* @timezone                          timezone of the database server
	* @username                          The username for the database
	* @password                          The password for the database
	* @ConnectionLimit                   Restricts the maximum number of simultaneous connections at one time
	* @ConnectionTimeout                 To define a time in minutes for how long a connection is kept alive before it will be closed
	* @metaCacheTimeout                  To define how long Stored Procedures Meta Data are stored in cache
	* @blob                              Enable binary large object retrieval (BLOB)
	* @clob                              Enable long text retrieval (CLOB)
	* @validate                          Validate the connection before use (only works with JDBC 4.0 Drivers)
	* @allowedSelect                     allow database permission for select
	* @allowedInsert                     allow database permission for insert
	* @allowedUpdate                     allow database permission for update
	* @allowedDelete                     allow database permission for delete
	* @allowedAlter                      allow database permission for alter
	* @allowedDrop                       allow database permission for drop
	* @allowedRevoke                     allow database permission for revoke
	* @allowedCreate                     allow database permission for create
	* @allowedGrant                      allow database permission for grant
	* @storage                           Allow to use this datasource as client/session storage.
	* @customUseUnicode                  Should the driver use Unicode character encodings when handling strings?
	* @customCharacterEncoding           Should only be used when the driver can't determine the character set mapping, or you are trying to 'force' the driver to use a character set that MySQL either doesn't natively support (such as UTF-8)If it is set to true, what character encoding should the driver use when dealing with strings?
	* @customUseOldAliasMetadataBehavior Should the driver use the legacy behavior for "AS" clauses on columns and tables, and only return aliases (if any) rather than the original column/table name? In 5.0.x, the default value was true.
	* @customAllowMultiQueries           Allow the use of ";" to delimit multiple queries during one statement
	* @customZeroDateTimeBehavior        What should happen when the driver encounters DATETIME values that are composed entirely of zeroes (used by MySQL to represent invalid dates)? Valid values are "exception", "round" and "convertToNull"
	* @customAutoReconnect               Should the driver try to re-establish stale and/or dead connections?
	* @customJdbcCompliantTruncation     If set to false then values for table fields are automatically truncated so that they fit into the field.
	* @customTinyInt1isBit               if set to "true" (default) tinyInt(1) is converted to a bit value otherwise as integer.
	* @customUseLegacyDatetimeCode       Use code for DATE/TIME/DATETIME/TIMESTAMP handling in result sets and statements
	* @verify                            whether connection needs to be verified
	* @luceeAdminPassword                Web admin password for lucee
	*/
	public void function updateDatasource(
		  required string  name
		, required string  type
		, required string  host
		, required string  database
		, required numeric port
		, required string  username
		, required string  password
		,          string  timezone                          = ""
		,          numeric ConnectionLimit                   = -1
		,          numeric ConnectionTimeout                 = 1
		,          numeric metaCacheTimeout                  = 60000
		,          boolean blob                              = false
		,          boolean clob                              = false
		,          boolean validate                          = false
		,          boolean storage                           = false
		,          boolean verify                            = false
		,          boolean allowedSelect                     = false
		,          boolean allowedInsert                     = false
		,          boolean allowedUpdate                     = false
		,          boolean allowedDelete                     = false
		,          boolean allowedAlter                      = false
		,          boolean allowedDrop                       = false
		,          boolean allowedRevoke                     = false
		,          boolean allowedCreate                     = false
		,          boolean allowedGrant                      = false
		,          boolean customUseUnicode                  = false
		,          string  customCharacterEncoding           = false
		,          boolean customUseOldAliasMetadataBehavior = false
		,          boolean customAllowMultiQueries           = false
		,          string  customZeroDateTimeBehavior        = false
		,          boolean customAutoReconnect               = false
		,          boolean customJdbcCompliantTruncation     = false
		,          boolean customTinyInt1isBit               = false
		,          boolean customUseLegacyDatetimeCode       = false
		,          string  luceeAdminPassword                = ""
	){
		var driver = _getDriverForType( arguments.type );
		var custom = {};

		for( var key in arguments ) {
			if ( key.reFindNoCase( "^custom" ) ) {
				custom[ key.reReplace( "^custom", "" ) ] = arguments[ key ];
			}
		}

		admin action                       = "updateDatasource"
		      type                         = "web"
		      classname                    = driver.getClass()
		      dsn                          = driver.getDsn()
		      dbdriver                     = arguments.type
		      name                         = arguments.name
		      newName                      = arguments.name
		      host                         = arguments.host
		      database                     = arguments.database
		      port                         = arguments.port
		      dbusername                   = arguments.username
		      dbpassword                   = arguments.password
		      customParameterSyntax        = isNull( driver.customParameterSyntax        ) ? nullValue() : driver.customParameterSyntax()
		      literalTimestampWithTSOffset = isNull( driver.literalTimestampWithTSOffset ) ? false       : driver.literalTimestampWithTSOffset()
		      alwaysSetTimeout             = isNull( driver.alwaysSetTimeout             ) ? false       : driver.alwaysSetTimeout()
		      timezone                     = arguments.timezone
		      connectionLimit              = arguments.connectionLimit
		      connectionTimeout            = arguments.connectionTimeout
		      metaCacheTimeout             = arguments.metaCacheTimeout
		      blob                         = arguments.blob
		      clob                         = arguments.clob
		      validate                     = arguments.validate
		      storage                      = arguments.storage
		      allowed_select               = arguments.allowedSelect
		      allowed_insert               = arguments.allowedInsert
		      allowed_update               = arguments.allowedUpdate
		      allowed_delete               = arguments.allowedDelete
		      allowed_alter                = arguments.allowedAlter
		      allowed_drop                 = arguments.allowedDrop
		      allowed_revoke               = arguments.allowedRevoke
		      allowed_create               = arguments.allowedCreate
		      allowed_grant                = arguments.allowedGrant
		      verify                       = arguments.verify
		      custom                       = custom
		      password                     = arguments.luceeAdminPassword;
	}


// PRIVATE HELPERS
	private any function _getDriverForType( required string dbType ) {
		var driverNames = _componentListPackageAsStruct( "lucee-server.admin.dbdriver" );
		    driverNames = _componentListPackageAsStruct( "lucee.admin.dbdriver", driverNames );
		    driverNames = _componentListPackageAsStruct( "dbdriver"            , driverNames );
		var driverClass = driverNames[ dbType ] ?: throw( type="preside.datasource.manager.missing.driver", message="No database driver found for DB type: [#arguments.dbtype#]" );

		return CreateObject( driverClass );
	}

	private struct function _componentListPackageAsStruct( string package, cfcNames=structnew("linked") ){
		try {
			var cfcNameArray = ComponentListPackage( package );
		} catch ( application e ) {
			var cfcNameArray = [];
		}

		for( var cfcName in cfcNameArray ) {
			cfcNames[ cfcName ] = package & "." & cfcName;
		}

		return cfcNames;
	}
}
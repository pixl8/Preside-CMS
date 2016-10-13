/**
 * The database migration service provides logic for
 * running downgrade and upgrade scripts between
 * versions of Preside (core scripts only)
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="Database Migration Service" {

// CONSTRUCTOR
	/**
	 * @updateManagerService.inject updateManagerService
	 *
	 */
	public any function init( required any updateManagerService ) {
		_setUpdateManagerService( arguments.updateManagerService );
		return this;
	}

// PUBLIC API METHODS
	public string function getCurrentDatabaseVersion() {
		var dbQueryResult = $getPresideObject( "preside_database_version" ).selectData(
			  selectFields = [ "version_number" ]
			, orderBy      = "datemodified desc"
			, maxRows      = 1
		);

		return dbQueryResult.version_number ?: "";
	}

	public void function migrate() {
		var currentPresideVersion = _getUpdateManagerService().detectCurrentVersion();

		if ( currentPresideVersion != "unknown" ) {
			var currentDbVersion  = getCurrentDatabaseVersion();
			var versionComparison = !currentDbVersion.len() ? 1 : compareVersions( currentPresideVersion, currentDbVersion );

			if ( versionComparison ) {
				var migrationType = versionComparison == 1 ? "upgrade" : "downgrade";
				var parentDirectory    = "/preside/system/migrations/#migrationType#s";
				var componentPath      = ReReplace( ListChangeDelims( parentDirectory, ".", "/" ), "^\.", "" );
				var migrationFiles     = DirectoryList( parentDirectory, false, "name", "*.cfc" );
				var migrations         = [];
				var versionNumberRegex = "^\d+\.\d+\.\d+$";

				for( var file in migrationFiles ){
					var versionNumber = ListChangeDelims( ReReplaceNoCase( file, "\.cfc$", "" ), ".", "-" );

					if ( ReFind( versionNumberRegex, versionNumber ) ) {
						if ( migrationType == "downgrade" && ( !currentDbVersion.len() || compareVersions( versionNumber, currentDbVersion ) <= 0 ) && compareVersions( versionNumber, currentPresideVersion ) > 0 ) {
							migrations.append( ListAppend( componentPath, ListChangeDelims( versionNumber, "-", "." ), "." ) );
						} elseif ( migrationType == "upgrade" && ( !currentDbVersion.len() || compareVersions( versionNumber, currentDbVersion ) > 0 ) && compareVersions( versionNumber, currentPresideVersion ) <= 0 ) {
							migrations.append( ListAppend( componentPath, ListChangeDelims( versionNumber, "-", "." ), "." ) );
						}
					}
				}
				migrations.sort( function( a, b ){
					var aVersion = ListChangeDelims( ListLast( a, "." ), ".", "-" );
					var bVersion = ListChangeDelims( ListLast( b, "." ), ".", "-" );
					var comparison = compareVersions( aVersion, bVersion );
					return migrationType == "downgrade" ? ( comparison * -1 ) : comparison;
				} );

				for( var migration in migrations ) {
					CreateObject( migration ).run( $getColdbox() );
				}

				if ( Len( Trim( currentDbVersion ) ) ) {
					$getPresideObject( "preside_database_version" ).updateData(
						  data           = { "version_number" = currentPresideVersion }
						, forceUpdateAll = true
					);
				} else {
					$getPresideObject( "preside_database_version" ).insertData( { "version_number" = currentPresideVersion } );
				}
			}

		}
	}

	public numeric function compareVersions() {
		return _getUpdateManagerService().compareVersions( argumentCollection=arguments );
	}

// PRIVATE HELPERS
	private any function _getUpdateManagerService() {
		return _updateManagerService;
	}
	private void function _setUpdateManagerService( required any updateManagerService ) {
		_updateManagerService = arguments.updateManagerService;
	}
}
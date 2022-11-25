/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function doMigrations( boolean async=false ) {
		$SystemOutput( "Checking for DB Migrations " & ( arguments.async ? " (async)..." : "..." ) );

		var migrations  = _listRequiredMigrations( arguments.async );
		for( var migration in migrations ) {
			doMigration( migration, arguments.async );
		}

		$SystemOutput( "Finished DB Migrations " & ( !ArrayLen( migrations ) ? "(no migrations to run)." : "." ) );
	}

	public void function doMigration( required string migration, boolean async=false  ) {
		var actionName = arguments.async ? "runAsync" : "run";

		$SystemOutput( "Running DB Migration: [#arguments.migration#]..." );

		if ( $getColdbox().handlerExists( "dbmigrations.#arguments.migration#.isEnabled" ) ) {
			var enabled = $runEvent(
				  event         = "dbmigrations.#arguments.migration#.isEnabled"
				, private       = true
				, prepostExempt = true
			);

			if ( !enabled ) {
				$SystemOutput( "Migration disabled" );
				return;
			}
		}

		$runEvent(
			  event         = "dbmigrations.#arguments.migration#.#actionName#"
			, private       = true
			, prepostExempt = true
		);
		_markMigrationAsRan( arguments.migration, arguments.async );

		$SystemOutput( "Finished running DB Migration: [#arguments.migration#]." );
	}

// PRIVATE HELPERS
	private array function _listRequiredMigrations( async ) {
		var installed  = _getInstalledMigrations( arguments.async );
		var alreadyRan = _getAlreadyRan();
		var migrations = [];

		for( var migration in installed ) {
			var key = migration & "-" & ( arguments.async ? "async" : "sync" );
			if ( !StructKeyExists( alreadyRan, key ) ) {
				ArrayAppend( migrations, migration );
			}
		}

		return migrations;
	}

	private array function _getInstalledMigrations( async ) {
		var cb         = $getColdbox();
		var possible   = cb.listHandlers( thatStartWith="dbmigrations." )
		var actionName = arguments.async ? "runAsync" : "run";
		var installed  = [];

		for( var handler in possible ) {
			if ( cb.handlerExists( handler & "." & actionName ) ) {
				ArrayAppend( installed, ListLast( handler, "." ) );
			}
		}

		ArraySort( installed, "textnocase" );

		return installed;
	}

	private struct function _getAlreadyRan() {
		var records    = $getPresideObject( "db_migration_history" ).selectData( selectFields=[ "migration_key" ] );
		var alreadyRan = {};

		for( var r in records ) {
			alreadyRan[ r.migration_key ] = true;
		}

		return alreadyRan;
	}

	private void function _markMigrationAsRan( migration, async ) {
		try {
			$getPresideObject( "db_migration_history" ).insertData( {
				migration_key = arguments.migration & "-" & ( arguments.async ? "async" : "sync" )
			} );
		} catch( database e ) {
			// ignoring duplicate keys
			if ( !e.message contains "ux_db_migration_history_migrationkey" ) {
				rethrow;
			}
		}
	}
}
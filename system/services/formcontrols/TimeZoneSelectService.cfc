/**
 * Provides methods for populating the timeZoneSelect form control.
 *
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @i18n.inject        coldbox:plugin:i18n
	 */
	public any function init( required any i18n ) {
		_setI18n( arguments.i18n );

		return this;
	}

// PUBLIC METHODS
	public query function getTimeZones() {
		if ( StructKeyExists( variables, "timezoneQuery" ) ) {
			return variables.timezoneQuery;
		}

		var i18n             = _getI18n();
		var timeZones        = i18n.getAvailableTZ();
		var timezoneQuery    = queryNew( "" );
		var ids              = [];
		var offsets          = [];
		var formattedOffsets = [];
		var names            = [];

		for( var timeZone in timeZones ) {
			if ( listLen( timeZone, "/" ) > 1 && !listFindNoCase( "SystemV", listFirst( timeZone, "/" ) ) ) {
				var offset = i18n.getRawOffset( timeZone );

				ids.append( timeZone );
				offsets.append( offset );
				formattedOffsets.append( _formatOffset( offset ) );
				names.append( i18n.getTZDisplayName( timeZone ) );
			}
		}

		timezoneQuery.addColumn( "id"             , "varchar", ids              );
		timezoneQuery.addColumn( "offset"         , "double" , offsets          );
		timezoneQuery.addColumn( "formattedOffset", "double" , formattedOffsets );
		timezoneQuery.addColumn( "name"           , "varchar", names            );

		variables.timezoneQuery = queryExecute(
			  sql     = "select id, offset, formattedOffset, name from timezoneQuery order by offset, id"
			, options = { dbtype="query" }
		);

		return variables.timezoneQuery;
	}

// PRIVATE METHODS & HELPERS
	private string function _formatOffset( required numeric offset) {
		var formatted = arguments.offset < 1 ? "-" : "+";
		formatted &= numberFormat( int( abs( arguments.offset ) ), "00" ) & ":";
		formatted &= numberFormat( ( abs( arguments.offset ) % 1 ) * 60, "00" );

		return formatted;
	}

// GETTERS AND SETTERS
	private struct function _getI18n() {
		return _i18n;
	}
	private void function _setI18n( required any i18n ) {
		_i18n = arguments.i18n;
	}

}


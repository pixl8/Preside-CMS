/**
 * @feature assetManager
 */
component {

	property name="dsn"       inject="coldbox:setting:dsn";
	property name="sqlRunner" inject="SqlRunner";

	private void function runAsync() {
		var records = sqlRunner.runSql(
				  dsn = dsn
				, sql = "
					SELECT
						  v1.id    as version_id
						, v1.asset as asset_id
					FROM
						psys_asset_version v1
					JOIN
						psys_asset_version v2 ON v1.asset = v2.asset
							AND v1.version_number = 1
							AND v2.version_number = 2
							AND v1.datecreated = v2.datecreated
		" );

		for ( var record in records ) {
			var asset = getPresideObject( "asset" ).selectData( id=record.asset_id, selectFields=[ "datecreated", "datemodified" ] );

			if ( asset.recordCount ) {
				getPresideObject( "asset_version" ).updateData(
					  id   = record.version_id
					, data = {
						  datecreated  = asset.datecreated
						, datemodified = asset.datemodified
					  }
				);
			}
		}
	}

}
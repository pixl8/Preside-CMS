component extends="originalcoldbox.system.core.util.Util" {

	function getInheritedMetaData( component, stopRecursions=[], md={} ) output=false {
		if ( StructIsEmpty( arguments.md ) ) {
			if ( IsObject( arguments.component ) ) {
				arguments.md = getMetadata();
			} else {
				arguments.md = preside.system.services.helpers.ComponentMetaDataReader::readMeta( arguments.component );
			}
		}

		return super.getInheritedMetaData( argumentCollection=arguments );
	}

}
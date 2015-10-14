component {

	public any function readDataFile( required string filePath ) {
		var fileDirectory              = GetDirectoryFromPath( arguments.filePath );
		var fileContent                = FileRead( arguments.filePath );
		var parsed                     = DeserializeJson( fileContent );
		var IncludeResolver            = new IncludeResolver();
		var parsedWithIncludesResolved = includeResolver.resolveIncludesInStructuredData(
			  data          = parsed
			, rootDirectory = fileDirectory
		);

		return parsedWithIncludesResolved;
	}

}
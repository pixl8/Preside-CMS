/**
 * Simple wrapper to Java library for generating QR Codes
 *
 * @autodoc
 * @singleton
 *
 */
component {

	public any function init() {
		_setupLibPath(  );

		return this;
	}

// PUBLIC API
	public binary function generateQrCode( required string input, numeric size=125, string imageType="gif" ) {
		var qrCode = CreateObject( "java", "net.glxn.qrgen.javase.QRCode", _getLibPath() );
		var binary = qrCode.from( arguments.input )
		      .to( _getImageTypeConstant( arguments.imageType ) )
		      .withSize( arguments.size, arguments.size )
		      .stream()
		      .toByteArray();

		if ( arguments.imageType == "jpg" ) {
			FileWrite( "/resources/qrcodes/helloWorld.jpg", binary );
		}

		return binary;
	}



// PRIVATE HELPERS
	private void function _setupLibPath() {
		var dir      = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/lib";
		var jarFiles = DirectoryList( dir, true, "path" );

		_setLibPath( jarFiles );
	}

	private string function _getImageTypeConstant( required string imageType ) {
		var imageTypes = CreateObject( "java", "net.glxn.qrgen.core.image.ImageType", _getLibPath() );

		switch( arguments.imageType ) {
			case "jpg":
				return imageTypes.JPG;
			case "png":
				return imageTypes.PNG;
			default:
				return imageTypes.GIF;
		}
	}

// ACCESSORS
	private array function _getLibPath() {
		return _libPath;
	}
	private void function _setLibPath( required array libPath ) {
		_libPath = arguments.libPath;
	}

}
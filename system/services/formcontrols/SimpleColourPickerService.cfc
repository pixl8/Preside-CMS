/**
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		variables.palettes = {};

		registerPalette(
			  name      = "web64"
			, colours   = buildRgbColourArray( 0, 255, 85 )
			, rowLength = 16
		);
		registerPalette(
			  name      = "web216"
			, colours   = buildRgbColourArray( 0, 255, 51 )
			, rowLength = 24
		);
		registerPalette(
			  name      = "material"
			, colours   = [ "f44336", "e91e63", "9c27b0", "673ab7", "3f51b5", "2196f3", "03a9f4", "00bcd4", "009688", "4caf50", "8bc34a", "cddc39", "ffeb3b", "ffc107", "ff9800", "ff5722", "795548", "9e9e9e", "607d8b", "000000", "ffffff" ]
			, rowLength = 7
		);

		return this;
	}

// PUBLIC METHODS
	public void function registerPalette(
		  required string  name
		, required array   colours
		,          numeric rowLength = 16
	) {
		variables.palettes[ name ] = {
			  name      = name
			, colours   = colours
			, rowLength = rowLength
		};
	}

	public any function getPalette( required string name ) {
		return variables.palettes[ name ] ?: variables.palettes[ "web64" ];
	}

	public array function convertColours(
		  required array  colours
		, required string colourFormat
	) {
		var currentFormat    = "";
		var convertedColour  = "";
		var convertedColours = [];
		
		for( var colour in colours ) {
			currentFormat   = _detectColourFormat( colour );
			convertedColour = "";

			if ( currentFormat == colourFormat ) {
				convertedColour = colour;
			} else if ( currentFormat == "hex" ) {
				convertedColour = _hexToRgb( colour );
			} else {
				convertedColour = _rgbToHex( colour );
			}

			convertedColours.append( convertedColour );
		}

		return convertedColours;
	}

	public array function buildRgbColourArray(
		  required numeric from
		, required numeric to
		, required numeric step
	) {
		var colours = [];

		for( var r=from; r<=to; r+=step ) {
			for( var g=from; g<=to; g+=step ) {
				for( var b=from; b<=to; b+=step ) {
					colours.append( "#r#,#g#,#b#" );
				}	
			}	
		}

		return colours;
	}


// PRIVATE METHODS & HELPERS

	private string function _detectColourFormat( required string colour ) {
		if ( listLen( colour ) == 3 ) {
			return "rgb";
		}
		if ( REFindNoCase( "^[0-9a-f]{3}$", colour ) || REFindNoCase( "^[0-9a-f]{6}$", colour ) ) {
			return "hex";
		}
		throw(
			  type    = "SimpleColourPicker.invalidColour"
			, message = $translateResource( uri="formcontrols.simpleColourPicker:error.invalidColour", data=[ colour ] )
		);
	}

	private string function _hexToRgb( hexColour ) {
		var chunkSize = len( hexColour ) == 3 ? 1 : 2;
		var red       = mid( hexColour, 1                    , chunkSize );
		var green     = mid( hexColour, chunkSize + 1        , chunkSize );
		var blue      = mid( hexColour, ( chunkSize * 2 ) + 1, chunkSize );

		if ( chunkSize == 1 ) {
			red   = red & red;
			green = green & green;
			blue  = blue & blue;
		}

		return inputBaseN( red, 16 ) & "," & inputBaseN( green, 16 ) & "," & inputBaseN( blue, 16 );
	}

	private string function _rgbToHex( rgbColour ) {
		var red   = trim( listGetAt( rgbColour, 1 ) );
		var green = trim( listGetAt( rgbColour, 2 ) );
		var blue  = trim( listGetAt( rgbColour, 3 ) );

		if ( red < 0 || red > 255 || green < 0 || green > 255 || blue < 0 || blue > 255 ) {
			throw(
				  type    = "SimpleColourPicker.invalidRgbColour"
				, message = $translateResource( uri="formcontrols.simpleColourPicker:error.invalidRgbColour", data=[ rgbColour ] )
			);
		}

		return _toHex( red ) & _toHex( green ) & _toHex( blue );
	}

	private string function _toHex( base10Value ) {
		var hex = formatBaseN( base10Value, 16 );
		return len( hex ) == 1 ? "0" & hex : hex;
	}

// GETTERS AND SETTERS

}


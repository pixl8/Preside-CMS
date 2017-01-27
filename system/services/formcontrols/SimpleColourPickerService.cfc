/**
 * Provides methods for creating and registering custom palettes for the simpleColourPicker form control,
 * plus a few helper methods for validating and manipulating colours.
 * 
 * @autodoc
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

	/**
	 * Registers a colour palette for use with the simpleColourPicker form control.
	 * 
	 * ${arguments}
	 * 
	 * ## Example
	 *
	 * ```luceescript
	 * simpleColourPickerService.registerPalette(
	 * \t  name      = "greyscale"
	 * \t, colours   = [ "000", "111", "222", "333", "444", "555", "666", "777", "888", "999", "aaa", "bbb", "ccc", "ddd", "eee", "fff" ]
	 * \t, rowLength = 8
	 * );
	 *```
	 *
	 * @autodoc 
	 * @name.hint      Name by which you will refer to your palette in the form definition XML
	 * @colours.hint   An array of colour values, in either RGB format (just the numbers, e.g. <code>100,150,0</code>) or a 3- or 6-character hex value - or even a mixture of the two.
	 * @rowLength.hint The maximum number of colours displayed on each row of the colour picker
	 */
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

	/**
	 * Builds a matrix of RGB colour values based on a simple regular pattern.
	 *
	 * @autodoc 
	 * @from.hint Starting value for each of the R, G and B colour values
	 * @to.hint   Ending value for each of the R, G and B colour values
	 * @step.hint Amount by which each value should increase for successive colours
	 */
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

	/**
	 * Converts an array of colour values to the specified colour format.
	 *
	 * @autodoc 
	 * @colours.hint      Array of colour values - hex, RGB, or a mix of the two.
	 * @colourFormat.hint Format to convert the colours to. Supported formats are <code>hex</code> and <code>rgb</code>.
	 */
	public array function convertColours(
		  required array  colours
		, required string colourFormat
	) {
		var currentFormat    = "";
		var convertedColour  = "";
		var convertedColours = [];
		
		for( var colour in colours ) {
			currentFormat   = detectColourFormat( colour );
			convertedColour = "";

			if ( currentFormat == colourFormat ) {
				convertedColour = colour;
			} else if ( currentFormat == "hex" ) {
				convertedColour = hexToRgb( colour, true );
			} else {
				convertedColour = rgbToHex( colour, true );
			}

			convertedColours.append( convertedColour );
		}

		return convertedColours;
	}

	/**
	 * Detects the colour format (RGB or hex) of a given colour value.
	 * \n
	 * Throws `SimpleColourPicker.invalidColour` error if the format cannot be detected.
	 *
	 * @autodoc 
	 * @colour.hint The colour value to be tested
	 */
	public string function detectColourFormat( required string colour ) {
		if ( isValidRgb( colour ) ) {
			return "rgb";
		}
		if ( isValidHex( colour ) ) {
			return "hex";
		}
		throw(
			  type    = "SimpleColourPicker.invalidColour"
			, message = $translateResource( uri="formcontrols.simpleColourPicker:error.invalidColour", data=[ colour ] )
		);
	}

	/**
	 * Converts a hex colour value to RGB.
	 * \n
	 * Throws `SimpleColourPicker.invalidHexColour` error if the input value is not a valid hex colour.
	 *
	 * @autodoc 
	 * @hexColour.hint The hex colour value to be converted
	 * @validated.hint Has the value already been validated as a hex colour? If so, skip validating it again
	 */
	public string function hexToRgb( required string hexColour, boolean validated=false ) {
		if ( !validated && !isValidHex( hexColour ) ) {
			throw(
				  type    = "SimpleColourPicker.invalidHexColour"
				, message = $translateResource( uri="formcontrols.simpleColourPicker:error.invalidHexColour", data=[ hexColour ] )
			);
		}

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

	/**
	 * Converts an RGB colour value to hex.
	 * \n
	 * Throws `SimpleColourPicker.invalidRgbColour` error if the input value is not a valid RGB colour.
	 *
	 * @autodoc 
	 * @rgbColour.hint The RGB colour value to be converted
	 * @validated.hint Has the value already been validated as an RGB colour? If so, skip validating it again
	 */
	public string function rgbToHex( required string rgbColour, boolean validated=false ) {
		if ( !validated && !isValidRgb( rgbColour ) ) {
			throw(
				  type    = "SimpleColourPicker.invalidRgbColour"
				, message = $translateResource( uri="formcontrols.simpleColourPicker:error.invalidRgbColour", data=[ rgbColour ] )
			);
		}

		var parts = listToArray( rgbColour );
		var red   = trim( parts[ 1 ] );
		var green = trim( parts[ 2 ] );
		var blue  = trim( parts[ 3 ] );

		return _toHexPair( red ) & _toHexPair( green ) & _toHexPair( blue );
	}

	/**
	 * Checks that a given colour value is a valid RGB colour.
	 *
	 * @autodoc 
	 * @colour.hint The colour value to be validated
	 */
	public boolean function isValidRgb( required string colour ) {
		var parts = listToArray( colour );

		if ( parts.len() != 3 ) {
			return false;
		}
		for( var part in parts ) {
			part = trim( part );
			if ( !isValid( "integer", part ) || part < 0 || part > 255 ) {
				return false;
			}
		}
		return true;
	}

	/**
	 * Checks that a given colour value is a valid 3- or 6-character hex colour.
	 *
	 * @autodoc 
	 * @colour.hint The colour value to be validated
	 */
	public boolean function isValidHex( required string colour ) {
		return REFindNoCase( "^[0-9a-f]{3}$", colour ) || REFindNoCase( "^[0-9a-f]{6}$", colour );
	}

// PRIVATE METHODS & HELPERS
	private string function _toHexPair( required numeric base10Value ) {
		var hex = formatBaseN( base10Value, 16 );
		return len( hex ) == 1 ? "0" & hex : hex;
	}

// GETTERS AND SETTERS
	/**
	 * Returns the named palette. If the named palette is not found, the default "web64" palette will be returned.
	 * \n
	 * This method is probably only of use internally by the form control, but is listed here for the sake of completeness.
	 *
	 * @autodoc 
	 * @name.hint The name of the palette to be returned
	 */
	public struct function getPalette( required string name ) {
		return variables.palettes[ name ] ?: variables.palettes[ "web64" ];
	}

	/**
	 * Returns a list of all the available palettes (both built-in and custom-registered).
	 *
	 * @autodoc 
	 */
	public string function getAvailablePalettes() {
		return structKeyList( variables.palettes );
	}

}


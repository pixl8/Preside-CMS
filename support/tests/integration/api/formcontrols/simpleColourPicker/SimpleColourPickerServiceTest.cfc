component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getPalette()", function(){
			it( "should return the requested palette if found", function(){
				var service = _getService();
				var palette = service.getPalette( "web216" );

				expect( palette ).toHaveKey( "name"      );
				expect( palette ).toHaveKey( "colours"   );
				expect( palette ).toHaveKey( "rowLength" );
				expect( palette.name      ).toBe( "web216" );
				expect( palette.rowLength ).toBe( 24 );
				expect( palette.colours   ).toBeTypeOf( "array" );
				expect( palette.colours   ).toHaveLength( 216 );
			} );

			it( "should return the default (web64) palette if requested palette not found", function(){
				var service = _getService();
				var palette = service.getPalette( "undefinedpalette" );

				expect( palette.name ).toBe( "web64" );
			} );

			it( "should return any of the built-in palettes if requested", function(){
				var service = _getService();

				expect( service.getPalette( "web64"    ).name ).toBe( "web64"    );
				expect( service.getPalette( "web216"   ).name ).toBe( "web216"   );
				expect( service.getPalette( "material" ).name ).toBe( "material" );
			} );
		} );

		describe( "getAvailablePalettes()", function(){
			it( "should return a list of the default palettes", function(){
				var service  = _getService();
				var palettes = service.getAvailablePalettes();

				expect( listLen( palettes ) ).toBe( 3 );
				expect( listFindNoCase( palettes, "web64"    ) ).toBeTrue();
				expect( listFindNoCase( palettes, "web216"   ) ).toBeTrue();
				expect( listFindNoCase( palettes, "material" ) ).toBeTrue();
			} );
			it( "should return a list of the default and custom palettes", function(){
				var service  = _getService();
				service.registerPalette(
					  name    = "custom"
					, colours = [ "000" ]
				);
				var palettes = service.getAvailablePalettes();

				expect( listLen( palettes ) ).toBe( 4 );
				expect( listFindNoCase( palettes, "custom" ) ).toBeTrue();
			} );
		} );

		describe( "registerPalette()", function(){
			it( "should add a custom-defined palette which can then be accessed", function(){
				var service       = _getService();
				var paletteBefore = service.getPalette( "custompalette" );

				service.registerPalette(
					  name    = "custompalette"
					, colours = [ "000", "ffffff", "0,150,255" ]
				);
				
				var paletteAfter  = service.getPalette( "custompalette" );

				expect( paletteBefore.name   ).toBe( "web64" );
				expect( paletteAfter.name    ).toBe( "custompalette" );
				expect( paletteAfter.colours ).toHaveLength( 3 );
			} );
		} );

		describe( "convertColours()", function(){
			it( "should convert an array of colours to the specified colour format", function(){
				var service = _getService();
				var colours = [ "000", "ffffff", "0,102,255" ];
				
				expect( service.convertColours( colours, "hex") ).toBe( [ "000000", "ffffff"     , "0066ff"    ] );
				expect( service.convertColours( colours, "rgb") ).toBe( [ "0,0,0" , "255,255,255", "0,102,255" ] );
			} );
		} );

		describe( "buildRgbColourArray()", function(){
			it( "should return an array of RGB colours generated according to the arguments", function(){
				var service  = _getService();

				var colours  = service.buildRgbColourArray( from=0, to=200, step=100 );
				var expected = [
					  "0,0,0"    , "0,0,100"    , "0,0,200"
					, "0,100,0"  , "0,100,100"  , "0,100,200"
					, "0,200,0"  , "0,200,100"  , "0,200,200"
					, "100,0,0"  , "100,0,100"  , "100,0,200"
					, "100,100,0", "100,100,100", "100,100,200"
					, "100,200,0", "100,200,100", "100,200,200"
					, "200,0,0"  , "200,0,100"  , "200,0,200"
					, "200,100,0", "200,100,100", "200,100,200"
					, "200,200,0", "200,200,100", "200,200,200"
				];
				
				expect( colours ).toBe( expected );
			} );
		} );

		describe( "detectColourFormat()", function(){
			it( "should detect the colour format of a colour value passed to it", function(){
				var service  = _getService();
				
				expect( service.detectColourFormat( "100,150,200" ) ).toBe( "rgb" );
				expect( service.detectColourFormat( "66ff09"      ) ).toBe( "hex" );
				expect( service.detectColourFormat( "f99"         ) ).toBe( "hex" );
				expect( function() {
					service.detectColourFormat( "0,0,0,1" );
				} ).toThrow( type="SimpleColourPicker.invalidColour" );
				expect( function() {
					service.detectColourFormat( "f99f"    );
				} ).toThrow( type="SimpleColourPicker.invalidColour" );
			} );
		} );

		describe( "isValidRgb()", function(){
			it( "should return true with a valid RGB value", function(){
				var service  = _getService();
				
				expect( service.isValidRgb( "0,0,0"       ) ).toBeTrue();
				expect( service.isValidRgb( "100,255,200" ) ).toBeTrue();
				expect( service.isValidRgb( "51, 102, 51" ) ).toBeTrue();
			} );

			it( "should return false with an invalid RGB value", function(){
				var service  = _getService();
				
				expect( service.isValidRgb( ""           ) ).toBeFalse();
				expect( service.isValidRgb( "fcc"        ) ).toBeFalse();
				expect( service.isValidRgb( "0,0,100,20" ) ).toBeFalse();
				expect( service.isValidRgb( "0,0,300"    ) ).toBeFalse();
			} );
		} );

		describe( "isValidHex()", function(){
			it( "should return true with a valid hex value", function(){
				var service  = _getService();
				
				expect( service.isValidHex( "fcc"    ) ).toBeTrue();
				expect( service.isValidHex( "aa09f5" ) ).toBeTrue();
			} );

			it( "should return false with an invalid hex value", function(){
				var service  = _getService();
				
				expect( service.isValidHex( ""        ) ).toBeFalse();
				expect( service.isValidHex( "fcca"    ) ).toBeFalse();
				expect( service.isValidHex( "aa235g"  ) ).toBeFalse();
				expect( service.isValidHex( "0,0,300" ) ).toBeFalse();
			} );
		} );

		describe( "hexToRgb()", function(){
			it( "should convert a hex colour to RGB", function(){
				var service  = _getService();
				
				expect( service.hexToRgb( "fcc"    ) ).toBe( "255,204,204" );
				expect( service.hexToRgb( "66ff09" ) ).toBe( "102,255,9"   );
			} );
			it( "should throw an error if invalid hex colour is provided", function(){
				var service  = _getService();

				expect( function() {
					service.hexToRgb( "ffaaee9" );
				} ).toThrow( type="SimpleColourPicker.invalidHexColour" );
			} );
		} );

		describe( "rgbToHex()", function(){
			it( "should convert an RGB colour to hex", function(){
				var service  = _getService();
				
				expect( service.rgbToHex( "102,255,9" ) ).toBe( "66ff09" );
			} );
			it( "should throw an error if invalid RGB colour is provided", function(){
				var service  = _getService();

				expect( function() {
					service.rgbToHex( "0,0,300" );
				} ).toThrow( type="SimpleColourPicker.invalidRgbColour" );
			} );
		} );

		describe( "_toHexPair()", function(){
			it( "should convert a base 10 value to a hex pair", function(){
				var service  = _getService();
				makePublic( service, "_toHexPair", "toHexPair" );
				
				expect( service.toHexPair( "0"  ) ).toBe( "00" );
				expect( service.toHexPair( "10" ) ).toBe( "0a" );
				expect( service.toHexPair( "51" ) ).toBe( "33" );
			} );
		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		var service = createMock( object=new preside.system.services.formcontrols.SimpleColourPickerService() );
		service.$("$translateResource").$results( "Generic error message" );

		return service;
	}

}
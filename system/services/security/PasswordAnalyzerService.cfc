/**
 * A class that provides methods for analyzing the strength of passwords
 *
 * @autodoc true
 */
component {

// PUBLIC API
	public numeric function calculatePasswordStrength( required string password ) {
		var bruteForceTimeInSeconds = _getBruteForceTimeInSeconds( arguments.password );
		var bruteForceScore         = _calculateStrengthFromTime( bruteForceTimeInSeconds );

		return bruteForceScore;
	}

// PRIVATE UTILITY
	private numeric function _getBruteForceTimeInSeconds( required string password ) {
		var charsetSize           = _calculateCharsetSize( arguments.password );
		var calculationsPerSecond = 5 * ( 10 ^ 13 ); // botnet

		return ( charsetSize ^ password.len() ) / calculationsPerSecond / 2;
	}

	private numeric function _calculateCharsetSize( required string password ) {
		var matchedSymbolClasses = {};
		var size = 0;
		var symbolClasses = {
			uppercase: {
				size   = 26,
				regexp = "[A-Z]"
			},
			lowercase: {
				size   = 26,
				regexp = "[a-z]"
			},
			digits: {
				size   = 10,
				regexp = "[0-9]"
			},
			unicode1: {
				size   = 127,
				regexp = "[\u0080-\u00FF]"
			},
			unicode2: {
				size   = 127,
				regexp = "[\u0100-\u017F]"
			},
			unicode3: {
				size   = 207,
				regexp = "[\u0180-\u024F]"
			},
			unicode4: {
				size   = 95,
				regexp = "[\u0250-\u02AF]"
			},
			unicode5: {
				size   = 79,
				regexp = "[\u02B0-\u02FF]"
			},
			unicode6: {
				size   = 111,
				regexp = "[\u0300-\u036F]"
			},
			unicode7: {
				size   = 143,
				regexp = "[\u0370-\u03FF]"
			},
			unicode8: {
				size   = 255,
				regexp = "[\u0400-\u04FF]"
			},
			unicode9: {
				size   = 47,
				regexp = "[\u0500-\u052F]"
			},
			unicode10: {
				size   = 95,
				regexp = "[\u0530-\u058F]"
			},
			unicode11: {
				size   = 111,
				regexp = "[\u0590-\u05FF]"
			},
			unicode12: {
				size   = 255,
				regexp = "[\u0600-\u06FF]"
			},
			unicode13: {
				size   = 79,
				regexp = "[\u0700-\u074F]"
			},
			unicode14: {
				size   = 47,
				regexp = "[\u0750-\u077F]"
			},
			unicode15: {
				size   = 63,
				regexp = "[\u0780-\u07BF]"
			},
			unicode16: {
				size   = 63,
				regexp = "[\u07C0-\u07FF]"
			},
			unicode17: {
				size   = 127,
				regexp = "[\u0900-\u097F]"
			},
			unicode18: {
				size   = 127,
				regexp = "[\u0980-\u09FF]"
			},
			unicode19: {
				size   = 127,
				regexp = "[\u0A00-\u0A7F]"
			},
			unicode20: {
				size   = 127,
				regexp = "[\u0A80-\u0AFF]"
			},
			unicode21: {
				size   = 127,
				regexp = "[\u0B00-\u0B7F]"
			},
			unicode22: {
				size   = 127,
				regexp = "[\u0B80-\u0BFF]"
			},
			unicode23: {
				size   = 127,
				regexp = "[\u0C00-\u0C7F]"
			},
			unicode24: {
				size   = 127,
				regexp = "[\u0C80-\u0CFF]"
			},
			unicode25: {
				size   = 127,
				regexp = "[\u0D00-\u0D7F]"
			},
			unicode26: {
				size   = 127,
				regexp = "[\u0D80-\u0DFF]"
			},
			unicode27: {
				size   = 127,
				regexp = "[\u0E00-\u0E7F]"
			},
			unicode28: {
				size   = 127,
				regexp = "[\u0E80-\u0EFF]"
			},
			unicode29: {
				size   = 255,
				regexp = "[\u0F00-\u0FFF]"
			},
			unicode30: {
				size   = 159,
				regexp = "[\u1000-\u109F]"
			},
			unicode31: {
				size   = 95,
				regexp = "[\u10A0-\u10FF]"
			},
			unicode32: {
				size   = 255,
				regexp = "[\u1100-\u11FF]"
			},
			unicode33: {
				size   = 383,
				regexp = "[\u1200-\u137F]"
			},
			unicode34: {
				size   = 31,
				regexp = "[\u1380-\u139F]"
			},
			unicode35: {
				size   = 95,
				regexp = "[\u13A0-\u13FF]"
			},
			unicode36: {
				size   = 639,
				regexp = "[\u1400-\u167F]"
			},
			unicode37: {
				size   = 31,
				regexp = "[\u1680-\u169F]"
			},
			unicode38: {
				size   = 95,
				regexp = "[\u16A0-\u16FF]"
			},
			unicode39: {
				size   = 31,
				regexp = "[\u1700-\u171F]"
			},
			unicode40: {
				size   = 31,
				regexp = "[\u1720-\u173F]"
			},
			unicode41: {
				size   = 31,
				regexp = "[\u1740-\u175F]"
			},
			unicode42: {
				size   = 31,
				regexp = "[\u1760-\u177F]"
			},
			unicode43: {
				size   = 127,
				regexp = "[\u1780-\u17FF]"
			},
			unicode44: {
				size   = 175,
				regexp = "[\u1800-\u18AF]"
			},
			unicode45: {
				size   = 79,
				regexp = "[\u1900-\u194F]"
			},
			unicode46: {
				size   = 47,
				regexp = "[\u1950-\u197F]"
			},
			unicode47: {
				size   = 95,
				regexp = "[\u1980-\u19DF]"
			},
			unicode48: {
				size   = 31,
				regexp = "[\u19E0-\u19FF]"
			},
			unicode49: {
				size   = 31,
				regexp = "[\u1A00-\u1A1F]"
			},
			unicode50: {
				size   = 127,
				regexp = "[\u1B00-\u1B7F]"
			},
			unicode51: {
				size   = 127,
				regexp = "[\u1D00-\u1D7F]"
			},
			unicode52: {
				size   = 63,
				regexp = "[\u1D80-\u1DBF]"
			},
			unicode53: {
				size   = 63,
				regexp = "[\u1DC0-\u1DFF]"
			},
			unicode54: {
				size   = 255,
				regexp = "[\u1E00-\u1EFF]"
			},
			unicode55: {
				size   = 255,
				regexp = "[\u1F00-\u1FFF]"
			},
			unicode56: {
				size   = 111,
				regexp = "[\u2000-\u206F]"
			},
			unicode57: {
				size   = 47,
				regexp = "[\u2070-\u209F]"
			},
			unicode58: {
				size   = 47,
				regexp = "[\u20A0-\u20CF]"
			},
			unicode59: {
				size   = 47,
				regexp = "[\u20D0-\u20FF]"
			},
			unicode60: {
				size   = 79,
				regexp = "[\u2100-\u214F]"
			},
			unicode61: {
				size   = 63,
				regexp = "[\u2150-\u218F]"
			},
			unicode62: {
				size   = 111,
				regexp = "[\u2190-\u21FF]"
			},
			unicode63: {
				size   = 255,
				regexp = "[\u2200-\u22FF]"
			},
			unicode64: {
				size   = 255,
				regexp = "[\u2300-\u23FF]"
			},
			unicode65: {
				size   = 63,
				regexp = "[\u2400-\u243F]"
			},
			unicode66: {
				size   = 31,
				regexp = "[\u2440-\u245F]"
			},
			unicode67: {
				size   = 159,
				regexp = "[\u2460-\u24FF]"
			},
			unicode68: {
				size   = 127,
				regexp = "[\u2500-\u257F]"
			},
			unicode69: {
				size   = 31,
				regexp = "[\u2580-\u259F]"
			},
			unicode70: {
				size   = 95,
				regexp = "[\u25A0-\u25FF]"
			},
			unicode71: {
				size   = 255,
				regexp = "[\u2600-\u26FF]"
			},
			unicode72: {
				size   = 191,
				regexp = "[\u2700-\u27BF]"
			},
			unicode73: {
				size   = 47,
				regexp = "[\u27C0-\u27EF]"
			},
			unicode74: {
				size   = 15,
				regexp = "[\u27F0-\u27FF]"
			},
			unicode75: {
				size   = 255,
				regexp = "[\u2800-\u28FF]"
			},
			unicode76: {
				size   = 127,
				regexp = "[\u2900-\u297F]"
			},
			unicode77: {
				size   = 127,
				regexp = "[\u2980-\u29FF]"
			},
			unicode78: {
				size   = 255,
				regexp = "[\u2A00-\u2AFF]"
			},
			unicode79: {
				size   = 255,
				regexp = "[\u2B00-\u2BFF]"
			},
			unicode80: {
				size   = 95,
				regexp = "[\u2C00-\u2C5F]"
			},
			unicode81: {
				size   = 31,
				regexp = "[\u2C60-\u2C7F]"
			},
			unicode82: {
				size   = 127,
				regexp = "[\u2C80-\u2CFF]"
			},
			unicode83: {
				size   = 47,
				regexp = "[\u2D00-\u2D2F]"
			},
			unicode84: {
				size   = 79,
				regexp = "[\u2D30-\u2D7F]"
			},
			unicode85: {
				size   = 95,
				regexp = "[\u2D80-\u2DDF]"
			},
			unicode86: {
				size   = 127,
				regexp = "[\u2E00-\u2E7F]"
			},
			unicode87: {
				size   = 127,
				regexp = "[\u2E80-\u2EFF]"
			},
			unicode88: {
				size   = 223,
				regexp = "[\u2F00-\u2FDF]"
			},
			unicode89: {
				size   = 15,
				regexp = "[\u2FF0-\u2FFF]"
			},
			unicode90: {
				size   = 63,
				regexp = "[\u3000-\u303F]"
			},
			unicode91: {
				size   = 95,
				regexp = "[\u3040-\u309F]"
			},
			unicode92: {
				size   = 95,
				regexp = "[\u30A0-\u30FF]"
			},
			unicode93: {
				size   = 47,
				regexp = "[\u3100-\u312F]"
			},
			unicode94: {
				size   = 95,
				regexp = "[\u3130-\u318F]"
			},
			unicode95: {
				size   = 15,
				regexp = "[\u3190-\u319F]"
			},
			unicode96: {
				size   = 31,
				regexp = "[\u31A0-\u31BF]"
			},
			unicode97: {
				size   = 47,
				regexp = "[\u31C0-\u31EF]"
			},
			unicode98: {
				size   = 15,
				regexp = "[\u31F0-\u31FF]"
			},
			unicode99: {
				size   = 255,
				regexp = "[\u3200-\u32FF]"
			},
			unicode100: {
				size   = 255,
				regexp = "[\u3300-\u33FF]"
			},
			unicode101: {
				size   = 6591,
				regexp = "[\u3400-\u4DBF]"
			},
			unicode102: {
				size   = 63,
				regexp = "[\u4DC0-\u4DFF]"
			},
			unicode103: {
				size   = 20991,
				regexp = "[\u4E00-\u9FFF]"
			},
			unicode104: {
				size   = 1167,
				regexp = "[\uA000-\uA48F]"
			},
			unicode105: {
				size   = 63,
				regexp = "[\uA490-\uA4CF]"
			},
			unicode106: {
				size   = 31,
				regexp = "[\uA700-\uA71F]"
			},
			unicode107: {
				size   = 223,
				regexp = "[\uA720-\uA7FF]"
			},
			unicode108: {
				size   = 47,
				regexp = "[\uA800-\uA82F]"
			},
			unicode109: {
				size   = 63,
				regexp = "[\uA840-\uA87F]"
			},
			unicode110: {
				size   = 11183,
				regexp = "[\uAC00-\uD7AF]"
			},
			unicode111: {
				size   = 895,
				regexp = "[\uD800-\uDB7F]"
			},
			unicode112: {
				size   = 127,
				regexp = "[\uDB80-\uDBFF]"
			},
			unicode113: {
				size   = 1023,
				regexp = "[\uDC00-\uDFFF]"
			},
			unicode114: {
				size   = 6399,
				regexp = "[\uE000-\uF8FF]"
			},
			unicode115: {
				size   = 511,
				regexp = "[\uF900-\uFAFF]"
			},
			unicode116: {
				size   = 79,
				regexp = "[\uFB00-\uFB4F]"
			},
			unicode117: {
				size   = 687,
				regexp = "[\uFB50-\uFDFF]"
			},
			unicode118: {
				size   = 15,
				regexp = "[\uFE00-\uFE0F]"
			},
			unicode119: {
				size   = 15,
				regexp = "[\uFE10-\uFE1F]"
			},
			unicode120: {
				size   = 15,
				regexp = "[\uFE20-\uFE2F]"
			},
			unicode121: {
				size   = 31,
				regexp = "[\uFE30-\uFE4F]"
			},
			unicode122: {
				size   = 31,
				regexp = "[\uFE50-\uFE6F]"
			},
			unicode123: {
				size   = 143,
				regexp = "[\uFE70-\uFEFF]"
			},
			unicode124: {
				size   = 239,
				regexp = "[\uFF00-\uFFEF]"
			},
			unicode125: {
				size   = 15,
				regexp = "[\uFFF0-\uFFFF]"
			},
			symbols: {
				size   = 32,
				regexp = "match-all"
			}
		};

		for( var letter in ListToArray( arguments.password, '' ) ) {
			var wasMatched = false;
			for ( var charsetType in symbolClasses ) {
				var spec = symbolClasses[ charsetType ];
				if ( spec.regexp != 'match-all' && JavaCast( 'String', letter ).matches( spec.regexp ) ) {
					wasMatched = true;
					matchedSymbolClasses[ charsetType ] = true;
				}
			}

			if ( !wasMatched ) {
				matchedSymbolClasses.symbols = true;
			}
		}

		for( var symbolClass in matchedSymbolClasses ) {
			size += symbolClasses[ symbolClass ].size;
		}

		return size;
	}


// SOME CRAZY MATHS STUFF TO DO WITH MONOTONIC CUBIC SPLINES
// SEE https://en.wikipedia.org/wiki/Monotone_cubic_interpolation
	private numeric function _calculateStrengthFromTime( required numeric timeInSeconds ) {
		var timeInHours = timeInSeconds / 3600;
		var max = 5 * ( 10 ^ 261 );

		if ( timeInHours > max ) {
			return 260;
		}

		var points = [
			  [ 0                    , 0  ]
			, [ (10 ^ -14.1305100087), 1  ]
			, [ (10 ^ -13.8630800087), 2  ]
			, [ (10 ^ -13.5956500087), 3  ]
			, [ (10 ^ -13.3282200087), 4  ]
			, [ (10 ^ -13.0607900087), 5  ]
			, [ (10 ^ -12.7933600087), 6  ]
			, [ (10 ^ -12.5259300087), 7  ]
			, [ (10 ^ -12.2585000087), 8  ]
			, [ (10 ^ -11.9910700087), 9  ]
			, [ (10 ^ -11.7236400087), 10 ]
			, [ (10 ^ -11.4562100087), 11 ]
			, [ (10 ^ -11.1887800087), 12 ]
			, [ (10 ^ -10.9213500087), 13 ]
			, [ (10 ^ -10.6539200087), 14 ]
			, [ (10 ^ -10.3864900087), 15 ]
			, [ (10 ^ -10.1190600087), 16 ]
			, [ (10 ^ -9.8516300087) , 17 ]
			, [ (10 ^ -9.5842000087) , 18 ]
			, [ (10 ^ -9.3167700087) , 19 ]
			, [ (10 ^ -9.0493400087) , 20 ]
			, [ (10 ^ -8.7819100087) , 21 ]
			, [ (10 ^ -8.5144800087) , 22 ]
			, [ (10 ^ -8.2470500087) , 23 ]
			, [ (10 ^ -7.9796200087) , 24 ]
			, [ (10 ^ -7.7121900087) , 25 ]
			, [ (10 ^ -7.4447600087) , 26 ]
			, [ (10 ^ -7.1773300087) , 27 ]
			, [ (10 ^ -6.9099000087) , 28 ]
			, [ (10 ^ -6.6424700087) , 29 ]
			, [ (10 ^ -6.3750400087) , 30 ]
			, [ (10 ^ -6.1076100087) , 31 ]
			, [ (10 ^ -5.8401800087) , 32 ]
			, [ (10 ^ -5.5727500087) , 33 ]
			, [ (10 ^ -5.3053200087) , 34 ]
			, [ (10 ^ -5.0378900087) , 35 ]
			, [ (10 ^ -4.7704600087) , 36 ]
			, [ (10 ^ -4.5030300087) , 37 ]
			, [ (10 ^ -4.2356000087) , 38 ]
			, [ (10 ^ -3.9681700087) , 39 ]
			, [ (10 ^ -3.7007400087) , 40 ]
			, [ (10 ^ -3.4333100087) , 41 ]
			, [ (10 ^ -3.1658800087) , 42 ]
			, [ (10 ^ -2.8984500087) , 43 ]
			, [ (10 ^ -2.6310200087) , 44 ]
			, [ (10 ^ -2.3635900087) , 45 ]
			, [ (10 ^ -2.0961600087) , 46 ]
			, [ (10 ^ -1.8287300087) , 47 ]
			, [ (10 ^ -1.5613000087) , 48 ]
			, [ (10 ^ -1.2938700087) , 49 ]
			, [ (10 ^ -1.0264400087) , 50 ]
			, [ (10 ^ -0.7590100087) , 51 ]
			, [ (10 ^ -0.4915800087) , 52 ]
			, [ (10 ^ -0.2241500087) , 53 ]
			, [ (10 ^ 0.0432799913)  , 54 ]
			, [ (10 ^ 0.3107099913)  , 55 ]
			, [ (10 ^ 0.5781399913)  , 56 ]
			, [ (10 ^ 0.8455699913)  , 57 ]
			, [ (10 ^ 1.1129999913)  , 58 ]
			, [ (10 ^ 1.3804299913)  , 59 ]
			, [ (10 ^ 1.6478599913)  , 60 ]
			, [ (10 ^ 1.9152899913)  , 61 ]
			, [ (10 ^ 2.1827199913)  , 62 ]
			, [ (10 ^ 2.4501499913)  , 63 ]
			, [ (10 ^ 2.7175799913)  , 64 ]
			, [ (10 ^ 2.9850099913)  , 65 ]
			, [ (10 ^ 3.2524399913)  , 66 ]
			, [ (10 ^ 3.5198699913)  , 67 ]
			, [ (10 ^ 3.7872999913)  , 68 ]
			, [ (10 ^ 4.0547299913)  , 69 ]
			, [ (10 ^ 4.3221599913)  , 70 ]
			, [ (10 ^ 4.5895899913)  , 71 ]
			, [ (10 ^ 4.8570199913)  , 72 ]
			, [ (10 ^ 5.1244499913)  , 73 ]
			, [ (10 ^ 5.3918799913)  , 74 ]
			, [ (10 ^ 5.6593099913)  , 75 ]
			, [ (10 ^ 5.9267399913)  , 76 ]
			, [ (10 ^ 6.1941699913)  , 77 ]
			, [ (10 ^ 6.4615999913)  , 78 ]
			, [ (10 ^ 6.7290299913)  , 79 ]
			, [ (10 ^ 6.9964599913)  , 80 ]
			, [ (10 ^ 7.2638899913)  , 81 ]
			, [ (10 ^ 7.5313199913)  , 82 ]
			, [ (10 ^ 7.7987499913)  , 83 ]
			, [ (10 ^ 8.0661799913)  , 84 ]
			, [ (10 ^ 8.3336099913)  , 85 ]
			, [ (10 ^ 8.6010399913)  , 86 ]
			, [ (10 ^ 8.8684699913)  , 87 ]
			, [ (10 ^ 9.1358999913)  , 88 ]
			, [ (10 ^ 9.4033299913)  , 89 ]
			, [ (10 ^ 9.6707599913)  , 90 ]
			, [ (10 ^ 9.9381899913)  , 91 ]
			, [ (10 ^ 10.2056199913) , 92 ]
			, [ (10 ^ 10.4730499913) , 93 ]
			, [ (10 ^ 10.7404799913) , 94 ]
			, [ (10 ^ 11.0079099913) , 95 ]
			, [ (10 ^ 11.2753399913) , 96 ]
			, [ (10 ^ 11.5427699913) , 97 ]
			, [ (10 ^ 11.8101999913) , 98 ]
			, [ (10 ^ 12.0776299913) , 99 ]
			, [ (10 ^ 12.3450599913) , 100]
			, [ (10 ^ 20)            , 100]
			, [ (10 ^ 50)            , 120]
			, [ (10 ^ 70)            , 140]
			, [ (10 ^ 90)            , 160]
			, [ (10 ^ 110)           , 180]
			, [ 5 * (10 ^ 130)       , 200]
			, [ (10 ^ 156)           , 220]
			, [ 2 * (10 ^ 197)       , 240]
			, [ max                  , 260]
		];

		var inputs = points.map( function( el ) {
			return el[ 1 ];
		});
		var outputs = points.map(function( el ) {
			return el[ 2 ];
		});

		return Round( _monotonicCubicSplineInterpolation( inputs, outputs, timeInHours ) );
	}

	private numeric function _monotonicCubicSplineInterpolation( required array inputMap, required array outputMap, required numeric input ) {
		var mapped = _prepareMonotonicCubicSplineInterpolation( arguments.inputMap, arguments.outputMap );
		var i      = "";

		for( i = arguments.inputMap.len() - 1; i >= 1; i-- ) {
			if ( arguments.inputMap[i] <= arguments.input ) {
				break;
			}
		}

		var h  = arguments.inputMap[i + 1] - arguments.inputMap[i];
		var t  = ( arguments.input - arguments.inputMap[i] ) / h;
		var t2 = t ^ 2;
		var t3 = t ^ 3;
		var h00 = 2 * t3 - 3 * t2 + 1;
		var h10 = t3 - 2 * t2 + t;
		var h01 = -2 * t3 + 3 * t2;
		var h11 = t3 - t2;
		return h00 * arguments.outputMap[i] + h10 * h * mapped[i] + h01 * arguments.outputMap[i + 1] + h11 * h * mapped[i + 1];
	}

	private array function _prepareMonotonicCubicSplineInterpolation( required array inputMap, required array outputMap ) {
		var mapLength = inputMap.len();
		var prepped   = [];
		var alpha     = [];
		var beta      = [];
		var delta     = [];
		var dist      = [];
		var tau       = [];
		var to_fix    = [];
		var i         = 0;
		var _i        = 0;

		for( i=1; i < mapLength; i++ ) {
		    delta[i] = ( outputMap[i + 1] - outputMap[i]) / (inputMap[i + 1] - inputMap[i] );
		    if ( i > 1 ) {
			  prepped[i] = (delta[i - 1] + delta[i]) / 2;
		    }
		}
		prepped[1] = delta[1];
		prepped[mapLength] = delta[mapLength-1];

		for( i=1; i < mapLength; i++ ) {
		    if ( delta[i] == 0 ) {
			  to_fix.append( i );
		    }
		}
		for( _i = 1; _i <= to_fix.len(); _i++ ){
		    i = to_fix[_i];
		    prepped[i] = prepped[i + 1] = 0;
		}

		for( i=1; i < mapLength; i++ ) {
		    if ( delta[i] == 0 ) {
			  alpha[i] = 0;
			  beta[i]  = 0;
		    } else {
			  alpha[i] = prepped[i] / delta[i];
			  beta[i] = prepped[i + 1] / delta[i];
		    }
		    dist[i] = ( alpha[i] ^ 2 ) + ( beta[i] ^ 2 );
		    if ( dist[i] == 0 ) {
			  tau[i] = 0;
		    } else {
			  tau[i] = 3 / Sqr( dist[i] );
		    }
		}

		for( i=1; i < mapLength; i++ ) {
		    if ( dist[i] > 9 ) {
			  to_fix.append( i );
		    }
		}
		for( _i = 1; _i <= to_fix.len(); _i++ ) {
		    i = to_fix[_i];
		    prepped[i] = tau[i] * alpha[i] * delta[i];
		    prepped[i + 1] = tau[i] * beta[i] * delta[i];
		}

		return prepped;
	}
}
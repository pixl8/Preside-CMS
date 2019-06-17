/**
 * A class that provides methods for analyzing the strength of passwords
 *
 * @singleton true
 */
component {

	public any function init() {
		_botnetCalculationsPerSecond = 5 * ( 10 ^ 13 );
		_factorialCache              = {};
		_setupSymbolClasses();
		_setupCommonPasswords();
		_setupMonotoneCubicTimeStrengthMappings();

		return this;
	}

// PUBLIC API
	public numeric function calculatePasswordStrength( required string password ) {
		if ( _commonPasswords.find( arguments.password ) ) {
			return 0;
		}

		var bruteForceTimeInSeconds = _getBruteForceTimeInSeconds( arguments.password );
		var bruteForceScore         = _calculateStrengthFromTime( bruteForceTimeInSeconds );
		var rulesBasedTimeInSeconds = -_getRulesBasedTimeInSeconds( arguments.password );
		var rulesBasedScore         = rulesBasedTimeInSeconds >= 0 ? _calculateStrengthFromTime( rulesBasedTimeInSeconds ) : -1;

		return ( rulesBasedScore >=0 && rulesBasedScore < bruteForceScore ) ? rulesBasedScore : bruteForceScore;
	}

// PRIVATE UTILITY
	private numeric function _getBruteForceTimeInSeconds( required string password ) {
		var charsetSize = _calculateCharsetSize( arguments.password );

		return ( charsetSize ^ password.len() ) / _botnetCalculationsPerSecond / 2;
	}

	/**
	 * I've truly no idea what's going on here. Bunch of maths with horrid variable names.
	 * I've tried to tidy those names up a little but doesn't help much (this code was
	 * converted over from a js library).
	 *
	 */
	private numeric function _getRulesBasedTimeInSeconds( required string password ) {
		var detectedSymbolClasses = _detectSymbolClasses( password );
		var correctCharsets       = true;

		for ( var symbolClass in detectedSymbolClasses ) {
			if ( _symbolClasses[ symbolClass ].isUnicode ) {
				correctCharsets = false;
				break;
			}
		}

		if ( !correctCharsets ) {
			return -1;
		}

		var diffCharsCount = _getNumberOfDifferentCharacters( arguments.password );
		var passwordLength = arguments.password.len();

		if ( diffCharsCount <= 6 || passwordLength <= 6 ) {
			return -1;
		}

		// Binomial coefficient implementation
		var binom = function (n, k) {
			var coeff = 1;

			for (var i = n - k + 1; i <= n; i += 1) {
					coeff *= i;
			}
			for (var i = 1; i <= k; i += 1) {
					coeff /= i;
			}
			return coeff;
		};

		var symbolClassSizes = [];
		for ( var symbolClass in detectedSymbolClasses ) {
			if ( !_symbolClasses[ symbolClass ].isUnicode ) {
				symbolClassSizes.append( _symbolClasses[ symbolClass ].size );
			}
		}
		var charsetsCount = symbolClassSizes.len();

		//  RSELECT
		var digits = [];
		for ( i=1; i <= charsetsCount; i++ ) {
			digits.append( 1 );
		}

		var rselect  = 0;
		var finished = false;
		var sum      = charsetsCount;
		var factor   = "";

		while ( !finished ) {
			if ( sum == diffCharsCount ) {
				factor = 1;

				for ( var i=1; i <= charsetsCount; i++ ) {
					factor *= binom( symbolClassSizes[ i ], digits[ i ] );
				}

				rselect += factor;
			}

			for( var i=1; i <= charsetsCount; i++ ) {
				digits[i]++;
				sum++;

				if( digits[i] > diffCharsCount || sum > diffCharsCount ) {
					if (i == charsetsCount) {
						finished = true;
						break;
					} else {
						sum = sum - digits[i] + 1;
						digits[i] = 1;
					}
				} else {
					break;
				}
			}
		}

		//  RREST
		var digits = [];
		for ( i=1; i <= charsetsCount; i++ ) {
			digits.append( 1 );
		}
		var Lfactorial = _factorial( passwordLength );
		var Xfactorial = _factorial( diffCharsCount );
		var rrest = 0;
		var divide = function (Min, Index, Remain) {
			if (Index == diffCharsCount - 1) {
				digits[diffCharsCount - 1] = Remain;

				var passwordsPerms = Lfactorial;
				var denominator = 1;

				for ( var i=1; i<=digits.len(); i++ ) {
					denominator *= _factorial( digits[i] );
				}

				var lastVal = -1;
				var arr = [];
				for ( var i=1; i<=digits.len(); i++ ) {
					var num = digits[i];
					if (lastVal != num) {
						arr.append(1);
					} else {
						arr[arr.len()] += 1;
					}
					lastVal = num;
				}

				var permutationsDenominator = 1;
				for( i=1; i<=arr.len(); i++ ) {
					permutationsDenominator *= _factorial( arr[i] );
				}

				rrest += (Xfactorial / permutationsDenominator) * (passwordsPerms / denominator);
			} else {
				for ( var i = Min; i < Remain; i += 1) {
					digits[Index] = i;
					if (i <= Remain - i) {
						divide( i, Index + 1, Remain - i );
					}
				}
			}
		};

		divide( 1, 1, passwordLength );

		//  FINAL
		var result = rselect * rrest;
			result = result * diffCharsCount * 15;
			result = result / _botnetCalculationsPerSecond / 2;

		return result;
	}

	private numeric function _calculateCharsetSize( required string password ) {
		var matchedSymbolClasses = _detectSymbolClasses( password );
		var size = 0;

		for( var symbolClass in matchedSymbolClasses ) {
			size += _symbolClasses[ symbolClass ].size;
		}

		return size;
	}

	private array function _detectSymbolClasses( required string password ) {
		var matchedSymbolClasses = {};

		for( var letter in ListToArray( arguments.password, '' ) ) {
			var wasMatched = false;
			for ( var charsetType in _symbolClasses ) {
				var spec = _symbolClasses[ charsetType ];
				if ( spec.regexp != 'match-all' && JavaCast( 'String', letter ).matches( spec.regexp ) ) {
					wasMatched = true;
					matchedSymbolClasses[ charsetType ] = true;
				}
			}

			if ( !wasMatched ) {
				matchedSymbolClasses.symbols = true;
			}
		}

		return matchedSymbolClasses.keyArray();
	}

	private numeric function _getNumberOfDifferentCharacters( required string password ) {
		var letters     = ListToArray( password, '' );
		var diffLetters = {};

		for( var letter in letters ){
			diffLetters[ letter ] = 0;
		}

		return diffLetters.count();
	}

	private void function _setupCommonPasswords() {
		_commonPasswords = DeSerializeJson( FileRead( "./commonPasswords.json" ) );
	}

	private void function _setupSymbolClasses() {
		_symbolClasses = DeSerializeJson( FileRead( "./symbolClasses.json" ) );
	}



// SOME CRAZY MATHS STUFF TO DO WITH MONOTONIC CUBIC SPLINES (I've no idea)
// SEE https://en.wikipedia.org/wiki/Monotone_cubic_interpolation
	private void function _setupMonotoneCubicTimeStrengthMappings() {
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
			, [ 5 * ( 10 ^ 261 )     , 260]
		];

		_inputs = points.map( function( el ) {
			return el[ 1 ];
		});
		_outputs = points.map(function( el ) {
			return el[ 2 ];
		});
		_prepared = _prepareMonotonicCubicSplineInterpolation( _inputs, _outputs );
	}

	private numeric function _calculateStrengthFromTime( required numeric timeInSeconds ) {
		var timeInHours = timeInSeconds / 3600;
		var max = 5 * ( 10 ^ 261 );

		if ( timeInHours > max ) {
			return 260;
		}

		return Round( _monotonicCubicSplineInterpolation( _inputs, _outputs, _prepared, timeInHours ) );
	}

	private numeric function _monotonicCubicSplineInterpolation( required array inputMap, required array outputMap, required array mapped, required numeric input ) {
		var i = "";

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

	private numeric function _factorial( required numeric number ) {
		if ( !StructKeyExists( _factorialCache, number ) ) {
			var factorialResult = 1;
			for ( var i=2; i <= number; i++ ) {
				factorialResult = factorialResult * i;
			}

			_factorialCache[ number ] = factorialResult;
		}

		return _factorialCache[ number ];
	}
}
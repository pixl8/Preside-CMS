/**
 * A class that provides methods for analyzing the strength of passwords, etc.
 *
 * @autodoc true
 */
component {



// SOME CRAZY MATHS STUFF TO DO WITH MONOTONIC CUBIC SPLINES
// SEE https://en.wikipedia.org/wiki/Monotone_cubic_interpolation
	private numeric function _monotonicCubicSplineInterpolation( required array inputMap, required array outputMap, required numeric input ) {
		var mapped = _prepareMonotonicCubicSplineInterpolation( arguments.inputMap, arguments.outputMap );
		var h      = "";
		var h00    = "";
		var h01    = "";
		var h10    = "";
		var h11    = "";
		var i      = "";
		var t      = "";
		var t2     = "";
		var t3     = "";
		var y      = "";

		for( i = arguments.inputMap.len() - 1; i >= 1; i-- ) {
			if ( arguments.inputMap[i] <= arguments.input ) {
				break;
			}
		}

		h  = arguments.inputMap[i + 1] - arguments.inputMap[i];
		t  = ( arguments.input - arguments.inputMap[i] ) / h;
		t2 = t ^ 2;
		t3 = t ^ 3;
		h00 = 2 * t3 - 3 * t2 + 1;
		h10 = t3 - 2 * t2 + t;
		h01 = -2 * t3 + 3 * t2;
		h11 = t3 - t2;
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
			alpha[i] = prepped[i] / delta[i];
			beta[i] = prepped[i + 1] / delta[i];
			dist[i] = ( alpha[i] ^ 2 ) + ( beta[i] ^ 2 );
			tau[i] = 3 / Sqr( dist[i] );
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
/**
 * A class that provides methods for dealing with all aspects of password policies
 *
 * @autodoc true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	public array function listStrengths() {
		return [
			  { name="dangerous", minValue="0"  }
			, { name="bad"      , minValue="15" }
			, { name="moderate" , minValue="40" }
			, { name="good"     , minValue="65" }
			, { name="great"    , minValue="80" }
			, { name="awesome"  , minValue="95" }
		];
	}
}

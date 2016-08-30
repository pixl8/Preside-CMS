/**
 * Handler for rules engine 'boolean type'
 *
 */
component {

	variables._booleanVarietyMappings = {
		  isIsNot     = { truthy="cms:rulesEngine.boolean.is"  , falsey="cms:rulesEngine.boolean.isNot"   }
		, hasHasNot   = { truthy="cms:rulesEngine.boolean.has" , falsey="cms:rulesEngine.boolean.hasNot"  }
		, wasWasNot   = { truthy="cms:rulesEngine.boolean.was" , falsey="cms:rulesEngine.boolean.wasNot"  }
		, willWillNot = { truthy="cms:rulesEngine.boolean.will", falsey="cms:rulesEngine.boolean.willNot" }
		, allAny      = { truthy="cms:rulesEngine.boolean.all" , falsey="cms:rulesEngine.boolean.any"     }
	};

	private string function renderConfiguredField( string value="", struct config={} ) {
		var variety    = "isIsNot";
		var varietyKey = isTrue( value ) ? "truthy" : "falsey";

		switch( config.variety ?: "" ) {
			case "hasHasNot":
			case "wasWasNot":
			case "willWillNot":
			case "allAny":
				variety = config.variety;
		}

		return translateResource( uri=_booleanVarietyMappings[ variety ][ varietyKey ] );
	}

}
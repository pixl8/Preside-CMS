/**
 * Handler for rules engine 'boolean type'
 *
 */
component {

	variables._booleanVarietyMappings = {
		  isIsNot        = { truthy="cms:rulesEngine.boolean.is"      , falsey="cms:rulesEngine.boolean.isNot"   }
		, hasHasNot      = { truthy="cms:rulesEngine.boolean.has"     , falsey="cms:rulesEngine.boolean.hasNot"  }
		, hasDoesNotHave = { truthy="cms:rulesEngine.boolean.posesses", falsey="cms:rulesEngine.boolean.doesNotPosess"  }
		, didDidNot      = { truthy="cms:rulesEngine.boolean.did"     , falsey="cms:rulesEngine.boolean.didNot"  }
		, doesDoesNot    = { truthy="cms:rulesEngine.boolean.does"    , falsey="cms:rulesEngine.boolean.doesNot" }
		, wasWasNot      = { truthy="cms:rulesEngine.boolean.was"     , falsey="cms:rulesEngine.boolean.wasNot"  }
		, willWillNot    = { truthy="cms:rulesEngine.boolean.will"    , falsey="cms:rulesEngine.boolean.willNot" }
		, areAreNot      = { truthy="cms:rulesEngine.boolean.are"     , falsey="cms:rulesEngine.boolean.areNot"  }
		, everNever      = { truthy="cms:rulesEngine.boolean.ever"    , falsey="cms:rulesEngine.boolean.never"   }
		, allAny         = { truthy="cms:rulesEngine.boolean.all"     , falsey="cms:rulesEngine.boolean.any"     }
	};

	private string function renderConfiguredField( string value="", struct config={} ) {
		var variety    = "isIsNot";
		var varietyKey = isTrue( value ) ? "truthy" : "falsey";

		if ( StructKeyExists( _booleanVarietyMappings, config.variety ?: "" ) ) {
			variety = config.variety;
		} else if ( Len( Trim( config.variety ?: "" ) ) ) {
			var translated = translateResource( uri=config.variety & "." & varietyKey, defaultValue="" );
			if ( translated.len() ) {
				return translated;
			}
		}

		return translateResource( uri=_booleanVarietyMappings[ variety ][ varietyKey ] );
	}

}
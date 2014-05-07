<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="test01_getRules_shouldReturnEmptyArray_whenNoRulesAdded" returntype="void">
		<cfscript>
			var ruleset = new preside.system.api.validation.RuleSet();
			var rules   = ruleset.getRules();

			super.assertEquals( [], _rulesetToArrayOfStructs( rules ) );
		</cfscript>
	</cffunction>

	<cffunction name="test02_addRule_shouldAppendRuleToRuleset" returntype="void">
		<cfscript>
			var ruleset = new preside.system.api.validation.RuleSet();
			var expected = [
				  { fieldName="fieldname"        , validator="required" , params={}                              , message=""                          , serverCondition="", clientCondition="" }
				, { fieldName="another_field"    , validator="email"    , params={ validDomains = ["gmail.com"] }, message=""                          , serverCondition="", clientCondition="" }
				, { fieldName="yet_another_field", validator="maxLength", params={ maxLength = 87 }              , message="{bundle:some.resource.key}", serverCondition="", clientCondition="" }
			];
			var rules = "";

			ruleset.addRule(
				  fieldName    = "fieldname"
				, validator = "required"
			);

			ruleset.addRule(
				  fieldName    = "another_field"
				, validator = "email"
				, params = { validDomains = ["gmail.com"] }
			);

			ruleset.addRule(
				  fieldName    = "yet_another_field"
				, validator = "maxLength"
				, params = { maxLength = 87 }
				, message = "{bundle:some.resource.key}"
			);

			rules = ruleset.getRules();
			super.assertEquals( expected, _rulesetToArrayOfStructs( rules ) );
		</cfscript>
	</cffunction>

	<cffunction name="test03_addRules_shouldLoadRules_whenRulesPassedIsArrayOfRules" returntype="void">
		<cfscript>
			var expected = [
				  { fieldName="fieldname"        , validator="required" , params={}                              , message=""                          , serverCondition="", clientCondition="" }
				, { fieldName="another_field"    , validator="email"    , params={ validDomains = ["gmail.com"] }, message=""                          , serverCondition="", clientCondition="" }
				, { fieldName="yet_another_field", validator="maxLength", params={ maxLength = 87 }              , message="{bundle:some.resource.key}", serverCondition="", clientCondition="" }
			];
			var ruleset = new preside.system.api.validation.RuleSet();
			var rules = "";

			ruleset.addRules( rules=expected );

			rules = ruleset.getRules();
			super.assertEquals( expected, _rulesetToArrayOfStructs( rules ) );
		</cfscript>
	</cffunction>

	<cffunction name="test04_addRules_shouldLoadRules_whenRulesPassedIsAJsonArrayOfRules" returntype="void">
		<cfscript>
			var expected = [
				  { fieldName="another_field"    , validator="email"    , params={ validDomains = ["gmail.com"] }, message=""                          , serverCondition="Len( Trim( ${fieldname} ) )", clientCondition="${fieldname}.val().length;" }
				, { fieldName="yet_another_field", validator="maxLength", params={ maxLength = 87 }              , message="{bundle:some.resource.key}", serverCondition="", clientCondition="" }
			];
			var ruleset = new preside.system.api.validation.RuleSet();
			var rules = "";

			ruleset.addRules( rules=SerializeJson( expected ) );

			rules = ruleset.getRules();
			super.assertEquals( expected, _rulesetToArrayOfStructs( rules ) );
		</cfscript>
	</cffunction>

	<cffunction name="test05_addRules_shouldLoadRules_whenRulesPassedIsFileContainingJsonArrayOfRules" returntype="void">
		<cfscript>
			var rules = "";
			var filePath = ListAppend( GetTempDirectory(), CreateUUId() );
			var ruleset = new preside.system.api.validation.RuleSet();
			var expected = [
				  { fieldName="another_field"    , validator="email"    , params={ validDomains = ["gmail.com"] }, message=""                          , serverCondition="", clientCondition="" }
				, { fieldName="yet_another_field", validator="maxLength", params={ maxLength = 87 }              , message="{bundle:some.resource.key}", serverCondition="Len( Trim( ${fieldname} ) )", clientCondition="${fieldname}.val().length;" }
			];

			FileWrite( filePath, SerializeJson( expected ) );

			ruleset.addRules( rules=filePath );

			rules = ruleset.getRules();

			super.assertEquals( expected, _rulesetToArrayOfStructs( rules ) );
		</cfscript>
	</cffunction>

	<cffunction name="test06_addRules_shouldThrowInformativeError_whenRulesPassedHaveBadOrMissingParameters" returntype="void">
		<cfscript>
			var errorThrown = false;
			var rules = [
				  { fieldName="another_field", validator="email", params={ validDomains = ["gmail.com"] }, message="" }
				, { fieldName={}, validator="maxLength", params={ maxLength = 87 }, message="{bundle:some.resource.key}" }
			];

			try {
				new preside.system.api.validation.RuleSet().addRules( rules=rules )
			} catch( "RuleSet.badRule" e ) {
				super.assertEquals( "Invalid rule. Please see the documentation on creating validation rulesets.", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test07_addRules_shouldThrowInformativeError_whenRulesPassedAreNeitherArrayNorSimpleValue" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				new preside.system.api.validation.RuleSet().addRules( rules={ fubar = "test" } )
			} catch( "RuleSet.badRuleset" e ) {
				super.assertEquals( "Invalid ruleset. Rulesets must be either an array of valid rules, a json string that deserializes to an array of valid rules or a path to a file containing such a json string.", e.message );
				super.assertEquals( "The following ruleset (serialized) was invalid: [#SerializeJson( { fubar = "test" } )#]", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test08_addRules_shouldThrowInformativeError_whenRulesPassedAreAStringThatIsNeitherAValidFilePathOrJsonString" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				new preside.system.api.validation.RuleSet().addRules( rules="invalidjson" )
			} catch( "RuleSet.badRuleset" e ) {
				super.assertEquals( "Invalid ruleset. Rulesets must be either an array of valid rules, a json string that deserializes to an array of valid rules or a path to a file containing such a json string.", e.message );
				super.assertEquals( "The following ruleset (serialized) was invalid: [#SerializeJson( "invalidjson" )#]", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test09_addRules_shouldThrowInformativeError_whenRulesPassedAreAValidFilePathThatDoesNotContainValidJson" returntype="void">
		<cfscript>
			var errorThrown = false;
			var filePath = ListAppend( GetTempDirectory(), CreateUUId() );

			FileWrite( filePath, "some invalid json here {}" );

			try {
				new preside.system.api.validation.RuleSet().addRules( rules=filePath )
			} catch( "RuleSet.badRuleset" e ) {
				super.assertEquals( "Invalid ruleset. Rulesets must be either an array of valid rules, a json string that deserializes to an array of valid rules or a path to a file containing such a json string.", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_rulesetToArrayOfStructs" access="private" returntype="array" output="false">
		<cfargument name="rules" type="array" required="true" />

		<cfscript>
			var arrOfStructs = [];
			var rule = "";

			for( rule in arguments.rules ){
				ArrayAppend( arrOfStructs, rule.getMemento() );
			}

			return arrOfStructs;
		</cfscript>
	</cffunction>
</cfcomponent>
<cfcomponent output="false" extends="mxunit.framework.TestCase">

	<cffunction name="test01_listBundles_shouldListAutomaticallyDiscoveredResourceBundles" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = [ "core.master", "secondary" ];
			var result     = rbService.listBundles();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_getResource_shouldLookupAndReturnResourceFromBaseBundle_whenNoLocaleInfoIsPassed" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "test resource value";
			var result     = rbService.getResource( "core.master:test.resource.key" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test03_getResource_shouldReturnEmptyString_whenKeyDoesNotExistInBundles" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var result     = rbService.getResource( "secondary:non.existant.key" );

			super.assertEquals( "", result );
		</cfscript>
	</cffunction>

	<cffunction name="test04_getResource_shouldReturnPassedDefaultValue_whenKeyDoesNotExistInBundles" returntype="void">
		<cfscript>
			var bundleDirs   = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService    = _getRBService( bundleDirs );
			var defaultValue = "some default";
			var result       = rbService.getResource( "secondary:non.existant.key", defaultValue );

			super.assertEquals( defaultValue, result );
		</cfscript>
	</cffunction>

	<cffunction name="test05_getResource_shouldReturnLanguageSpecificValue_whenLanguageSupplied" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "test resource value en";
			var result     = rbService.getResource( uri="core.master:test.resource.key", language="en" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test06_getResource_shouldReturnLocaleSpecificValue_whenLocaleSupplied" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "test resource value en uk";
			var result     = rbService.getResource( uri="core.master:test.resource.key", language="en", country="uk" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test07_getResource_shouldReturnKeyFromCoreBundle_whenKeyDoesNotExistInEitherCountryOrLanguageBundle" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "core bundle only";
			var result     = rbService.getResource( uri="core.master:core.only.key", language="en", country="US" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test08_getResource_shouldReturnKeyFromLanguageBundle_whenKeyDoesNotExistInCountryBundleButDoesExistInBothCoreAndLanguageBundles" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "I am from language";
			var result     = rbService.getResource( uri="core.master:core.and.language.only", language="en", country="US" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test09_getResource_shouldReturnKeyFromMaster_whenLanguageDoesNotExistAtAll" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "I am a value";
			var result     = rbService.getResource( uri="secondary:i.am.a.property", language="ar" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test10_getResource_shouldReturnKeyFromMaster_whenLanguageAndCountryDoNotExistAtAll" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "I am a value";
			var result     = rbService.getResource( uri="secondary:i.am.a.property", language="af", country="ZA" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test11_getResource_shouldReturnKeyFromLanguage_whenLanguageExistsButCountryDoesNot" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "Ceci n'est pas une pipe";
			var result     = rbService.getResource( uri="secondary:some.key", language="fr", country="CA" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test12_getResource_shouldGetResourcesMergedFromMultipleInputDirectories" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/", "/tests/resources/ResourceBundleService/testBundles2/", "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var result     = "";
			var expected   = "";

			// russian key, only in Bundle 3 (make sure your font can cope with russian if you're just seeing blocks!)
			expected = "Ад прё ёудико конжюль волумюч, нэ векж тальэ фюгит зюжкепиантюр, но декта лаборамюз ыюм. Пэр ан жанктюч зэнтынтиаэ, но глориатюр витюпырата зыд. Ан мыа выро пошжим докэндё, эю мыа ыёрмод молыжтйаы, ырант емпэтюсъ эа мэя. Йн зюаз обльйквюэ консэквюат дуо.";
			result   = rbService.getResource( "bundle3:core.and.language.only", "", "ru", "RU" );
			super.assertEquals( expected, result );

			// spanish key only in bundle 2
			expected = "scorchio! (dir 2)";
			result   = rbService.getResource( "core.master:test.resource.key", "", "es", "ES" );
			super.assertEquals( expected, result );

			// unique to dir 1
			expected = "I only live here";
			result   = rbService.getResource( "secondary:unique.to.dir1", "", "it", "IT" );
			super.assertEquals( expected, result );

			// in all three (we should get the value from bundle set 3)
			expected = "I am from language (dir 3)";
			result   = rbService.getResource( "core.master:core.and.language.only", "", "en" );
			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test13_getResource_shouldReturnDefaultValue_whenMalformedResourceUriPassed" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = CreateUUId();
			var result     = rbService.getResource( uri="malformed.resource.uri", defaultValue=expected );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test14_getResource_shouldReturnDefaultValue_whenBundleDoesNotExist" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "some default value here.";
			var result     = rbService.getResource( uri="nonExistantBundle:btn.ok", defaultValue=expected );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test15_listLocales_shouldReturnListOfAllSupportedLocalesAcrossAllBundles" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = [ "en", "it", "ru", "ru_RU" ];
			var result     = rbService.listLocales();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test16_listLocales_shouldReturnListOfLocalesForGivenResourceBundle" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = [ "it", "ru", "ru_RU" ];
			var result     = rbService.listLocales( bundle="bundle3" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test17_listLocales_shouldReturnEmptyList_whenProvidedBundleDoesNotExist" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = [];
			var result     = rbService.listLocales( bundle="someBundleThatDoesNotExist" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test18_getBundleAsJson_shouldReturnJsonRepresentationOfBundleForGivenLocale" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles3/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = '{"core.master:core.only.key":"core bundle only (dir 3)","core.master:test.resource.key":"test resource value en (dir 3)","core.master:core.and.language.only":"i am from language (dir 3)"}';
			var result     = rbService.getBundleAsJson( bundle="core.master", language="en", country="US" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test19_getResource_shouldNotReturnSiteTemplateSpecificValue_whenSiteTemplateIsNotActive" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/", "/tests/resources/ResourceBundleService/site-templates/test-template/i18n/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "This is not a pipe";
			var result     = rbService.getResource( "secondary:some.key" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test20_getResource_shouldReturnSiteTemplateSpecificValue_whenSiteTemplateIsActive" returntype="void">
		<cfscript>
			var bundleDirs = [ "/tests/resources/ResourceBundleService/testBundles/", "/tests/resources/ResourceBundleService/site-templates/test-template/i18n/" ];
			var rbService  = _getRBService( bundleDirs );
			var expected   = "Specific to site template";

			mockSiteService.$( "getActiveSiteTemplate", "test-template" );

			var result     = rbService.getResource( "secondary:some.key" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getRBService" access="private" returntype="any" output="false">
		<cfargument name="bundleDirectories" type="array" required="true" />

		<cfscript>
			mockSiteService = getMockBox().createEmptyMock( "preside.system.services.siteTree.SiteService" );
			mockSiteService.$( "getActiveSiteTemplate", "" );

			return new preside.system.services.i18n.ResourceBundleService( bundleDirectories = arguments.bundleDirectories, siteService=mockSiteService );
		</cfscript>
	</cffunction>

</cfcomponent>
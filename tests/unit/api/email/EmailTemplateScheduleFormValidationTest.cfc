component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "Validation rules generated from the email template schedule forms", function(){

			it( "should include a minimum value rule of 1 for the repeat measure in the repeat schedule validation form", function(){
				var rules       = _getRulesForForm( "repeat.schedule.form.for.validation.xml" );
				var measureRule = _findRule( rules, "schedule_measure", "min" );

				expect( measureRule ).notToBeEmpty();
				expect( measureRule.params.min ).toBe( 1 );
				expect( _findRule( rules, "schedule_measure", "required" ) ).notToBeEmpty();
			} );

			it( "should include a minimum value rule of 1 for the repeat measure in the repeat schedule clone form", function(){
				var rules       = _getRulesForForm( "admin.clone.repeat.schedule.xml" );
				var measureRule = _findRule( rules, "schedule_measure", "min" );

				expect( measureRule ).notToBeEmpty();
				expect( measureRule.params.min ).toBe( 1 );
			} );

			it( "should require both the repeat measure and the repeat unit in the repeat schedule clone form so that a scheduled repeat clone cannot be saved without them", function(){
				var rules = _getRulesForForm( "admin.clone.repeat.schedule.xml" );

				expect( _findRule( rules, "schedule_measure", "required" ) ).notToBeEmpty();
				expect( _findRule( rules, "schedule_unit", "required" ) ).notToBeEmpty();
			} );

			it( "should not apply a minimum value rule to the repeat measure in the general send options form so that a template holding a zero measure can still be switched to manual or fixed date", function(){
				var rules = _getRulesForForm( "configure.send.methods.xml" );

				expect( _findRule( rules, "schedule_measure", "min" ) ).toBeEmpty();
				expect( _findRule( rules, "schedule_measure", "range" ) ).toBeEmpty();
			} );

		} );

	}

	private array function _getRulesForForm( required string fileName ) {
		var formsService = _getFormsService();
		var filePath     = ExpandPath( "/preside/system/forms/preside-objects/email_template/" & arguments.fileName );

		makePublic( formsService, "_readForm" );

		var formDefinition = formsService._readForm( filePath=filePath, formName="preside-objects.email_template." & ListDeleteAt( arguments.fileName, ListLen( arguments.fileName, "." ), "." ) );

		return _getRuleGenerator().generateRulesFromPresideForm( formDefinition );
	}

	private struct function _findRule( required array rules, required string fieldName, required string validator ) {
		for( var rule in arguments.rules ) {
			if ( rule.fieldName == arguments.fieldName && rule.validator == arguments.validator ) {
				return rule;
			}
		}

		return {};
	}

	private any function _getFormsService() {
		var service = createMock( object=CreateObject( "preside.system.services.forms.FormsService" ) );

		service.$( "_getPresideObjectService", _getMockPresideObjectService() );

		return service;
	}

	private any function _getRuleGenerator() {
		var mockResourceBundleSvc = createEmptyMock( "preside.system.services.i18n.ResourceBundleService" );
		var mockInterceptorSvc    = createStub();

		mockResourceBundleSvc.$( "getResource", "" );
		mockInterceptorSvc.$( "processState" );

		return new preside.system.services.validation.PresideFieldRuleGenerator(
			  presideObjectService  = _getMockPresideObjectService()
			, logger                = _getTestLogger()
			, resourceBundleService = mockResourceBundleSvc
			, assetManagerService   = createEmptyMock( "preside.system.services.assetManager.AssetManagerService" )
			, interceptorService    = mockInterceptorSvc
		);
	}

	private any function _getMockPresideObjectService() {
		var mockPoService = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		var properties    = {
			  sending_method      = { name="sending_method"     , type="string" , dbtype="varchar" , maxlength=20, required=false, enum="emailSendingMethod" }
			, schedule_type       = { name="schedule_type"      , type="string" , dbtype="varchar" , maxlength=20, required=false, enum="emailSendingScheduleType" }
			, schedule_date       = { name="schedule_date"      , type="date"   , dbtype="datetime", required=false }
			, schedule_start_date = { name="schedule_start_date", type="date"   , dbtype="datetime", required=false }
			, schedule_end_date   = { name="schedule_end_date"  , type="date"   , dbtype="datetime", required=false }
			, schedule_unit       = { name="schedule_unit"      , type="string" , dbtype="varchar" , maxlength=20, required=false, enum="timeUnit" }
			, schedule_measure    = { name="schedule_measure"   , type="numeric", dbtype="int"     , required=false }
			, recipient_filter    = { name="recipient_filter"   , type="string" , dbtype="varchar" , required=false }
		};

		mockPoService.$( "objectExists", true );
		mockPoService.$( "getResourceBundleUriRoot", "preside-objects.email_template:" );
		mockPoService.$( "isOneToManyConfiguratorObject", false );

		for( var propertyName in properties ) {
			mockPoService.$( "fieldExists" ).$args( "email_template", propertyName ).$results( true );
			mockPoService.$( "getObjectProperty" ).$args( "email_template", propertyName ).$results( properties[ propertyName ] );
		}

		return mockPoService;
	}
}

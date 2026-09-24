component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "index()", function(){
			it( "should render every matching conditional label", function(){
				var renderer = CreateMock( object=new preside.system.handlers.renderers.content.CustomFieldConditionalLabel() );
				var service  = createStub();

				service.$( "evaluateConditionalLabels", [ "rule-1", "rule-2" ] );
				service.$( "getConditionalRuleById" ).$args( "rule-1" ).$results( { label_text="Red", colour="##ff0000" } );
				service.$( "getConditionalRuleById" ).$args( "rule-2" ).$results( { label_text="Blue", colour="##0000ff" } );
				renderer.$property( propertyName="customFieldsService", mock=service );
				renderer.$property( propertyName="customFieldBadgeService", mock=new preside.system.services.customFields.CustomFieldBadgeService() );

				var rendered = renderer.index( args={ data="15.record-1" } );

				expect( rendered ).toInclude( ">Red</span>" );
				expect( rendered ).toInclude( ">Blue</span>" );
			} );
		} );
	}

}

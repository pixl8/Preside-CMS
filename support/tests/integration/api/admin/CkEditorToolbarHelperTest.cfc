component extends="tests.resources.HelperObjects.PresideTestCase" output=false {

// SETUP, TEARDOWN, etc
	function setup() output=false {
		// mockSecurityService          = getMockBox().createEmptyMock( "preside.system.services.admin.SecurityService" );
		variables.configuredToolbars = { full = "test,-,config|here|/|oh,-,yes", notsofull = "not,very,full" };
		variables.toolbarHelper      = new preside.system.services.admin.CkEditorToolbarHelper(
			  configuredToolbars = configuredToolbars
			//, securityService    = mockSecurityService
		);
	}

// TESTS
	function test01_getToolbarDefinition_shouldReturnPassedDefinition_whenPassedDefinitionDoesNotMatchAnyRegisteredKeys(){
		// mockSecurityService.$( 'hasPermission', true );
		super.assertEquals( "testDefinition,here", toolbarHelper.getToolbarDefinition( "testDefinition,here" ) );
	}

	function test02_getToolbarDefinition_shouldReturnMatchedDefinition(){
		// mockSecurityService.$( 'hasPermission', true );
		super.assertEquals( configuredToolbars.notsofull, toolbarHelper.getToolbarDefinition( "notsofull" ) );
	}
/*
	function test03_getToolbarDefinition_shouldStripOutButtonsForWhichTheUserDoesNotHavePermission(){
		var expectedResult = "test|here";

		mockSecurityService.$( 'hasPermission' ).$args( permission="ckeditor.button.test"   ).$results( true  );
		mockSecurityService.$( 'hasPermission' ).$args( permission="ckeditor.button.config" ).$results( false );
		mockSecurityService.$( 'hasPermission' ).$args( permission="ckeditor.button.here"   ).$results( true  );
		mockSecurityService.$( 'hasPermission' ).$args( permission="ckeditor.button.oh"     ).$results( false );
		mockSecurityService.$( 'hasPermission' ).$args( permission="ckeditor.button.yes"    ).$results( false );

		super.assertEquals( expectedResult, toolbarHelper.getToolbarDefinition( "full" ) );
	};
*/
}
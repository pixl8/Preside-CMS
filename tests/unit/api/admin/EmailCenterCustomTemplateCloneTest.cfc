component extends="testbox.system.BaseSpec" {

	function run() {

		describe( "Cloning a custom email template from the email centre", function(){

			it( "should resolve the clone form through the email template clone form name customisation, the same way the clone page does", function(){
				var handler = _getHandler( validated=true );
				var event   = _getMockEvent( { name="Copy", subject="Subject" } );

				handler.cloneAction( event=event, rc={ id="template-1" }, prc={ record={ sending_method="scheduled", schedule_type="repeat" } } );

				var customizationCalls = _getCustomizationCalls( "getCloneRecordFormName" );

				expect( ArrayLen( customizationCalls ) ).toBe( 1 );
				expect( customizationCalls[ 1 ].objectName ).toBe( "email_template" );
				expect( customizationCalls[ 1 ].defaultHandler ).toBe( "admin.datamanager._getCloneRecordFormName" );
				expect( customizationCalls[ 1 ].args.objectName ?: "" ).toBe( "email_template" );
			} );

			it( "should collect and validate the posted data against the resolved clone form rather than the plain name and subject form", function(){
				var handler = _getHandler( validated=true );
				var event   = _getMockEvent( { name="Copy", subject="Subject", schedule_measure=3 } );

				handler.cloneAction( event=event, rc={ id="template-1" }, prc={ record={ sending_method="scheduled", schedule_type="repeat" } } );

				expect( _getArg( event.$callLog().getCollectionForForm[ 1 ], "formName", 1 ) ).toBe( variables.resolvedFormName );
				expect( _getArg( handler.$callLog().validateForm[ 1 ], "formName", 1 ) ).toBe( variables.resolvedFormName );
			} );

			it( "should pass the posted schedule values to the cloning service as a draft when validation succeeds", function(){
				var handler = _getHandler( validated=true );
				var event   = _getMockEvent( { name="Copy", subject="Subject", schedule_measure=3, schedule_unit="week" } );

				handler.cloneAction( event=event, rc={ id="template-1" }, prc={ record={ sending_method="scheduled", schedule_type="repeat" } } );

				var cloneCalls = variables.mockCloningService.$callLog().cloneRecord;

				expect( ArrayLen( cloneCalls ) ).toBe( 1 );
				expect( cloneCalls[ 1 ].objectName ).toBe( "email_template" );
				expect( cloneCalls[ 1 ].recordId ).toBe( "template-1" );
				expect( cloneCalls[ 1 ].isDraft ).toBeTrue();
				expect( cloneCalls[ 1 ].data.schedule_measure ).toBe( 3 );
				expect( cloneCalls[ 1 ].data.schedule_unit ).toBe( "week" );
			} );

			it( "should not clone and should send the posted values and validation result back to the clone page when validation fails", function(){
				var handler = _getHandler( validated=false );
				var event   = _getMockEvent( { name="Copy", subject="Subject", schedule_measure=0 } );

				handler.cloneAction( event=event, rc={ id="template-1" }, prc={ record={ sending_method="scheduled", schedule_type="repeat" } } );

				var redirects = handler.$callLog().setNextEvent;

				expect( ArrayLen( variables.mockCloningService.$callLog().cloneRecord ) ).toBe( 0 );
				expect( ArrayLen( redirects ) ).toBe( 1 );
				expect( redirects[ 1 ].url ).toBe( "/admin/emailcenter/customTemplates/clone/" );
				expect( redirects[ 1 ].persistStruct.schedule_measure ).toBe( 0 );
				expect( StructKeyExists( redirects[ 1 ].persistStruct, "validationResult" ) ).toBeTrue();
			} );

		} );

	}

	private any function _getHandler( required boolean validated ) {
		var handler          = createMock( "preside.system.handlers.admin.emailCenter.CustomTemplates" );
		var validationResult = createStub();

		variables.resolvedFormName       = "preside-objects.email_template.admin.clone.merged.with.repeat";
		variables.mockCustomizationSvc   = createStub();
		variables.mockCloningService     = createStub();
		variables.mockMessageBox         = createStub();

		mockCustomizationSvc.$( "runCustomization", variables.resolvedFormName );
		mockCloningService.$( "cloneRecord", "new-template-id" );
		mockMessageBox.$( "info" );
		mockMessageBox.$( "error" );
		validationResult.$( "validated", arguments.validated );

		handler.$property( propertyName="customizationService", mock=mockCustomizationSvc );
		handler.$property( propertyName="cloningService"      , mock=mockCloningService   );
		handler.$property( propertyName="messageBox"          , mock=mockMessageBox       );
		handler.$( "_checkPermissions" );
		handler.$( "_getTemplate" );
		handler.$( "validateForm", validationResult );
		handler.$( "translateResource", "" );
		handler.$( "setNextEvent" );

		return handler;
	}

	private any function _getMockEvent( required struct formData ) {
		var mockEvent = createStub();

		mockEvent.$( "getCollectionForForm", Duplicate( arguments.formData ) );
		mockEvent.$( "audit" );
		mockEvent.$( "buildAdminLink" ).$args( linkTo="emailcenter.customTemplates.clone", queryString="id=template-1" ).$results( "/admin/emailcenter/customTemplates/clone/" );
		mockEvent.$( "buildAdminLink" ).$args( linkTo="emailcenter.customTemplates.preview", queryString="id=new-template-id" ).$results( "/admin/emailcenter/customTemplates/preview/" );

		return mockEvent;
	}

	private array function _getCustomizationCalls( required string action ) {
		var calls = [];

		for( var callArgs in variables.mockCustomizationSvc.$callLog().runCustomization ) {
			if ( ( callArgs.action ?: "" ) == arguments.action ) {
				ArrayAppend( calls, callArgs );
			}
		}

		return calls;
	}

	private any function _getArg( required struct callArgs, required string name, required numeric position ) {
		if ( StructKeyExists( arguments.callArgs, arguments.name ) ) {
			return arguments.callArgs[ arguments.name ];
		}

		return arguments.callArgs[ arguments.position ] ?: "";
	}
}

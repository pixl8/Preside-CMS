component extends="testbox.system.BaseSpec" {

	function run() {

		describe( "auditDataManagerAddRecord()", function(){

			it( "should run the datamanager add record audit action", function(){
				_setupHelpers();

				auditDataManagerAddRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" } );

				expect( _getRunEventCall().event ).toBe( "admin.datamanager._addRecordActionAudit" );
			} );

			it( "should run the audit action privately and exempt from pre/post handlers", function(){
				_setupHelpers();

				auditDataManagerAddRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" } );

				var runEventCall = _getRunEventCall();

				expect( runEventCall.private       ).toBeTrue();
				expect( runEventCall.prePostExempt ).toBeTrue();
			} );

			it( "should translate the objectName argument to the object argument expected by the handler", function(){
				_setupHelpers();

				auditDataManagerAddRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" } );

				var eventArguments = _getRunEventCall().eventArguments;

				expect( eventArguments.object ).toBe( "my_object" );
				expect( eventArguments.keyExists( "objectName" ) ).toBeFalse();
			} );

			it( "should pass through the record id and form data untouched", function(){
				_setupHelpers();

				auditDataManagerAddRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" } );

				var eventArguments = _getRunEventCall().eventArguments;

				expect( eventArguments.recordId ).toBe( "record-1" );
				expect( eventArguments.formData ).toBe( { label="Test record" } );
			} );

			it( "should not pass through arguments that were never supplied, so that handler defaults apply", function(){
				_setupHelpers();

				auditDataManagerAddRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" } );

				var eventArguments = _getRunEventCall().eventArguments;

				expect( eventArguments.keyExists( "auditAction" ) ).toBeFalse();
				expect( eventArguments.keyExists( "auditType"   ) ).toBeFalse();
				expect( eventArguments.keyExists( "formName"    ) ).toBeFalse();
				expect( eventArguments.keyExists( "isDraft"     ) ).toBeFalse();
			} );

			it( "should default the object name to the object of the current datamanager request", function(){
				_setupHelpers( prc={ objectName="object_from_prc" } );

				auditDataManagerAddRecord( recordId="record-1", formData={ label="Test record" } );

				expect( _getRunEventCall().eventArguments.object ).toBe( "object_from_prc" );
			} );

			it( "should default drafts enabled to the setting of the current datamanager request", function(){
				_setupHelpers( prc={ objectName="my_object", draftsEnabled=true } );

				auditDataManagerAddRecord( recordId="record-1", formData={ label="Test record" } );

				expect( _getRunEventCall().eventArguments.draftsEnabled ).toBeTrue();
			} );

			it( "should preserve an explicitly disabled drafts argument even when the current request has drafts enabled", function(){
				_setupHelpers( prc={ objectName="my_object", draftsEnabled=true } );

				auditDataManagerAddRecord( recordId="record-1", formData={ label="Test record" }, draftsEnabled=false );

				expect( _getRunEventCall().eventArguments.draftsEnabled ).toBeFalse();
			} );

			it( "should throw an informative error when no object name can be resolved", function(){
				_setupHelpers();

				expect( function(){
					auditDataManagerAddRecord( recordId="record-1", formData={ label="Test record" } );
				} ).toThrow( type="datamanager.audit.missing.objectname" );
			} );

		} );

		describe( "auditDataManagerEditRecord()", function(){

			it( "should run the datamanager edit record audit action", function(){
				_setupHelpers();

				auditDataManagerEditRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" } );

				expect( _getRunEventCall().event ).toBe( "admin.datamanager._editRecordActionAudit" );
			} );

			it( "should pass the draft status through to the handler", function(){
				_setupHelpers( prc={ draftsEnabled=true } );

				auditDataManagerEditRecord( objectName="my_object", recordId="record-1", formData={ label="Test record" }, isDraft=true );

				var eventArguments = _getRunEventCall().eventArguments;

				expect( eventArguments.draftsEnabled ).toBeTrue();
				expect( eventArguments.isDraft       ).toBeTrue();
			} );

			it( "should throw an informative error when no object name can be resolved", function(){
				_setupHelpers();

				expect( function(){
					auditDataManagerEditRecord( recordId="record-1", formData={ label="Test record" } );
				} ).toThrow( type="datamanager.audit.missing.objectname" );
			} );

		} );

	}

// PRIVATE HELPERS
	private void function _setupHelpers( struct prc={} ) {
		include "/preside/system/helpers/booleanUtils.cfm";
		include "/preside/system/helpers/datamanagerAuditHelpers.cfm";

		var mockRequestContext = createStub();

		mockRequestContext.$( "getCollection", arguments.prc );

		variables.mockController = createStub();
		variables.mockController.$( "getRequestContext", mockRequestContext );
		variables.mockController.$( "runEvent" );
	}

	private any function getController() {
		return variables.mockController;
	}

	private struct function _getRunEventCall( numeric callNumber=1 ) {
		var callLog = variables.mockController.$callLog().runEvent;

		expect( callLog.len() ).toBeGTE( arguments.callNumber, "Expected runEvent() to have been called at least [#arguments.callNumber#] time(s)" );

		return callLog[ arguments.callNumber ];
	}

}

component extends="testbox.system.BaseSpec" {

	function run() {

		describe( "_addRecordActionAudit()", function(){

			it( "should audit with the standard add action when drafts are not enabled", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addRecordActionAudit(
					  event    = mockEvent
					, object   = "my_object"
					, recordId = "record-1"
					, formData = { label="Test record" }
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_add_record" );
			} );

			it( "should audit with the draft add action when drafts are enabled and the record is a draft", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, draftsEnabled = true
					, isDraft       = true
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_add_draft_record" );
			} );

			it( "should audit with the standard add action when drafts are enabled but the record is published", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, draftsEnabled = true
					, isDraft       = false
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_add_record" );
			} );

			it( "should use an explicitly supplied audit action in preference to the calculated one", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, auditAction   = "my_custom_add_action"
					, draftsEnabled = true
					, isDraft       = true
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "my_custom_add_action" );
			} );

		} );

		describe( "_editRecordActionAudit()", function(){

			it( "should audit with the standard edit action when drafts are not enabled", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._editRecordActionAudit(
					  event    = mockEvent
					, object   = "my_object"
					, recordId = "record-1"
					, formData = { label="Test record" }
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_edit_record" );
			} );

			it( "should ignore the draft status when drafts are not enabled", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._editRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, draftsEnabled = false
					, isDraft       = true
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_edit_record" );
			} );

			it( "should audit with the save draft action when drafts are enabled and the record is a draft", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._editRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, draftsEnabled = true
					, isDraft       = true
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_save_draft_record" );
			} );

			it( "should audit with the publish action when drafts are enabled and the record is published", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._editRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, draftsEnabled = true
					, isDraft       = false
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "datamanager_publish_record" );
			} );

			it( "should use an explicitly supplied audit action in preference to the calculated one", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._editRecordActionAudit(
					  event         = mockEvent
					, object        = "my_object"
					, recordId      = "record-1"
					, formData      = { label="Test record" }
					, auditAction   = "my_custom_edit_action"
					, draftsEnabled = true
					, isDraft       = true
				);

				expect( _getAuditCall( mockEvent ).action ).toBe( "my_custom_edit_action" );
			} );

		} );

		describe( "_addEditRecordActionAudit()", function(){

			it( "should audit against the supplied record id", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addEditRecordActionAudit(
					  event       = mockEvent
					, object      = "my_object"
					, recordId    = "record-1"
					, auditAction = "datamanager_add_record"
					, formData    = { label="Test record" }
				);

				expect( _getAuditCall( mockEvent ).recordId ).toBe( "record-1" );
			} );

			it( "should include the object name and record id in the audit detail alongside the form data", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addEditRecordActionAudit(
					  event       = mockEvent
					, object      = "my_object"
					, recordId    = "record-1"
					, auditAction = "datamanager_add_record"
					, formData    = { label="Test record" }
				);

				expect( _getAuditCall( mockEvent ).detail ).toBe( {
					  objectName = "my_object"
					, id         = "record-1"
					, label      = "Test record"
				} );
			} );

			it( "should use the supplied audit type", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addEditRecordActionAudit(
					  event       = mockEvent
					, object      = "my_object"
					, recordId    = "record-1"
					, auditAction = "datamanager_add_record"
					, auditType   = "myCustomType"
					, formData    = { label="Test record" }
				);

				expect( _getAuditCall( mockEvent ).type ).toBe( "myCustomType" );
			} );

			it( "should default the audit type to datamanager", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addEditRecordActionAudit(
					  event       = mockEvent
					, object      = "my_object"
					, recordId    = "record-1"
					, auditAction = "datamanager_add_record"
					, formData    = { label="Test record" }
				);

				expect( _getAuditCall( mockEvent ).type ).toBe( "datamanager" );
			} );

			it( "should not audit at all when auditing is disabled", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addEditRecordActionAudit(
					  event       = mockEvent
					, object      = "my_object"
					, recordId    = "record-1"
					, auditAction = "datamanager_add_record"
					, audit       = false
					, formData    = { label="Test record" }
				);

				expect( mockEvent.$callLog().audit.len() ).toBe( 0 );
			} );

			it( "should collect the form data from the supplied form name when no form data is passed", function(){
				var mockEvent = _getMockEvent();

				_getHandler()._addEditRecordActionAudit(
					  event       = mockEvent
					, object      = "my_object"
					, recordId    = "record-1"
					, auditAction = "datamanager_add_record"
					, formName    = "preside-objects.my_object.admin.add"
				);

				expect( mockEvent.$callLog().getCollectionForForm[ 1 ].formName ).toBe( "preside-objects.my_object.admin.add" );
				expect( _getAuditCall( mockEvent ).detail.label ).toBe( "Collected from form" );
			} );

			it( "should throw an informative error when neither form data nor a form name is supplied", function(){
				expect( function(){
					_getHandler()._addEditRecordActionAudit(
						  event       = _getMockEvent()
						, object      = "my_object"
						, recordId    = "record-1"
						, auditAction = "datamanager_add_record"
					);
				} ).toThrow( type="datamanager.audit.missing.formdata" );
			} );

		} );

	}

// PRIVATE HELPERS
	private any function _getHandler() {
		var handler = createMock( "preside.system.handlers.admin.DataManager" );

		makePublic( handler, "_addRecordActionAudit"     );
		makePublic( handler, "_editRecordActionAudit"    );
		makePublic( handler, "_addEditRecordActionAudit" );

		return handler;
	}

	private any function _getMockEvent() {
		var mockEvent = createStub();

		mockEvent.$( "audit" );
		mockEvent.$( "getCollectionForForm", { label="Collected from form" } );

		return mockEvent;
	}

	private struct function _getAuditCall( required any mockEvent, numeric callNumber=1 ) {
		var callLog = arguments.mockEvent.$callLog().audit;

		expect( callLog.len() ).toBeGTE( arguments.callNumber, "Expected event.audit() to have been called at least [#arguments.callNumber#] time(s)" );

		return callLog[ arguments.callNumber ];
	}

}

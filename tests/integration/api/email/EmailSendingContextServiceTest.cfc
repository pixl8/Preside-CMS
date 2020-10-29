component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getContextPayload()", function(){
			it( "should return an empty structure when no context has been set for the request", function(){
				var service = _getService();

				expect( service.getContextPayload() ).toBe( {} );
			} );

			it( "should return the result of a call to getting data for the set recipient type and recipient ID", function(){
				var service       = _getService();
				var recipientType = CreateUUId();
				var recipientId   = CreateUUId();
				var filterObject  = "some_object";
				var record        = QueryNew( 'id,label', 'varchar,varchar', [ [ CreateUUId(), CreateUUId() ] ] );
				var expectedPayload = {};

				for( var r in record ) {
					expectedPayload = { "#filterObject#"=r };
				}

				mockRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( filterObject );
				mockPresideObjectService.$( "selectData" ).$args(
					  objectName = filterObject
					, id         = recipientId
				).$results( record );

				service.setContext( recipientType=recipientType, recipientId=recipientId );
				expect( service.getContextPayload() ).toBe( expectedPayload );
			} );

			it( "should return an empty struct when the set recipient type does not have a source filter object", function(){
				var service       = _getService();
				var recipientType = CreateUUId();
				var recipientId   = CreateUUId();
				var filterObject  = "";
				var expectedPayload = {};

				mockRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( filterObject );

				service.setContext( recipientType=recipientType, recipientId=recipientId );
				expect( service.getContextPayload() ).toBe( expectedPayload );
			} );

			it( "should return an empty struct when no matching record found", function(){
				var service       = _getService();
				var recipientType = CreateUUId();
				var recipientId   = CreateUUId();
				var filterObject  = "some_object";

				mockRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( filterObject );
				mockPresideObjectService.$( "selectData" ).$args(
					  objectName = filterObject
					, id         = recipientId
				).$results( QueryNew('') );

				service.setContext( recipientType=recipientType, recipientId=recipientId );
				expect( service.getContextPayload() ).toBe( {} );
			} );
		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		mockRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockPresideObjectService = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );

		var service = createMock( object=new preside.system.services.email.EmailSendingContextService(
			recipientTypeService = mockRecipientTypeService
		) );

		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$announceInterception" );

		return service;
	}
}
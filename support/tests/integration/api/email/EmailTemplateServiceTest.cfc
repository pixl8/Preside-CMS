component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "saveTemplate()", function(){
			it( "should insert a new record when no ID is supplied", function(){
				var service  = _getService();
				var id       = CreateUUId();
				var template = {
					  name      = "Some template"
					, layout    = "default"
					, subject   = "Reset password instructions"
					, html_body = CreateUUId()
					, text_body = CreateUUId()
				};

				mockTemplateDao.$( "insertData" ).$args( data=template ).$results( id );

				expect( service.saveTemplate( template=template ) ).toBe( id );
			} );

			it( "should update a record when ID is supplied", function(){
				var service  = _getService();
				var id       = CreateUUId();
				var template = {
					  name      = "Some template"
					, layout    = "default"
					, subject   = "Reset password instructions"
					, html_body = CreateUUId()
					, text_body = CreateUUId()
				};

				mockTemplateDao.$( "insertData", CreateUUId() );
				mockTemplateDao.$( "updateData", 1 );

				expect( service.saveTemplate( id=id, template=template ) ).toBe( id );
				expect( mockTemplateDao.$callLog().insertData.len() ).toBe( 0 );
				expect( mockTemplateDao.$callLog().updateData.len() ).toBe( 1 );

				expect( mockTemplateDao.$callLog().updateData[1] ).toBe({
					  id   = id
					, data = template
				});
			} );

			it( "should insert a record when ID is supplied but update fails to update any records", function(){
				var service  = _getService();
				var id       = CreateUUId();
				var template = {
					  name      = "Some template"
					, layout    = "default"
					, subject   = "Reset password instructions"
					, html_body = CreateUUId()
					, text_body = CreateUUId()
				};

				var insertDataArgs = Duplicate( template );
				insertDataArgs.id = id;

				mockTemplateDao.$( "insertData" ).$args( data=insertDataArgs ).$results( id );
				mockTemplateDao.$( "updateData", 0 );

				expect( service.saveTemplate( id=id, template=template ) ).toBe( id );
				expect( mockTemplateDao.$callLog().insertData.len() ).toBe( 1 );
				expect( mockTemplateDao.$callLog().updateData.len() ).toBe( 1 );

				expect( mockTemplateDao.$callLog().updateData[1] ).toBe({
					  id   = id
					, data = template
				});
			} );
		} );

		describe( "init()", function(){
			it( "should populate template records for any system email templates that do not already have a record in the DB", function(){
				var service = _getService( initialize=false );
				var systemTemplates = [ { id="t1", title="Template 1" }, { id="t2", title="Template 2" }, { id="t3", title="Template 3" } ];

				mockSystemEmailTemplateService.$( "listTemplates", systemTemplates );
				service.$( "saveTemplate", CreateUUId() );
				for( var t in systemTemplates ){
					service.$( "templateExists" ).$args( t.id ).$results( t.id == "t2" );
					mockSystemEmailTemplateService.$( "getDefaultLayout" ).$args( t.id ).$results( t.id & "layout" );
					mockSystemEmailTemplateService.$( "getDefaultSubject" ).$args( t.id ).$results( t.id & "subject" );
					mockSystemEmailTemplateService.$( "getDefaultHtmlBody" ).$args( t.id ).$results( t.id & "html" );
					mockSystemEmailTemplateService.$( "getDefaultTextBody" ).$args( t.id ).$results( t.id & "text" );
				}

				service.init( systemEmailTemplateService = mockSystemEmailTemplateService );

				expect( service.$callLog().saveTemplate.len() ).toBe( 2 );
				expect( service.$callLog().saveTemplate[1] ).toBe( {
					  id = "t1"
					, template = {
						  name      = "Template 1"
						, layout    = "t1layout"
						, subject   = "t1subject"
						, html_body = "t1html"
						, text_body = "t1text"
					}
				} );
				expect( service.$callLog().saveTemplate[2] ).toBe( {
					  id = "t3"
					, template = {
						  name      = "Template 3"
						, layout    = "t3layout"
						, subject   = "t3subject"
						, html_body = "t3html"
						, text_body = "t3text"
					}
				} );
			} );
		} );

	}

	private any function _getService( boolean initialize=true ) {
		var service = createMock( object=CreateObject( "preside.system.services.email.EmailTemplateService" ) );

		mockTemplateDao = createStub();
		service.$( "$getPresideObject" ).$args( "email_template" ).$results( mockTemplateDao );
		mockSystemEmailTemplateService = createEmptyMock( "preside.system.services.email.SystemEmailTemplateService" );

		if ( arguments.initialize ) {
			service.$( "_ensureSystemTemplatesHaveDbEntries" );
			service.init(
				systemEmailTemplateService = mockSystemEmailTemplateService
			);
		}

		return service;
	}
}
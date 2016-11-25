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

				mockTemplateDao.$( "insertData" ).$args( data=template, isDraft=false ).$results( id );

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
					  id      = id
					, data    = template
					, isDraft = false
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

				mockTemplateDao.$( "insertData" ).$args( data=insertDataArgs, isDraft=false ).$results( id );
				mockTemplateDao.$( "updateData", 0 );

				expect( service.saveTemplate( id=id, template=template ) ).toBe( id );
				expect( mockTemplateDao.$callLog().insertData.len() ).toBe( 1 );
				expect( mockTemplateDao.$callLog().updateData.len() ).toBe( 1 );

				expect( mockTemplateDao.$callLog().updateData[1] ).toBe({
					  id      = id
					, data    = template
					, isDraft = false
				});
			} );

			it( "should insert a draft when 'saveDraft' is passed as true", function(){
				var service  = _getService();
				var id       = CreateUUId();
				var template = {
					  name      = "Some template"
					, layout    = "default"
					, subject   = "Reset password instructions"
					, html_body = CreateUUId()
					, text_body = CreateUUId()
				};

				mockTemplateDao.$( "insertData" ).$args( data=template, isDraft=true ).$results( id );

				expect( service.saveTemplate( template=template, isDraft=true ) ).toBe( id );
			} );

			it( "should make a draft update when 'saveDraft' is passed as true (for an existing template)", function(){
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

				expect( service.saveTemplate( id=id, template=template, isDraft=true ) ).toBe( id );
				expect( mockTemplateDao.$callLog().insertData.len() ).toBe( 0 );
				expect( mockTemplateDao.$callLog().updateData.len() ).toBe( 1 );

				expect( mockTemplateDao.$callLog().updateData[1] ).toBe({
					  id      = id
					, data    = template
					, isDraft = true
				});
			} );

		} );

		describe( "init()", function(){
			it( "should populate template records for any system email templates that do not already have a record in the DB", function(){
				var service = _getService( initialize=false );
				var recipientType = CreateUUId();
				var systemTemplates = [ { id="t1", title="Template 1" }, { id="t2", title="Template 2" }, { id="t3", title="Template 3" } ];

				mockSystemEmailTemplateService.$( "listTemplates", systemTemplates );
				service.$( "saveTemplate", CreateUUId() );
				for( var t in systemTemplates ){
					service.$( "templateExists" ).$args( t.id ).$results( t.id == "t2" );
					mockSystemEmailTemplateService.$( "getDefaultLayout" ).$args( t.id ).$results( t.id & "layout" );
					mockSystemEmailTemplateService.$( "getDefaultSubject" ).$args( t.id ).$results( t.id & "subject" );
					mockSystemEmailTemplateService.$( "getDefaultHtmlBody" ).$args( t.id ).$results( t.id & "html" );
					mockSystemEmailTemplateService.$( "getDefaultTextBody" ).$args( t.id ).$results( t.id & "text" );
					mockSystemEmailTemplateService.$( "getRecipientType" ).$args( t.id ).$results( recipientType );
				}

				service.init(
					  systemEmailTemplateService = mockSystemEmailTemplateService
					, emailRecipientTypeService  = mockEmailRecipientTypeService
					, emailLayoutService         = mockEmailLayoutService
					, emailLoggingService        = mockEmailLoggingService
				);

				expect( service.$callLog().saveTemplate.len() ).toBe( 2 );
				expect( service.$callLog().saveTemplate[1] ).toBe( {
					  id = "t1"
					, template = {
						  name            = "Template 1"
						, layout          = "t1layout"
						, subject         = "t1subject"
						, html_body       = "t1html"
						, text_body       = "t1text"
						, recipient_type  = recipientType
						, is_system_email = true
					}
				} );
				expect( service.$callLog().saveTemplate[2] ).toBe( {
					  id = "t3"
					, template = {
						  name            = "Template 3"
						, layout          = "t3layout"
						, subject         = "t3subject"
						, html_body       = "t3html"
						, text_body       = "t3text"
						, recipient_type  = recipientType
						, is_system_email = true
					}
				} );
			} );
		} );

		describe( "getTemplate()", function(){
			it( "should return the DB record for the given template converted to a struct", function(){
				var service    = _getService();
				var template   = CreateUUId();
				var mockResult = QueryNew( 'blah', 'varchar', [[CreateUUId()]]);
				var expected   = {};

				for( var r in mockResult ) { expected = r; }

				mockTemplateDao.$( "selectData" ).$args( id=template, allowDraftVersions=false, fromversionTable=false, specificVersion=0 ).$results( mockResult );

				expect( service.getTemplate( template ) ).toBe( expected );
			} );

			it( "should return the _draft_ DB record for the given template converted to a struct when allowDrafts is set to true", function(){
				var service    = _getService();
				var template   = CreateUUId();
				var mockResult = QueryNew( 'blah', 'varchar', [[CreateUUId()]]);
				var expected   = {};

				for( var r in mockResult ) { expected = r; }

				mockTemplateDao.$( "selectData" ).$args( id=template, allowDraftVersions=true, fromversionTable=true, specificVersion=0 ).$results( mockResult );

				expect( service.getTemplate( id=template, allowDrafts=true ) ).toBe( expected );
			} );

			it( "should return the specific version DB record for the given template when a specific version id is passed", function(){
				var service    = _getService();
				var template   = CreateUUId();
				var mockResult = QueryNew( 'blah', 'varchar', [[CreateUUId()]]);
				var version    = 3498;
				var expected   = {};

				for( var r in mockResult ) { expected = r; }

				mockTemplateDao.$( "selectData" ).$args(
					  id                 = template
					, allowDraftVersions = false
					, fromversionTable   = true
					, specificVersion    = version
				).$results( mockResult );

				expect( service.getTemplate( id=template, version=version ) ).toBe( expected );
			} );
		} );

		describe( "replaceParameterTokens()", function(){
			it( "it should replace all occurrences of param tokens (${param}) with the supplied params, using the appropriate html/text version of the param according to the passed type", function(){
				var service = _getService();
				var raw     = "${param1} was a ${param2} which was ${param1} and very ${param3}. Indeed! ${param4}";
				var type    = "text";
				var params  = {
					  param1 = { html="html 1", text="text1" }
					, param2 = "just text"
					, param3 = { html="html 3", text="text 3" }
				};

				expect( service.replaceParameterTokens(
					  text   = raw
					, params = params
					, type   = type
				) ).toBe( "text1 was a just text which was text1 and very text 3. Indeed! ${param4}" );
			} );
		} );

		describe( "prepareParameters()", function(){
			it( "should combine prepared parameters from system email template + recipient type (when template is system type)", function(){
				var service        = _getService();
				var template       = "eventBookingConfirmation";
				var recipientType  = "websiteUser";
				var mockArgs       = { userId=CreateUUId(), bookingId=CreateUUId() };
				var sysEmailParams = { eventName="My event", bookingSummary=CreateUUId() };
				var recipientTypeParams = { known_as="Harry" };
				var finalParams         = Duplicate( sysEmailParams );

				finalParams.append( recipientTypeParams );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockSystemEmailTemplateService.$( "prepareParameters" ).$args( template=template, args=mockArgs ).$results( sysEmailParams );
				mockEmailRecipientTypeService.$( "prepareParameters" ).$args( recipientType=recipientType, args=mockArgs ).$results( recipientTypeParams );

				expect( service.prepareParameters(
					  template      = template
					, recipientType = recipientType
					, args          = mockArgs
				) ).toBe( finalParams );
			} );
		} );

		describe( "getPreviewParameters()", function(){
			it( "should combine preview parameters from system email template + recipient type (when template is system type)", function(){
				var service             = _getService();
				var template            = "eventBookingConfirmation";
				var recipientType       = "websiteUser";
				var sysEmailParams      = { eventName="My event", bookingSummary=CreateUUId() };
				var recipientTypeParams = { known_as="Harry" };
				var finalParams         = Duplicate( sysEmailParams );

				finalParams.append( recipientTypeParams );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockSystemEmailTemplateService.$( "getPreviewParameters" ).$args( template=template ).$results( sysEmailParams );
				mockEmailRecipientTypeService.$( "getPreviewParameters" ).$args( recipientType=recipientType ).$results( recipientTypeParams );

				expect( service.getPreviewParameters(
					  template      = template
					, recipientType = recipientType
				) ).toBe( finalParams );
			} );
		} );

		describe( "prepareMessage()", function(){
			it( "should build a message by fetching template from DB, substiting prepared params and adding system email template attachments", function() {
				var service                = _getService();
				var template               = "mytemplate";
				var mockSubject            = CreateUUId();
				var mockMessageId          = CreateUUId();
				var mockTo                 = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockArgs               = { userId = CreateUUId(), bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var mockTemplate           = {
					  layout         = "testLayout"
					, recipient_type = "testRecipientType"
					, subject        = "Test subject"
					, from_address   = "From address"
					, html_body      = "HTML BODY HERE"
					, text_body      = "TEXT BODY OH YEAH"
				};

				service.$( "getTemplate" ).$args( template ).$results( mockTemplate );
				service.$( "prepareParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
					, args          = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.text_body, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.html_body, mockParams, "html" ).$results( mockHtmlBody );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, type          = "text"
					, subject       = mockSubject
					, body          = mockTextBody
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, type          = "html"
					, subject       = mockSubject
					, body          = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, args=mockArgs ).$results( mockTo );

				mockEmailLoggingService.$( "createEmailLog" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
					, recipient     = mockTo
					, sender        = mockTemplate.from_address
					, subject       = mockSubject
					, sendArgs      = mockArgs
				).$results( mockMessageId );

				expect( service.prepareMessage( template=template, args=mockArgs ) ).toBe( {
					  subject   = mockSubject
					, from      = mockTemplate.from_address
					, to        = [ mockTo ]
					, textBody  = mockTextBodyWithLayout
					, htmlBody  = mockHtmlBodyWithLayout
					, cc        = []
					, bcc       = []
					, params    = {}
					, messageId = mockMessageId
				} );
			} );

			it( "should use default from address when template from address is empty", function() {
				var service                = _getService();
				var template               = "mytemplate";
				var mockSubject            = CreateUUId();
				var mockTo                 = CreateUUId();
				var mockFrom               = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockArgs               = { userId = CreateUUId(), bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var mockTemplate           = {
					  layout         = "testLayout"
					, recipient_type = "testRecipientType"
					, subject        = "Test subject"
					, from_address   = ""
					, html_body      = "HTML BODY HERE"
					, text_body      = "TEXT BODY OH YEAH"
				};

				service.$( "getTemplate" ).$args( template ).$results( mockTemplate );
				service.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( mockFrom );
				service.$( "prepareParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
					, args          = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.text_body, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.html_body, mockParams, "html" ).$results( mockHtmlBody );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, type          = "text"
					, subject       = mockSubject
					, body          = mockTextBody
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, type          = "html"
					, subject       = mockSubject
					, body          = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, args=mockArgs ).$results( mockTo );

				expect( service.prepareMessage( template=template, args=mockArgs ) ).toBe( {
					  subject  = mockSubject
					, from     = mockFrom
					, to       = [ mockTo ]
					, textBody = mockTextBodyWithLayout
					, htmlBody = mockHtmlBodyWithLayout
					, cc       = []
					, bcc      = []
					, params   = {}
					, messageId = "testMessageId"
				} );
			} );

			it( "should throw an informative error when the email template is not found", function(){
				var service     = _getService();
				var template    = CreateUUId();
				var errorThrown = false;

				service.$( "getTemplate" ).$args( template ).$results( {} );

				try {
					service.prepareMessage( template, {} );
				} catch( "preside.emailtemplateservice.missing.template" e ) {
					expect( e.message ).toBe( "The email template, [#template#], could not be found." );
					errorThrown = true;
				}

				expect( errorThrown ).toBe( true );
			} );
		} );

		describe( "previewTemplate()", function(){
			it( "should return a struct with html body, text body, subject retrieved from the DB and mixed in with 'preview parameters' from recipient type and system template type + finally wrapped in layout", function(){
				var service                = _getService();
				var template               = "mytemplate";
				var mockSubject            = CreateUUId();
				var mockTo                 = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockArgs               = { userId = CreateUUId(), bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var version                = 49545;
				var mockTemplate           = {
					  layout         = "testLayout"
					, recipient_type = "testRecipientType"
					, subject        = "Test subject"
					, from_address   = "From address"
					, html_body      = "HTML BODY HERE"
					, text_body      = "TEXT BODY OH YEAH"
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=true, version=version ).$results( mockTemplate );
				service.$( "getPreviewParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.text_body, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.html_body, mockParams, "html" ).$results( mockHtmlBody );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, type          = "text"
					, subject       = mockSubject
					, body          = mockTextBody
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, type          = "html"
					, subject       = mockSubject
					, body          = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				expect( service.previewTemplate( template=template, allowDrafts=true, version=version ) ).toBe( {
					  subject  = mockSubject
					, textBody = mockTextBodyWithLayout
					, htmlBody = mockHtmlBodyWithLayout
				} );
			} );
		} );

		describe( "listMissingParams()", function(){
			it( "should return an empty array when content contains all required params for the given template", function(){
				var service                 = _getService();
				var content                 = "${dummy} ${test} right here";
				var templateId              = "mytemplate";
				var mockTemplateParams      = [ { id="test", required=true } ];
				var mockRecipientTypeParams = [ { id="dummy", required=true }, { id="another", required=false } ];
				var mockTemplate            = { recipient_type="test" };

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true ).$results( mockTemplate );
				mockEmailRecipientTypeService.$( "listRecipientTypeParameters" ).$args( mockTemplate.recipient_type ).$results( mockRecipientTypeParams );
				mockSystemEmailTemplateService.$( "templateExists" ).$args( templateId ).$results( true );
				mockSystemEmailTemplateService.$( "listTemplateParameters" ).$args( templateId ).$results( mockTemplateParams );

				expect( service.listMissingParams( content=content, template=templateId ) ).toBe( [] );
			} );

			it( "should return an array of all the parameters that are missing for the given template", function(){
				var service                 = _getService();
				var content                 = "blah blah ${another} blah";
				var templateId              = "mytemplate";
				var mockTemplateParams      = [ { id="test", required=true } ];
				var mockRecipientTypeParams = [ { id="dummy", required=true }, { id="another", required=false } ];
				var mockTemplate            = { recipient_type="test" };

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true ).$results( mockTemplate );
				mockEmailRecipientTypeService.$( "listRecipientTypeParameters" ).$args( mockTemplate.recipient_type ).$results( mockRecipientTypeParams );
				mockSystemEmailTemplateService.$( "templateExists" ).$args( templateId ).$results( true );
				mockSystemEmailTemplateService.$( "listTemplateParameters" ).$args( templateId ).$results( mockTemplateParams );

				expect( service.listMissingParams( content=content, template=templateId ) ).toBe( [ "${test}", "${dummy}" ] );
			} );

			it( "should return an empty array when the template is not found", function(){
				var service                 = _getService();
				var content                 = "blah blah ${another} blah";
				var templateId              = "mytemplate";
				var mockTemplate            = {};

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true ).$results( mockTemplate );

				expect( service.listMissingParams( content=content, template=templateId ) ).toBe( [] );
			} );
		} );

	}

	private any function _getService( boolean initialize=true ) {
		var service = createMock( object=CreateObject( "preside.system.services.email.EmailTemplateService" ) );

		mockTemplateDao = createStub();
		service.$( "$getPresideObject" ).$args( "email_template" ).$results( mockTemplateDao );
		service.$( "$audit" );
		mockSystemEmailTemplateService = createEmptyMock( "preside.system.services.email.SystemEmailTemplateService" );
		mockEmailRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockEmailLayoutService = createEmptyMock( "preside.system.services.email.EmailLayoutService" );
		mockEmailLoggingService = createEmptyMock( "preside.system.services.email.EmailLoggingService" );

		mockSystemEmailTemplateService.$( "templateExists", false );
		mockEmailLoggingService.$( "createEmailLog", "testMessageId" );

		if ( arguments.initialize ) {
			service.$( "_ensureSystemTemplatesHaveDbEntries" );
			service.init(
				  systemEmailTemplateService = mockSystemEmailTemplateService
				, emailRecipientTypeService  = mockEmailRecipientTypeService
				, emailLayoutService         = mockEmailLayoutService
				, emailLoggingService        = mockEmailLoggingService
			);
		}

		return service;
	}
}
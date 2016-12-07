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

		describe( "updateScheduledSendFields()", function(){
			it( "should empty the 'schedule_date' and 'schedule_sent' field when the schedule type is 'repeat'", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "ww", 1, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 1
					, schedule_unit           = "week"
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_date ).toBe( "" );
				expect( service.$callLog().saveTemplate[1].template.schedule_sent ).toBe( "" );
			} );

			it( "should not touch the repeating schedule fields when schedule type is repeat", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "ww", 1, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 1
					, schedule_unit           = "week"
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.keyExists( "schedule_type" ) ).toBe( false );
				expect( service.$callLog().saveTemplate[1].template.keyExists( "schedule_measure" ) ).toBe( false );
				expect( service.$callLog().saveTemplate[1].template.keyExists( "schedule_unit" ) ).toBe( false );
				expect( service.$callLog().saveTemplate[1].template.keyExists( "schedule_start_date" ) ).toBe( false );
				expect( service.$callLog().saveTemplate[1].template.keyExists( "schedule_end_date" ) ).toBe( false );
			} );

			it( "should set the schedule_next_send_date field when the schedule type is 'repeat' and next_send_date is empty", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "ww", 1, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 1
					, schedule_unit           = "week"
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( nextSendDate );

			} );

			it( "should set the schedule_next_send_date field when the schedule type is 'repeat' and next_send_date is in the past", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 2, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 2
					, schedule_unit           = "day"
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = DateAdd( "ww", -1, nowish )
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( nextSendDate );

			} );

			it( "should set the schedule_next_send_date field when the schedule type is 'repeat' and next_send_date later than newly calculated send date", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 3, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 3
					, schedule_unit           = "day"
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = DateAdd( "ww", 4, nowish )
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( nextSendDate );

			} );

			it( "should not set the schedule_next_send_date field when the schedule type is 'repeat' and next_send_date is in the future and earlier than newly calculated send date", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 3, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 3
					, schedule_unit           = "day"
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = DateAdd( "d", 2, nowish )
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.keyExists( "schedule_next_send_date" ) ).toBe( false );

			} );

			it( "should set the schedule_next_send_date to empty when schedule start date is in the future", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 3, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 3
					, schedule_unit           = "day"
					, schedule_start_date     = DateAdd( "ww", 1, nowish )
					, schedule_end_date       = ""
					, schedule_next_send_date = DateAdd( "ww", 4, nowish )
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( "" );
			} );

			it( "should set the schedule_next_send_date to empty when schedule end date is in the past", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 3, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 3
					, schedule_unit           = "day"
					, schedule_start_date     = DateAdd( "ww", -2, nowish )
					, schedule_end_date       = DateAdd( "ww", -1, nowish )
					, schedule_next_send_date = DateAdd( "ww", 4, nowish )
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( "" );
			} );

			it( "should set the schedule_next_send_date to empty when type is not 'repeat", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 3, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "fixeddate"
					, schedule_date           = Now()
					, schedule_measure        = ""
					, schedule_unit           = ""
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( "" );
			} );

			it( "should set the schedule_next_send_date field relative to the schedule_start_date", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var startDate    = "1900-01-01 09:00";
				var nextSendDate = DateAdd( "d", DateDiff( "d", startDate, nowish )+1, startDate );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 1
					, schedule_unit           = "day"
					, schedule_start_date     = startDate
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( nextSendDate );

			} );

			it( "should set all schedule fields to empty when method is not 'scheduled", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 3, nowish );
				var template = {
					  sending_method          = "manual"
					, schedule_type           = ""
					, schedule_date           = Now()
					, schedule_measure        = ""
					, schedule_unit           = ""
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template ).toBe( {
					  schedule_type           = ""
					, schedule_date           = ""
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_unit           = ""
					, schedule_measure        = ""
					, schedule_sent           = ""
					, schedule_next_send_date = ""
				} );
			} );

			it( "should clear all the repeating schedule fields when the schedule type is 'fixeddate'", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "fixeddate"
					, schedule_measure        = ""
					, schedule_date           = DateAdd( "ww", 1, nowish )
					, schedule_unit           = ""
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_start_date ).toBe( "" );
				expect( service.$callLog().saveTemplate[1].template.schedule_end_date ).toBe( "" );
				expect( service.$callLog().saveTemplate[1].template.schedule_unit ).toBe( "" );
				expect( service.$callLog().saveTemplate[1].template.schedule_measure ).toBe( "" );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ).toBe( "" );
			} );

			it( "it should mark as sent, when type is fixeddate and markAsSent passed as true", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "fixeddate"
					, schedule_measure        = ""
					, schedule_date           = DateAdd( "ww", 1, nowish )
					, schedule_unit           = ""
					, schedule_start_date     = ""
					, schedule_end_date       = ""
					, schedule_next_send_date = ""
				};

				service.$( "getTemplate" ).$args( templateId ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId=templateId, markAsSent=true );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_sent ).toBe( true );
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
					, emailSendingContextService = mockEmailSendingContextService
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

			it( "should return recipient_type, filter and layout fields from the template's blueprint when the template has a non-empty blueprint", function(){
				var service       = _getService();
				var template      = CreateUUId();
				var mockResult    = QueryNew( 'email_blueprint', 'varchar', [[CreateUUId()]]);
				var mockBlueprint = QueryNew( 'recipient_type,layout,recipient_filter', 'varchar,varchar,varchar', [[CreateUUId(),CreateUUId(),CreateUUId()]]);
				var expected      = {
					  email_blueprint  = mockResult.email_blueprint
					, recipient_type   = mockBlueprint.recipient_type
					, layout           = mockBlueprint.layout
					, blueprint_filter = mockBlueprint.recipient_filter
				};

				mockTemplateDao.$( "selectData" ).$args( id=template, allowDraftVersions=false, fromversionTable=false, specificVersion=0 ).$results( mockResult );
				mockBlueprintDao.$( "selectData" ).$args( id=mockResult.email_blueprint ).$results( mockBlueprint );

				expect( service.getTemplate( template ) ).toBe( expected );
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
				var service             = _getService();
				var template            = "eventBookingConfirmation";
				var recipientType       = "websiteUser";
				var recipientId         = CreateUUId();
				var mockArgs            = { userId=CreateUUId(), bookingId=CreateUUId() };
				var sysEmailParams      = { eventName="My event", bookingSummary=CreateUUId() };
				var recipientTypeParams = { known_as="Harry" };
				var finalParams         = Duplicate( sysEmailParams );

				finalParams.append( recipientTypeParams );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockSystemEmailTemplateService.$( "prepareParameters" ).$args( template=template, args=mockArgs ).$results( sysEmailParams );
				mockEmailRecipientTypeService.$( "prepareParameters" ).$args( recipientType=recipientType, recipientId=recipientId, args=mockArgs ).$results( recipientTypeParams );

				expect( service.prepareParameters(
					  template      = template
					, recipientType = recipientType
					, recipientId   = recipientId
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
				var mockTo                 = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockHtmlBodyRendered   = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockRecipientId        = CreateUUId();
				var mockArgs               = { bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var mockTemplate           = {
					  layout          = "testLayout"
					, recipient_type  = "testRecipientType"
					, subject         = "Test subject"
					, from_address    = "From address"
					, html_body       = "HTML BODY HERE"
					, text_body       = "TEXT BODY OH YEAH"
					, email_blueprint = CreateUUId()
				};

				service.$( "getTemplate" ).$args( template ).$results( mockTemplate );
				service.$( "prepareParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
					, recipientId   = mockRecipientId
					, args          = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.text_body, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.html_body, mockParams, "html" ).$results( mockHtmlBody );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockHtmlBody, context="email"  ).$results( mockHtmlBodyRendered );
				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, blueprint     = mockTemplate.email_blueprint
					, type          = "text"
					, subject       = mockSubject
					, body          = mockTextBody
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, blueprint     = mockTemplate.email_blueprint
					, type          = "html"
					, subject       = mockSubject
					, body          = mockHtmlBodyRendered
				).$results( mockHtmlBodyWithLayout );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId ).$results( mockTo );

				expect( service.prepareMessage( template=template, recipientId=mockRecipientId, args=mockArgs ) ).toBe( {
					  subject   = mockSubject
					, from      = mockTemplate.from_address
					, to        = [ mockTo ]
					, textBody  = mockTextBodyWithLayout
					, htmlBody  = mockHtmlBodyWithLayout
					, cc        = []
					, bcc       = []
					, params    = {}
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
				var mockRecipientId        = CreateUUId();
				var mockArgs               = { bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var mockTemplate           = {
					  layout          = "testLayout"
					, recipient_type  = "testRecipientType"
					, subject         = "Test subject"
					, from_address    = ""
					, html_body       = "HTML BODY HERE"
					, text_body       = "TEXT BODY OH YEAH"
					, email_blueprint = CreateUUId()
				};

				service.$( "getTemplate" ).$args( template ).$results( mockTemplate );
				service.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( mockFrom );
				service.$( "prepareParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
					, recipientId   = mockRecipientId
					, args          = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.text_body, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.html_body, mockParams, "html" ).$results( mockHtmlBody );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockHtmlBody, context="email"  ).$results( mockHtmlBody );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, blueprint     = mockTemplate.email_blueprint
					, type          = "text"
					, subject       = mockSubject
					, body          = mockTextBody
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, blueprint     = mockTemplate.email_blueprint
					, type          = "html"
					, subject       = mockSubject
					, body          = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId ).$results( mockTo );

				expect( service.prepareMessage( template=template, recipientId=mockRecipientId, args=mockArgs ) ).toBe( {
					  subject  = mockSubject
					, from     = mockFrom
					, to       = [ mockTo ]
					, textBody = mockTextBodyWithLayout
					, htmlBody = mockHtmlBodyWithLayout
					, cc       = []
					, bcc      = []
					, params   = {}
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

			it( "should set and clear the email sending context so that any dynamic content that is rendered can have access to the relevant recipient context", function(){
				var service                = _getService();
				var template               = "mytemplate";
				var mockRecipientId        = CreateUUId();
				var mockTemplate           = {
					  layout          = "testLayout"
					, recipient_type  = "testRecipientType"
					, subject         = "Test subject"
					, from_address    = "From address"
					, html_body       = "HTML BODY HERE"
					, text_body       = "TEXT BODY OH YEAH"
					, email_blueprint = CreateUUId()
				};

				service.$( "getTemplate", mockTemplate );
				service.$( "prepareParameters", {} )
				service.$( "replaceParameterTokens", CreateUUId() );
				service.$( "replaceParameterTokens", CreateUUId() );
				service.$( "replaceParameterTokens", CreateUUId() );
				service.$( "$renderContent", CreateUUId() );
				mockSystemEmailTemplateService.$( "templateExists", true );
				mockEmailLayoutService.$( "renderLayout", CreateUUId() );
				mockEmailLayoutService.$( "renderLayout", CreateUUId() );
				mockEmailRecipientTypeService.$( "getToAddress", CreateUUId() );

				service.prepareMessage( template=template, recipientId=mockRecipientId, args={} );

				expect( mockEmailSendingContextService.$callLog().setContext.len() ).toBe( 1 );
				expect( mockEmailSendingContextService.$callLog().setContext[ 1 ] ).toBe( { recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId } );
				expect( mockEmailSendingContextService.$callLog().clearContext.len() ).toBe( 1 );
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
				var mockHtmlBodyRendered   = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockArgs               = { userId = CreateUUId(), bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var version                = 49545;
				var mockTemplate           = {
					  layout          = "testLayout"
					, recipient_type  = "testRecipientType"
					, subject         = "Test subject"
					, from_address    = "From address"
					, html_body       = "HTML BODY HERE"
					, text_body       = "TEXT BODY OH YEAH"
					, email_blueprint = CreateUUId()
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=true, version=version ).$results( mockTemplate );
				service.$( "getPreviewParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.text_body, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.html_body, mockParams, "html" ).$results( mockHtmlBody );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockHtmlBody, context="email" ).$results( mockHtmlBodyRendered );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, blueprint     = mockTemplate.email_blueprint
					, type          = "text"
					, subject       = mockSubject
					, body          = mockTextBody
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout        = mockTemplate.layout
					, emailTemplate = template
					, blueprint     = mockTemplate.email_blueprint
					, type          = "html"
					, subject       = mockSubject
					, body          = mockHtmlBodyRendered
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

		describe( "listDueOneTimeScheduleTemplates()", function(){
			it( "should fetch all the templates using 'fixeddate' schedule who have not been sent and who's send date is in the past", function(){
				var service = _getService();
				var templateRecords = QueryNew( 'id', 'varchar', [[CreateUUId()], [CreateUUId()]] );
				var nowish = Now();

				service.$( "_getNow", nowish );
				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "id" ]
					, filter       = { sending_method="scheduled", schedule_type="fixeddate", schedule_sent=false }
					, extraFilters = [ { filter="schedule_date <= :schedule_date", filterParams={ schedule_date=nowish } } ]
					, orderby      = "schedule_date"
				).$results( templateRecords );

				expect( service.listDueOneTimeScheduleTemplates() ).toBe( ValueArray( templateRecords.id ) );
			} );
		} );

		describe( "listDueRepeatedScheduleTemplates()", function(){
			it( "should fetch all the templates using 'repeat' schedule who's next send date is in the past and when current date is between start and end date", function(){
				var service = _getService();
				var templateRecords = QueryNew( 'id', 'varchar', [[CreateUUId()], [CreateUUId()]] );
				var nowish = Now();

				service.$( "_getNow", nowish );
				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "id" ]
					, filter       = { sending_method="scheduled", schedule_type="repeat" }
					, extraFilters = [ { filter="schedule_next_send_date <= :schedule_next_send_date", filterParams={ schedule_next_send_date=nowish } } ]
					, orderby      = "schedule_next_send_date"
				).$results( templateRecords );

				expect( service.listDueRepeatedScheduleTemplates() ).toBe( ValueArray( templateRecords.id ) );
			} );
		} );

	}

	private any function _getService( boolean initialize=true ) {
		var service = createMock( object=CreateObject( "preside.system.services.email.EmailTemplateService" ) );

		mockTemplateDao = createStub();
		mockBlueprintDao = createStub();
		service.$( "$getPresideObject" ).$args( "email_template" ).$results( mockTemplateDao );
		service.$( "$getPresideObject" ).$args( "email_blueprint" ).$results( mockBlueprintDao );
		service.$( "$audit" );
		mockSystemEmailTemplateService = createEmptyMock( "preside.system.services.email.SystemEmailTemplateService" );
		mockEmailRecipientTypeService = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockEmailLayoutService = createEmptyMock( "preside.system.services.email.EmailLayoutService" );
		mockEmailSendingContextService = createEmptyMock( "preside.system.services.email.EmailSendingContextService" );

		mockSystemEmailTemplateService.$( "templateExists", false );
		mockEmailSendingContextService.$( "setContext" );
		mockEmailSendingContextService.$( "clearContext" );

		if ( arguments.initialize ) {
			service.$( "_ensureSystemTemplatesHaveDbEntries" );
			service.init(
				  systemEmailTemplateService = mockSystemEmailTemplateService
				, emailRecipientTypeService  = mockEmailRecipientTypeService
				, emailLayoutService         = mockEmailLayoutService
				, emailSendingContextService = mockEmailSendingContextService
			);
		}

		return service;
	}
}
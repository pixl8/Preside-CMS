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

				mockTemplateDao.$( "insertData" ).$args( data=template, isDraft=false, insertManyToManyRecords=true ).$results( id );

				expect( service.saveTemplate( template=template ) ).toBe( id );
			} );

			it( "should default the sending method to 'manual' when using a blueprint that has a recipient type tied to an object (not anonymous)", function(){
				var service       = _getService();
				var id            = CreateUUId();
				var blueprint     = CreateUUId();
				var recipientType = CreateUUId();
				var template      = {
					  name            = "Some template"
					, layout          = "default"
					, subject         = "Reset password instructions"
					, html_body       = CreateUUId()
					, text_body       = CreateUUId()
					, email_blueprint = blueprint
				};

				mockBluePrintDao.$( "selectData" ).$args( id=blueprint ).$results( QueryNew( "recipient_type", "varchar", [[recipientType]]) );
				mockTemplateDao.$( "insertData", id );
				mockEmailRecipientTypeService.$( "getFilterObjectForRecipientType" ).$args( recipientType ).$results( "someobject" );

				service.saveTemplate( template=template );
				expect( mockTemplateDao.$callLog().insertData[1].data.sending_method ?: "" ).toBe( "manual" );
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
					  id                      = id
					, data                    = template
					, isDraft                 = false
					, forceVersionCreation    = false
					, updateManyToManyRecords = true
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
					  id                      = id
					, data                    = template
					, isDraft                 = false
					, forceVersionCreation    = false
					, updateManyToManyRecords = true
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

				mockTemplateDao.$( "insertData" ).$args( data=template, isDraft=true, insertManyToManyRecords=true ).$results( id );

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
					  id                      = id
					, data                    = template
					, isDraft                 = true
					, forceVersionCreation    = false
					, updateManyToManyRecords = true
				});
			} );

			it( "should make a forced update when 'saveDraft' is passed as false and 'forcePublication' is passed as true (for an existing template)", function(){
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

				expect( service.saveTemplate( id=id, template=template, isDraft=false, forcePublication=true ) ).toBe( id );
				expect( mockTemplateDao.$callLog().insertData.len() ).toBe( 0 );
				expect( mockTemplateDao.$callLog().updateData.len() ).toBe( 1 );

				expect( mockTemplateDao.$callLog().updateData[1] ).toBe({
					  id                      = id
					, data                    = template
					, isDraft                 = false
					, forceVersionCreation    = true
					, updateManyToManyRecords = true
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
					, schedule_date           = ""
					, schedule_sent           = ""
				};

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
				service.$( "saveTemplate").$args( template=template, id=templateId , isDraft=true ).$results( templateId );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_next_send_date ?: "" ).toBe( nextSendDate );

			} );

			it( "should set the schedule_next_send_date field when the schedule type is 'repeat' and next_send_date is right now", function(){
				var service      = _getService();
				var templateId   = CreateUUId();
				var nowish       = Now();
				var nextSendDate = DateAdd( "d", 2, nowish );
				var template = {
					  sending_method          = "scheduled"
					, schedule_type           = "repeat"
					, schedule_measure        = 2
					, schedule_unit           = "day"
					, schedule_start_date     = DateAdd( "d", -4, nowish )
					, schedule_end_date       = ""
					, schedule_next_send_date = nowish
				};

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
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

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId=templateId, markAsSent=true );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_sent ).toBe( true );
			} );

			it( "it should mark the email as not sent, when type is fixeddate, scheduled date is in the future and is sent is set to true", function(){
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
					, schedule_sent           = true
				};

				service.$( "getTemplate" ).$args( id=templateId, allowDrafts=true, fromVersionTable=false ).$results( template );
				service.$( "saveTemplate", templateId );
				service.$( "_getNow", nowish );

				service.updateScheduledSendFields( templateId=templateId );

				expect( service.$callLog().saveTemplate.len() ).toBe( 1 );
				expect( service.$callLog().saveTemplate[1].id ?: "" ).toBe( templateId );
				expect( service.$callLog().saveTemplate[1].template.schedule_sent ?: "" ).toBe( false );
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
					, assetManagerService        = mockAssetManagerService
					, emailStyleInliner          = mockEmailStyleInliner
					, emailSettings              = mockEmailSettings
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

				mockTemplateDao.$( "selectData" ).$args( id=template, allowDraftVersions=false, fromversionTable=false, specificVersion=0, useCache=false ).$results( mockResult );

				expect( service.getTemplate( template ) ).toBe( expected );
			} );

			it( "should return the _draft_ DB record for the given template converted to a struct when allowDrafts is set to true", function(){
				var service    = _getService();
				var template   = CreateUUId();
				var mockResult = QueryNew( 'blah', 'varchar', [[CreateUUId()]]);
				var expected   = {};

				for( var r in mockResult ) { expected = r; }

				mockTemplateDao.$( "selectData" ).$args( id=template, allowDraftVersions=true, fromversionTable=true, specificVersion=0, useCache=false ).$results( mockResult );

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
					, useCache           = false
				).$results( mockResult );

				expect( service.getTemplate( id=template, version=version ) ).toBe( expected );
			} );

			it( "should return recipient_type, filter, service_provider and layout fields from the template's blueprint when the template has a non-empty blueprint", function(){
				var service       = _getService();
				var template      = CreateUUId();
				var mockResult    = QueryNew( 'email_blueprint', 'varchar', [[CreateUUId()]]);
				var mockBlueprint = QueryNew( 'recipient_type,layout,recipient_filter,service_provider', 'varchar,varchar,varchar,varchar', [[CreateUUId(),CreateUUId(),CreateUUId(),CreateUUId()]]);
				var expected      = {
					  email_blueprint  = mockResult.email_blueprint
					, recipient_type   = mockBlueprint.recipient_type
					, layout           = mockBlueprint.layout
					, blueprint_filter = mockBlueprint.recipient_filter
					, service_provider = mockBlueprint.service_provider
				};

				mockTemplateDao.$( "selectData" ).$args( id=template, allowDraftVersions=false, fromversionTable=false, specificVersion=0, useCache=false ).$results( mockResult );
				mockBlueprintDao.$( "selectData" ).$args( id=mockResult.email_blueprint ).$results( mockBlueprint );

				expect( service.getTemplate( template ) ).toBe( expected );
			} );
		} );

		describe( "replaceParameterTokens()", function(){
			it( "it should replace all occurrences of param tokens (${param}) with the supplied params, using the appropriate html/text version of the param according to the passed type", function(){
				var service = _getService();
				var raw     = "${param1} was a ${param2} which was ${param1} and very ${param3}. indeed! ${param4}";
				var type    = "text";
				var params  = {
					  param1 = { html="html 1", text="İtext1" }
					, param2 = "just text"
					, param3 = { html="html 3", text="text 3" }
				};

				expect( service.replaceParameterTokens(
					  text   = raw
					, params = params
					, type   = type
				) ).toBe( "İtext1 was a just text which was İtext1 and very text 3. indeed! ${param4}" );
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
				var templateDetail      = { test="template", whatever=CreateUUId() };
				var finalParams         = Duplicate( sysEmailParams );

				finalParams.append( recipientTypeParams );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockSystemEmailTemplateService.$( "prepareParameters" ).$args( template=template, templateDetail=templateDetail, args=mockArgs ).$results( sysEmailParams );
				mockEmailRecipientTypeService.$( "prepareParameters" ).$args( recipientType=recipientType, recipientId=recipientId, template=template, templateDetail=templateDetail, args=mockArgs ).$results( recipientTypeParams );

				expect( service.prepareParameters(
					  template       = template
					, recipientType  = recipientType
					, recipientId    = recipientId
					, args           = mockArgs
					, templateDetail = templateDetail
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
				var mockHtmlBodyWithStyles = CreateUUId();
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
					, view_online     = false
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=false ).$results( mockTemplate );
				service.$( "prepareParameters" ).$args(
					  template       = template
					, recipientType  = mockTemplate.recipient_type
					, recipientId    = mockRecipientId
					, templateDetail = mockTemplate
					, args           = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockTemplate.html_body, context="email"  ).$results( mockHtmlBody );

				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "text"
					, subject        = mockSubject
					, body           = mockTemplate.text_body
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "html"
					, subject        = mockSubject
					, body           = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				service.$( "replaceParameterTokens" ).$args( mockTextBodyWithLayout, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockHtmlBodyWithLayout, mockParams, "html" ).$results( mockHtmlBodyRendered );
				service.$( "getAttachments", [] );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailStyleInliner.$( "inlineStyles" ).$args( mockHtmlBodyRendered ).$results( mockHtmlBodyWithStyles );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId ).$results( mockTo );

				expect( service.prepareMessage( template=template, recipientId=mockRecipientId, args=mockArgs ) ).toBe( {
					  subject     = mockSubject
					, from        = mockTemplate.from_address
					, to          = [ mockTo ]
					, textBody    = mockTextBody
					, htmlBody    = mockHtmlBodyWithStyles
					, cc          = []
					, bcc         = []
					, params      = {}
					, attachments = []
				} );
			} );

			it( "should use default from address when template from address is empty", function() {
				var service                = _getService();
				var template               = "mytemplate";
				var mockSubject            = CreateUUId();
				var mockTo                 = CreateUUId();
				var mockFrom               = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockHtmlBodyRendered   = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithStyles = CreateUUId();
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
					, view_online     = false
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=false ).$results( mockTemplate );
				service.$( "$getPresideSetting" ).$args( "email", "default_from_address" ).$results( mockFrom );
				service.$( "prepareParameters" ).$args(
					  template       = template
					, recipientType  = mockTemplate.recipient_type
					, recipientId    = mockRecipientId
					, templateDetail = mockTemplate
					, args           = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockTemplate.html_body, context="email"  ).$results( mockHtmlBody );

				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "text"
					, subject        = mockSubject
					, body           = mockTemplate.text_body
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "html"
					, subject        = mockSubject
					, body           = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				service.$( "replaceParameterTokens" ).$args( mockTextBodyWithLayout, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockHtmlBodyWithLayout, mockParams, "html" ).$results( mockHtmlBodyRendered );
				service.$( "getAttachments", [] );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailStyleInliner.$( "inlineStyles" ).$args( mockHtmlBodyRendered ).$results( mockHtmlBodyWithStyles );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId ).$results( mockTo );

				expect( service.prepareMessage( template=template, recipientId=mockRecipientId, args=mockArgs ) ).toBe( {
					  subject     = mockSubject
					, from        = mockFrom
					, to          = [ mockTo ]
					, textBody    = mockTextBody
					, htmlBody    = mockHtmlBodyWithStyles
					, cc          = []
					, bcc         = []
					, params      = {}
					, attachments = []
				} );
			} );

			it( "should throw an informative error when the email template is not found", function(){
				var service     = _getService();
				var template    = CreateUUId();
				var errorThrown = false;

				service.$( "getTemplate" ).$args( id=template, allowDrafts=false ).$results( {} );

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
					, view_online     = false
				};

				service.$( "getTemplate", mockTemplate );
				service.$( "prepareParameters", {} )
				service.$( "getAttachments", [] );
				service.$( "replaceParameterTokens", CreateUUId() );
				service.$( "replaceParameterTokens", CreateUUId() );
				service.$( "replaceParameterTokens", CreateUUId() );
				service.$( "$renderContent", CreateUUId() );
				mockSystemEmailTemplateService.$( "templateExists", true );
				mockEmailLayoutService.$( "renderLayout", CreateUUId() );
				mockEmailLayoutService.$( "renderLayout", CreateUUId() );
				mockEmailRecipientTypeService.$( "getToAddress", CreateUUId() );
				mockEmailStyleInliner.$( "inlineStyles", CreateUUId() );

				service.prepareMessage( template=template, recipientId=mockRecipientId, args={} );

				expect( mockEmailSendingContextService.$callLog().setContext.len() ).toBe( 1 );
				expect( mockEmailSendingContextService.$callLog().setContext[ 1 ] ).toBe( { recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId, templateId=template, template=mockTemplate } );
				expect( mockEmailSendingContextService.$callLog().clearContext.len() ).toBe( 1 );
			} );

			it( "should build a view online link and pass to layout when 'view online' is set to true for the template", function(){
				var service                        = _getService();
				var template                       = "mytemplate";
				var mockSubject                    = CreateUUId();
				var mockTo                         = CreateUUId();
				var mockTextBody                   = CreateUUId();
				var mockTextBodyWithLayout         = CreateUUId();
				var mockHtmlBody                   = CreateUUId();
				var mockHtmlBodyRendered           = CreateUUId();
				var mockHtmlBodyWithLayout         = CreateUUId();
				var mockHtmlBodyWithStyles         = CreateUUId();
				var mockRecipientId                = CreateUUId();
				var viewOnlineLink                 = CreateUUId();
				var mockHtmlWithViewOnline         = CreateUUId();
				var mockHtmlWithViewOnlineRendered = CreateUUId();
				var mockArgs                       = { bookingId = CreateUUId() };
				var mockParams                     = { test=CreateUUId(), params=Now() };
				var mockTemplate                   = {
					  layout          = "testLayout"
					, recipient_type  = "testRecipientType"
					, subject         = "Test subject"
					, from_address    = "From address"
					, html_body       = "HTML BODY HERE"
					, text_body       = "TEXT BODY OH YEAH"
					, email_blueprint = CreateUUId()
					, view_online     = true
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=false ).$results( mockTemplate );
				service.$( "prepareParameters" ).$args(
					  template       = template
					, recipientType  = mockTemplate.recipient_type
					, recipientId    = mockRecipientId
					, templateDetail = mockTemplate
					, args           = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockTemplate.html_body, context="email"  ).$results( mockHtmlBody );

				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "text"
					, subject        = mockSubject
					, body           = mockTemplate.text_body
					, viewOnlineLink = viewOnlineLink
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "html"
					, subject        = mockSubject
					, body           = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				service.$( "replaceParameterTokens" ).$args( mockTextBodyWithLayout, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockHtmlBodyWithLayout, mockParams, "html" ).$results( mockHtmlBodyRendered );
				service.$( "replaceParameterTokens" ).$args( mockHtmlWithViewOnline, mockParams, "html" ).$results( mockHtmlWithViewOnlineRendered );
				service.$( "getAttachments", [] );

				service.$( "getViewOnlineLink" ).$args( mockHtmlBodyRendered ).$results( viewOnlineLink );

				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "html"
					, subject        = mockSubject
					, body           = mockHtmlBody
					, viewOnlineLink = viewOnlineLink
				).$results( mockHtmlWithViewOnline );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailStyleInliner.$( "inlineStyles" ).$args( mockHtmlWithViewOnlineRendered ).$results( mockHtmlBodyWithStyles );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId ).$results( mockTo );

				expect( service.prepareMessage( template=template, recipientId=mockRecipientId, args=mockArgs ) ).toBe( {
					  subject     = mockSubject
					, from        = mockTemplate.from_address
					, to          = [ mockTo ]
					, textBody    = mockTextBody
					, htmlBody    = mockHtmlBodyWithStyles
					, cc          = []
					, bcc         = []
					, params      = {}
					, attachments = []
				} );
			} );

			it( "should add unsubscribe header when unsubscribe link is not empty", function(){
				var service                = _getService();
				var template               = "mytemplate";
				var mockUnsubscribeLink    = CreateUUId();
				var mockSubject            = CreateUUId();
				var mockTo                 = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockHtmlBodyRendered   = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithStyles = CreateUUId();
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
					, view_online     = false
				};

				mockEmailRecipientTypeService.$( "getUnsubscribeLink" ).$args(
					  recipientType = "testRecipientType"
					, recipientId   = mockRecipientId
					, templateId    = template
				).$results( mockUnsubscribeLink );

				service.$( "getTemplate" ).$args( id=template, allowDrafts=false ).$results( mockTemplate );
				service.$( "prepareParameters" ).$args(
					  template       = template
					, recipientType  = mockTemplate.recipient_type
					, recipientId    = mockRecipientId
					, templateDetail = mockTemplate
					, args           = mockArgs
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockTemplate.html_body, context="email"  ).$results( mockHtmlBody );

				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "text"
					, subject        = mockSubject
					, body           = mockTemplate.text_body
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout          = mockTemplate.layout
					, emailTemplate   = template
					, templateDetail  = mockTemplate
					, blueprint       = mockTemplate.email_blueprint
					, type            = "html"
					, subject         = mockSubject
					, body            = mockHtmlBody
					, unsubscribeLInk = mockUnsubscribeLink
				).$results( mockHtmlBodyWithLayout );

				service.$( "replaceParameterTokens" ).$args( mockTextBodyWithLayout, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockHtmlBodyWithLayout, mockParams, "html" ).$results( mockHtmlBodyRendered );
				service.$( "getAttachments", [] );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailStyleInliner.$( "inlineStyles" ).$args( mockHtmlBodyRendered ).$results( mockHtmlBodyWithStyles );

				mockEmailRecipientTypeService.$( "getToAddress" ).$args( recipientType=mockTemplate.recipient_type, recipientId=mockRecipientId ).$results( mockTo );

				var prepped = service.prepareMessage( template=template, recipientId=mockRecipientId, args=mockArgs );

				expect( prepped.params ).toBe( { "List-Unsubscribe"={ name="List-Unsubscribe", value=mockUnsubscribeLink } } );
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
				var mockHtmlBodyWithStyles = CreateUUId();
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
					, view_online     = false
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=true, version=version ).$results( mockTemplate );
				service.$( "getPreviewParameters" ).$args(
					  template      = template
					, recipientType = mockTemplate.recipient_type
				).$results( mockParams );
				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockTemplate.html_body, context="email" ).$results( mockHtmlBody );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "text"
					, subject        = mockSubject
					, body           = mockTemplate.text_body
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "html"
					, subject        = mockSubject
					, body           = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				service.$( "replaceParameterTokens" ).$args( mockTextBodyWithLayout, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockHtmlBodyWithLayout, mockParams, "html" ).$results( mockHtmlBodyRendered );

				mockEmailStyleInliner.$( "inlineStyles" ).$args( mockHtmlBodyRendered ).$results( mockHtmlBodyWithStyles );

				expect( service.previewTemplate( template=template, allowDrafts=true, version=version ) ).toBe( {
					  subject  = mockSubject
					, textBody = mockTextBody
					, htmlBody = mockHtmlBodyWithStyles
				} );
			} );

			it( "should render the details using passed in recipient ID as the user for preview when recipient ID is not empty", function(){
				var service                = _getService();
				var template               = "mytemplate";
				var mockSubject            = CreateUUId();
				var mockTo                 = CreateUUId();
				var mockTextBody           = CreateUUId();
				var mockHtmlBody           = CreateUUId();
				var mockHtmlBodyRendered   = CreateUUId();
				var mockTextBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithLayout = CreateUUId();
				var mockHtmlBodyWithStyles = CreateUUId();
				var mockArgs               = { userId = CreateUUId(), bookingId = CreateUUId() };
				var mockParams             = { test=CreateUUId(), params=Now() };
				var version                = 49545;
				var recipientId            = CreateUUId();
				var mockTemplate           = {
					  layout          = "testLayout"
					, recipient_type  = "testRecipientType"
					, subject         = "Test subject"
					, from_address    = "From address"
					, html_body       = "HTML BODY HERE"
					, text_body       = "TEXT BODY OH YEAH"
					, email_blueprint = CreateUUId()
					, view_online     = false
				};

				service.$( "getTemplate" ).$args( id=template, allowDrafts=true, version=version ).$results( mockTemplate );
				service.$( "prepareParameters" ).$args(
					  template       = template
					, templateDetail = mockTemplate
					, recipientType  = mockTemplate.recipient_type
					, recipientId    = recipientId
					, args           = {}
				).$results( mockParams );

				service.$( "replaceParameterTokens" ).$args( mockTemplate.subject, mockParams, "text" ).$results( mockSubject );
				service.$( "$renderContent" ).$args( renderer="richeditor", data=mockTemplate.html_body, context="email" ).$results( mockHtmlBody );

				mockSystemEmailTemplateService.$( "templateExists" ).$args( template ).$results( true );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "text"
					, subject        = mockSubject
					, body           = mockTemplate.text_body
				).$results( mockTextBodyWithLayout );
				mockEmailLayoutService.$( "renderLayout" ).$args(
					  layout         = mockTemplate.layout
					, emailTemplate  = template
					, templateDetail = mockTemplate
					, blueprint      = mockTemplate.email_blueprint
					, type           = "html"
					, subject        = mockSubject
					, body           = mockHtmlBody
				).$results( mockHtmlBodyWithLayout );

				service.$( "replaceParameterTokens" ).$args( mockTextBodyWithLayout, mockParams, "text" ).$results( mockTextBody );
				service.$( "replaceParameterTokens" ).$args( mockHtmlBodyWithLayout, mockParams, "html" ).$results( mockHtmlBodyRendered );

				mockEmailStyleInliner.$( "inlineStyles" ).$args( mockHtmlBodyRendered ).$results( mockHtmlBodyWithStyles );

				mockEmailSendingContextService.$( "setContext" );
				mockEmailSendingContextService.$( "clearContext" );

				expect( service.previewTemplate( template=template, allowDrafts=true, version=version, previewRecipient = recipientId ) ).toBe( {
					  subject          = mockSubject
					, textBody         = mockTextBody
					, htmlBody         = mockHtmlBodyWithStyles
				} );

				expect( mockEmailSendingContextService.$callLog().clearContext.len() ).toBe( 1 );
				expect( mockEmailSendingContextService.$callLog().setContext.len() ).toBe( 1 );
				expect( mockEmailSendingContextService.$callLog().setContext[ 1 ] ).toBe( {
					  recipientType = mockTemplate.recipient_type
					, recipientId   = recipientId
					, templateId    = template
					, template      = mockTemplate
				} );
			} );
		} );

		describe( "getViewOnlineContentId()", function(){
			it( "it should use an MD5 hash of the given content to check against DB store of sent content and return the matching record ID", function(){
				var service     = _getService();
				var content     = CreateUUId();
				var contentHash = Hash( content );
				var viewOnlineId = CreateUUId();
				var matchingRecord = QueryNew( 'id', 'varchar', [ [ viewOnlineId ] ] );

				mockViewOnlineContentDao.$( "selectData" ).$args(
					  selectFields = [ "id" ]
					, filter       = { content_hash = contentHash }
				).$results( matchingRecord );

				expect( service.getViewOnlineContentId( content ) ).toBe( viewOnlineId );
			} );

			it( "should create a new view online record when none exist that match the content hash", function(){
				var service     = _getService();
				var content     = CreateUUId();
				var contentHash = Hash( content );
				var viewOnlineId = CreateUUId();
				var matchingRecord = QueryNew( 'id' );

				mockViewOnlineContentDao.$( "selectData" ).$args(
					  selectFields = [ "id" ]
					, filter       = { content_hash = contentHash }
				).$results( matchingRecord );

				mockViewOnlineContentDao.$( "insertData" ).$args( {
					  content      = content
					, content_hash = contentHash
				} ).$results( viewOnlineId );

				expect( service.getViewOnlineContentId( content ) ).toBe( viewOnlineId );
			} );
		} );

		describe( "getViewOnlineLink()", function(){
			it( "should generate a link based on the view online ID of the given content", function(){
				var service      = _getService();
				var content      = CreateUUId();
				var viewOnlineId = CreateUUId();
				var link         = CreateUUId();

				service.$( "getViewOnlineContentId" ).$args( content ).$results( viewOnlineId );
				mockRequestContext.$( "buildLink" ).$args(
					  linkto      = "email.viewonline"
					, queryString = "mid=" & viewOnlineId
				).$results( link );

				expect( service.getViewOnlineLink( content ) ).toBe( link );
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
			it( "should fetch all the templates using 'fixeddate' schedule who have not been sent and whose send date is in the past", function(){
				var service = _getService();
				var templateRecords = QueryNew( 'id', 'varchar', [[CreateUUId()], [CreateUUId()]] );
				var nowish = Now();

				service.$( "_getNow", nowish );
				mockTemplateDao.$( "selectData" ).$args(
					  selectFields       = [ "id" ]
					, filter             = "sending_method = :sending_method and schedule_type = :schedule_type and (schedule_sent is null or schedule_sent = :schedule_sent)"
					, filterParams       = { sending_method="scheduled", schedule_type="fixeddate", schedule_sent=false }
					, extraFilters       = [ { filter="schedule_date <= :schedule_date", filterParams={ schedule_date=nowish } } ]
					, orderby            = "schedule_date"
					, allowDraftVersions = false
					, useCache           = false
				).$results( templateRecords );

				expect( service.listDueOneTimeScheduleTemplates() ).toBe( ValueArray( templateRecords.id ) );
			} );
		} );

		describe( "listDueRepeatedScheduleTemplates()", function(){
			it( "should fetch all the templates using 'repeat' schedule whose next send date is in the past and when current date is between start and end date", function(){
				var service = _getService();
				var templateRecords = QueryNew( 'id', 'varchar', [[CreateUUId()], [CreateUUId()]] );
				var nowish = Now();

				service.$( "_getNow", nowish );
				mockTemplateDao.$( "selectData" ).$args(
					  selectFields       = [ "id" ]
					, filter             = { sending_method="scheduled", schedule_type="repeat" }
					, extraFilters       = [ { filter="schedule_next_send_date <= :schedule_next_send_date", filterParams={ schedule_next_send_date=nowish } } ]
					, orderby            = "schedule_next_send_date"
					, allowDraftVersions = false
					, useCache           = false
				).$results( templateRecords );

				expect( service.listDueRepeatedScheduleTemplates() ).toBe( ValueArray( templateRecords.id ) );
			} );
		} );

		describe( "getAttachments()", function(){
			it( "should return an array of attachment binaries & titles using the asset manager service with configured template attachments", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var assets     = QueryNew( 'id,title,asset_type', 'varchar,varchar,varchar', [
					  [ CreateUUId(), "Title 1", "pdf" ]
					, [ CreateUUId(), "Title 2", "pdf" ]
					, [ CreateUUId(), "Title 3", "pdf" ]
				] );
				var binaries = [
					  ToBinary( ToBase64( CreateUUId() ) )
					, ToBinary( ToBase64( CreateUUId() ) )
					, ToBinary( ToBase64( CreateUUId() ) )
				];
				var expected = [];

				for( var i=1; i<=assets.recordCount; i++ ) {
					expected.append({
						  binary          = binaries[ i ]
						, name            = assets.title[ i ] & ".pdf"
						, removeAfterSend = false
					});
					mockAssetManagerService.$( "getAssetBinary" ).$args(
						  id             = assets.id[ i ]
						, throwOnMissing = false
					).$results( binaries[ i ] );
					mockAssetManagerService.$( "getAssetType", { extension="pdf" } );
				}

				mockTemplateDao.$( "selectData" ).$args(
					  id           = templateId
					, selectFields = [ "attachments.id", "attachments.title", "attachments.asset_type" ]
					, orderBy      = "email_template_attachment.sort_order"
				).$results( assets );


				expect( service.getAttachments( templateId ) ).toBe( expected );
			} );
		} );

		describe( "getSentCount()", function(){
			it( "should return count of sends for the given template for all time when no date range passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'sent_count', 'int', [[635]] );

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as sent_count" ]
					, filter       = { id=templateId, "send_logs.sent"=true }
					, forceJoins   = "inner"
					, extraFilters = []
					, useCache     = false
				).$results( stats );

				expect( service.getSentCount( templateId ) ).toBe( 635 );
			} );

			it( "should add date filters when dateFrom and dateTo passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'sent_count', 'int', [[23]] );
				var dateFrom   = "1900-01-01";
				var dateTo   = "1999-06-29";

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as sent_count" ]
					, filter       = { id=templateId, "send_logs.sent"=true }
					, forceJoins   = "inner"
					, extraFilters = [
						  { filter="send_logs.sent_date >= :dateFrom", filterParams={ dateFrom = { type="cf_sql_timestamp", value=dateFrom } } }
						, { filter="send_logs.sent_date <= :dateTo"  , filterParams={ dateTo   = { type="cf_sql_timestamp", value=dateTo   } } }
					]
					, useCache     = false
				).$results( stats );

				expect( service.getSentCount( templateId, dateFrom, dateTo ) ).toBe( 23 );
			} );
		} );

		describe( "getDeliveredCount()", function(){
			it( "should return count of successful deliveries for the given template for all time when no date range passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'delivered_count', 'int', [[635]] );

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as delivered_count" ]
					, filter       = { id=templateId, "send_logs.delivered"=true }
					, forceJoins   = "inner"
					, extraFilters = []
					, useCache     = false
				).$results( stats );

				expect( service.getDeliveredCount( templateId ) ).toBe( 635 );
			} );

			it( "should add date filters when dateFrom and dateTo passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'delivered_count', 'int', [[23]] );
				var dateFrom   = "1900-01-01";
				var dateTo   = "1999-06-29";

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as delivered_count" ]
					, filter       = { id=templateId, "send_logs.delivered"=true }
					, forceJoins   = "inner"
					, extraFilters = [
						  { filter="send_logs.delivered_date >= :dateFrom", filterParams={ dateFrom={ type="cf_sql_timestamp", value=dateFrom } } }
						, { filter="send_logs.delivered_date <= :dateTo"  , filterParams={ dateTo={ type="cf_sql_timestamp", value=dateTo } } }
					]
					, useCache     = false
				).$results( stats );

				expect( service.getDeliveredCount( templateId, dateFrom, dateTo ) ).toBe( 23 );
			} );
		} );

		describe( "getUniqueOpenedCount()", function(){
			it( "should return count of successful opens for the given template for all time when no date range passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'opened_count', 'int', [[635]] );

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as opened_count" ]
					, filter       = { id=templateId, "send_logs.opened"=true }
					, forceJoins   = "inner"
					, extraFilters = []
				).$results( stats );

				expect( service.getUniqueOpenedCount( templateId ) ).toBe( 635 );
			} );

			it( "should add date filters when dateFrom and dateTo passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'opened_count', 'int', [[23]] );
				var dateFrom   = "1900-01-01";
				var dateTo   = "1999-06-29";

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as opened_count" ]
					, filter       = { id=templateId, "send_logs.opened"=true }
					, forceJoins   = "inner"
					, extraFilters = [
						  { filter="send_logs.opened_date >= :dateFrom", filterParams={ dateFrom={ type="cf_sql_timestamp", value=dateFrom } } }
						, { filter="send_logs.opened_date <= :dateTo"  , filterParams={ dateTo={ type="cf_sql_timestamp", value=dateTo } } }
					]
				).$results( stats );

				expect( service.getUniqueOpenedCount( templateId, dateFrom, dateTo ) ).toBe( 23 );
			} );
		} );

		describe( "getFailedCount()", function(){
			it( "should return count of successful opens for the given template for all time when no date range passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'failed_count', 'int', [[635]] );

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as failed_count" ]
					, filter       = { id=templateId, "send_logs.failed"=true }
					, forceJoins   = "inner"
					, extraFilters = []
				).$results( stats );

				expect( service.getFailedCount( templateId ) ).toBe( 635 );
			} );

			it( "should add date filters when dateFrom and dateTo passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'failed_count', 'int', [[23]] );
				var dateFrom   = "1900-01-01";
				var dateTo   = "1999-06-29";

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( send_logs.id ) as failed_count" ]
					, filter       = { id=templateId, "send_logs.failed"=true }
					, forceJoins   = "inner"
					, extraFilters = [
						  { filter="send_logs.failed_date >= :dateFrom", filterParams={ dateFrom={ type="cf_sql_timestamp", value=dateFrom } } }
						, { filter="send_logs.failed_date <= :dateTo"  , filterParams={ dateTo={ type="cf_sql_timestamp", value=dateTo } } }
					]
				).$results( stats );

				expect( service.getFailedCount( templateId, dateFrom, dateTo ) ).toBe( 23 );
			} );
		} );

		describe( "getQueuedCount()", function(){
			it( "should return count of queued emails", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var stats      = QueryNew( 'queued_count', 'int', [[459]] );

				mockTemplateDao.$( "selectData" ).$args(
					  selectFields = [ "Count( queued_emails.id ) as queued_count" ]
					, filter       = { id=templateId }
					, forceJoins   = "inner"
					, useCache     = false
				).$results( stats );

				expect( service.getQueuedCount( templateId ) ).toBe( 459 );
			} );
		} );

		describe( "getStats()", function(){
			it( "should get counts and return in a struct based on args passed", function(){
				var service    = _getService();
				var templateId = CreateUUId();
				var dateFrom   = "2017-06-12";
				var dateTo     = "2017-07-19";
				var stats      = { sent=4985, delivered=4980, failed=5, opened=234, queued=340, clicks=234 };

				service.$( "getSentCount" ).$args( templateId=templateId, dateFrom=dateFrom, dateTo=dateTo, timePoints=1, uniqueOpens=true ).$results( stats.sent );
				service.$( "getDeliveredCount" ).$args( templateId=templateId, dateFrom=dateFrom, dateTo=dateTo, timePoints=1, uniqueOpens=true ).$results( stats.delivered );
				service.$( "getFailedCount" ).$args( templateId=templateId, dateFrom=dateFrom, dateTo=dateTo, timePoints=1, uniqueOpens=true ).$results( stats.failed );
				service.$( "getUniqueOpenedCount" ).$args( templateId=templateId, dateFrom=dateFrom, dateTo=dateTo, timePoints=1, uniqueOpens=true ).$results( stats.opened );
				service.$( "getClickCount" ).$args( templateId=templateId, dateFrom=dateFrom, dateTo=dateTo, timePoints=1, uniqueOpens=true ).$results( stats.clicks );
				service.$( "getQueuedCount" ).$args( templateId=templateId ).$results( stats.queued );

				expect( service.getStats( templateId=templateId, dateFrom=dateFrom, dateTo=dateTo ) ).toBe( stats );
			} );
		} );

		describe( "getQueueStats()", function(){
			it( "should get counts of queued emails grouped by template", function(){
				var service = _getService();
				var stats   = QueryNew( 'queued_count,id,name', 'int,varchar,varchar', [
					  [ 324   , CreateUUId(), "Template 1" ]
					, [ 132654, CreateUUId(), "Template 2" ]
					, [ 1     , CreateUUId(), "Template 3" ]
					, [ 464   , CreateUUId(), "Template 4" ]
					, [ 116   , CreateUUId(), "Template 5" ]
				] );

				mockQueueDao.$( "selectData" ).$args(
					  selectFields = [ "Count( email_mass_send_queue.id ) as queued_count", "template.id", "template.name" ]
					, autoGroupBy  = true
					, orderBy      = "template.name"
				).$results( stats );

				expect( service.getQueueStats() ).toBe( stats );
			} );
		} );
	}

	private any function _getService( boolean initialize=true ) {
		var service = createMock( object=CreateObject( "preside.system.services.email.EmailTemplateService" ) );

		mockTemplateDao          = createStub();
		mockQueueDao             = createStub();
		mockBlueprintDao         = createStub();
		mockViewOnlineContentDao = createStub();
		mockRequestContext       = createStub();
		mockEmailSettings        = { defaultContentExpiry=30 };

		service.$( "$getPresideObject" ).$args( "email_template" ).$results( mockTemplateDao );
		service.$( "$getPresideObject" ).$args( "email_mass_send_queue" ).$results( mockQueueDao );
		service.$( "$getPresideObject" ).$args( "email_blueprint" ).$results( mockBlueprintDao );
		service.$( "$getPresideObject" ).$args( "email_template_view_online_content" ).$results( mockViewOnlineContentDao );
		service.$( "$isFeatureEnabled" ).$args( "emailStyleInliner" ).$results( true );
		service.$( "$isFeatureEnabled" ).$args( "emailOverwriteDomain" ).$results( false );
		service.$( "$audit" );
		service.$( "$getRequestContext", mockRequestContext );
		service.$( "$announceInterception", mockRequestContext );

		mockSystemEmailTemplateService = createEmptyMock( "preside.system.services.email.SystemEmailTemplateService" );
		mockEmailRecipientTypeService  = createEmptyMock( "preside.system.services.email.EmailRecipientTypeService" );
		mockEmailLayoutService         = createEmptyMock( "preside.system.services.email.EmailLayoutService" );
		mockEmailSendingContextService = createEmptyMock( "preside.system.services.email.EmailSendingContextService" );
		mockEmailStyleInliner          = createEmptyMock( "preside.system.services.email.EmailStyleInliner" );
		mockAssetManagerService        = createEmptyMock( "preside.system.services.assetManager.AssetManagerService" );

		mockSystemEmailTemplateService.$( "templateExists", false );
		mockSystemEmailTemplateService.$( "prepareAttachments", [] );
		mockEmailSendingContextService.$( "setContext" );
		mockEmailSendingContextService.$( "clearContext" );

		mockEmailRecipientTypeService.$( "getUnsubscribeLink", "" );

		if ( arguments.initialize ) {
			service.$( "_ensureSystemTemplatesHaveDbEntries" );
			service.init(
				  systemEmailTemplateService = mockSystemEmailTemplateService
				, emailRecipientTypeService  = mockEmailRecipientTypeService
				, emailLayoutService         = mockEmailLayoutService
				, emailSendingContextService = mockEmailSendingContextService
				, assetManagerService        = mockAssetManagerService
				, emailStyleInliner          = mockEmailStyleInliner
				, emailSettings              = mockEmailSettings
			);
		}

		return service;
	}
}
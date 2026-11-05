component {

	property name="presideObjectService"       inject="presideObjectService";
	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="taskmanagerService"         inject="taskmanagerService";
	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailLayoutService"         inject="emailLayoutService";

	private string function datamanager( event, rc, prc, args={} ) {
		var action       = args.action            ?: "";
		var known_as     = args.known_as          ?: "";
		var userLink     = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var objectName   = args.detail.objectName ?: "";

		var labelField   = objectName.len() ? presideObjectService.getObjectAttribute( objectName, "labelField" ) : "";
		var record_id    = args.record_id   ?: "";
		var recordLabel  = record_id;
		try {
			recordLabel  = args.detail[ labelField ] ?: renderLabel( objectName=objectName, recordId=record_id );
		} catch (PresideObjectService.no.label.field e) {}

		var objectTitle  = translateResource( uri="preside-objects.#objectName#:title.singular" );
		var objectUrl    = event.buildAdminLink( objectName=objectName, operation="listing" );
		var objectLink   = _linkedAdminText( objectUrl, objectTitle );
		var recordUrl    = event.buildAdminLink( objectName=objectName, recordId=record_id );
		var recordLink   = _linkedAdminText( recordUrl, recordLabel );

		switch( action ) {
			case "datamanager_translate_record":
			case "datamanager_save_draft_translation":
			case "datamanager_publish_translation":
				var language = renderLabel( "multilingual_language", args.detail.languageId ?: "" );
				return translateResource( uri="auditlog.datamanager:#args.action#.message", data=[ userLink, objectLink, recordLink, language ] );
			case "datamanager_batch_edit_record":
				var field = args.detail.fieldName ?: "";
				var fieldName = translateResource( "preside-objects.#objectName#:field.#field#.title", field );
				return translateResource( uri="auditlog.datamanager:#args.action#.message", data=[ userLink, objectLink, recordLink, fieldName ] );
		}


		return translateResource( uri="auditlog.datamanager:#args.action#.message", data=[ userLink, objectLink, recordLink ] );
	}

	private string function userManager( event, rc, prc, args={} ) {
		var action     = args.action            ?: "";
		var known_as   = args.known_as          ?: "";
		var userLink   = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var recordId   = args.record_id         ?: "";
		var type       = action.find( "_group" ) ? "group" : "user";
		var labelField = type == "group" ? "label" : "known_as";
		var label      = args.detail[ labelField ] ?: "unknown";
		var recordUrl  = event.buildAdminLink( linkTo="usermanager.#( type == 'group' ? 'editGroup' : 'editUser' )#", queryString="id=" & recordId );
		var recordLink = _linkedAdminText( recordUrl, label );

		return translateResource( uri="auditlog.usermanager:#action#.message", data=[ userLink, recordLink ] );
	}

	private string function sysconfig( event, rc, prc ) {
		var action       = args.action    ?: "";
		var known_as     = args.known_as  ?: "";
		var userLink     = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		if( isFeatureEnabled( "emailcenter" ) && ( args.record_id ?: "" ) == "email"  ){
			var category     = translateResource( "cms:emailCenter.menu.title" );
			var categoryUrl  = event.buildAdminLink( linkTo="emailcenter.settings" );
		} else {
			var category     = translateResource( systemConfigurationService.getConfigCategory( args.record_id ?: "" ).getName() );
			var categoryUrl  = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=" & ( args.record_id ?: "" ) )
		}
		var categoryLink = _linkedAdminText( categoryUrl, category );

		return translateResource( uri="auditlog.sysconfig:#action#.message", data=[ userLink, categoryLink ] );
	}

	private string function sitemanager( event, rc, prc ) {
		var action   = args.action    ?: "";
		var known_as = args.known_as  ?: "";
		var userLink = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var siteId   = args.record_id;
		var siteName = args.detail.name ?: "unknown";
		var siteUrl  = event.buildAdminLink( linkTo="sites.editSite", queryString="id=" & ( args.record_id ?: "" ) )
		var siteLink = _linkedAdminText( siteUrl, siteName );

		return translateResource( uri="auditlog.sitemanager:#action#.message", data=[ userLink, siteLink ] );
	}

	private string function passwordpolicies( event, rc, prc ) {
		var action      = args.action    ?: "";
		var known_as    = args.known_as  ?: "";
		var userLink    = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var context     = args.record_id;
		var contextName = translateResource( "cms:passwordpolicycontext.#context#.title" );
		var contextUrl  = event.buildAdminLink( linkTo="passwordpolicymanager", queryString="context=" & context );
		var contextLink = _linkedAdminText( contextUrl, contextName );

		return translateResource( uri="auditlog.passwordpolicies:#action#.message", data=[ userLink, contextLink ] );
	}

	private string function urlredirects( event, rc, prc ) {
		var action   = args.action    ?: "";
		var known_as = args.known_as  ?: "";
		var userLink = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var rule     = args.record_id;
		var ruleName = args.detail.label ?: "unknown";
		var ruleUrl  = event.buildAdminLink( linkTo="urlredirects.editrule", queryString="id=" & rule );
		var ruleLink = _linkedAdminText( ruleUrl, ruleName );

		return translateResource( uri="auditlog.urlredirects:#action#.message", data=[ userLink, ruleLink ] );
	}

	private string function websiteusermanager( event, rc, prc ) {
		var action      = args.action    ?: "";
		var known_as    = args.known_as  ?: "";
		var userLink    = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var webUser     = args.record_id;
		var webUserName = args.detail.display_name ?: "unknown";
		var webUserUrl  = event.buildAdminLink( linkTo="websiteusermanager.edituser", queryString="id=" & webUser );
		var webUserLink = _linkedAdminText( webUserUrl, webUserName );

		return translateResource( uri="auditlog.websiteusermanager:#action#.message", data=[ userLink, webUserLink ] );
	}

	private string function websitebenefitsmanager( event, rc, prc ) {
		var action   = args.action    ?: "";
		var known_as = args.known_as  ?: "";
		var userLink = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var benefit     = args.record_id;
		var benefitName = args.detail.label ?: "unknown";
		var benefitUrl  = event.buildAdminLink( linkTo="websitebenefitsmanager.editbenefit", queryString="id=" & benefit );
		var benefitLink = _linkedAdminText( benefitUrl, benefitName );

		return translateResource( uri="auditlog.websitebenefitsmanager:#action#.message", data=[ userLink, benefitLink ] );
	}

	private string function rulesEngine( event, rc, prc ) {
		var action        = args.action    ?: "";
		var known_as      = args.known_as  ?: "";
		var userLink      = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var condition     = args.record_id;
		var conditionName = args.detail.condition_name ?: "unknown";
		var conditionUrl  = event.buildAdminLink( linkTo="rulesengine.editCondition", queryString="id=" & condition );
		var conditionLink = _linkedAdminText( conditionUrl, conditionName );

		return translateResource( uri="auditlog.rulesEngine:#action#.message", data=[ userLink, conditionLink ] );
	}

	private string function taskmanager( event, rc, prc ) {
		var action     = args.action    ?: "";
		var known_as   = args.known_as  ?: "";
		var userLink   = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var task       = args.record_id;
		var taskDetail = {};
		var taskLink   = "";
		try {
			taskDetail = Len( Trim( task ) ) ? taskmanagerService.getTask( task ) : {};
			var taskName = taskDetail.name ?: "unknown";
			var taskUrl  = event.buildAdminLink( linkTo="taskmanager.history", queryString="task=" & task );
			taskLink     = _linkedAdminText( taskUrl, taskName );
		} catch( "TaskManager.missing.task" e ) {
			action = "#action#.unknown_task";
		}

		return translateResource( uri="auditlog.taskmanager:#action#.message", data=[ userLink, taskLink ] );
	}

	private string function frontendeditor( event, rc, prc, args={} ) {
		var action       = args.action        ?: "";
		var known_as     = args.known_as      ?: "";
		var userLink     = args.userLink      ?: "";
		var record_id    = args.record_id     ?: "";
		var objectName   = args.detail.object ?: "";
		var labelField   = objectName.len() ? presideObjectService.getObjectAttribute( objectName, "labelField" ) : "";
		var userLink     = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var objectTitle  = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
		var recordLabel  = args.detail[ labelField ] ?: renderLabel( objectName=objectName, recordId=record_id );

		return translateResource( uri="auditlog.frontendeditor:#args.action#.message", data=[ userLink, objectTitle, EncodeForHtml( recordLabel ) ] );
	}

	private string function emailtemplate( event, rc, prc, args={} ) {
		var action     = args.action            ?: "";
		var known_as   = args.known_as          ?: "";
		var userLink   = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var recordId   = args.record_id         ?: "";
		var label      = renderLabel( "email_template", recordId );
		var type       = systemEmailTemplateService.templateExists( recordId ) ? "systemtemplates" : "customtemplates";
		var recordUrl  = event.buildAdminLink( linkTo="emailcenter.#type#.template", queryString="template=" & recordId );
		var recordLink = '<a href="#recordUrl#">#label#</a>';

		return translateResource( uri="auditlog.emailtemplate:#action#.message", data=[ userLink, recordLink ] );
	}

	private string function emailLayout( event, rc, prc, args={} ) {
		var action     = args.action            ?: "";
		var known_as   = args.known_as          ?: "";
		var userLink   = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var recordId   = args.record_id         ?: "";
		var layout     = emailLayoutService.getLayout( recordId );
		var label      = layout.title ?: "Unknown";
		var recordUrl  = event.buildAdminLink( linkTo="emailcenter.layouts.layout", queryString="layout=" & recordId );
		var recordLink = _linkedAdminText( recordUrl, label );

		return translateResource( uri="auditlog.emaillayout:#action#.message", data=[ userLink, recordLink ] );
	}

	private string function emailResend( event, rc, prc, args={} ) {
		var action     = args.action           ?: "";
		var known_as   = args.known_as         ?: "";
		var subject    = args.detail.subject   ?: "";
		var recipient  = args.detail.recipient ?: "";
		var userLink   = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );

		return translateResource( uri="auditlog.emailresend:#action#.message", data=[ userLink, EncodeForHtml( subject ), EncodeForHtml( recipient ) ] );
	}

	private string function dataexport( event, rc, prc, args={} ) {
		var action     = args.action            ?: "";
		var known_as   = args.known_as          ?: "";
		var userLink   = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );
		var file       = args.detail.file       ?: "";

		return translateResource( uri="auditlog.dataexport:#action#.message", data=[ userLink, EncodeForHtml( file ) ] );
	}

	private string function userProfile( event, rc, prc, args={} ) {
		var action = args.action ?: "";

		var userLink = _linkedAdminText( args.userLink ?: "", args.known_as ?: "" );

		var recordId   = args.record_id ?: "";
		var recordLink = "";
		if ( !isEmptyString( recordId ) ) {
			recordLink = _linkedAdminText( event.buildAdminLink( linkTo="usermanager.viewUser", queryString="id=" & recordId ), renderLabel( "security_user", recordId ) );
		}

		return translateResource( uri="auditlog.userprofile:#action#.message", data=[ userLink, recordLink ] );
	}

	private string function _linkedAdminText( required string href, required string label ) {
		return '<a href="#EncodeForHtmlAttribute( arguments.href )#">#EncodeForHtml( arguments.label )#</a>';
	}

	private string function _linkedAdminHtml( required string href, required string html ) {
		return '<a href="#EncodeForHtmlAttribute( arguments.href )#">#arguments.html#</a>';
	}
}
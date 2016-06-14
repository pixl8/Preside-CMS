component {

	property name="presideObjectService"       inject="presideObjectService";
	property name="systemConfigurationService" inject="systemConfigurationService";

	private string function datamanager( event, rc, prc, args={} ) {
		var action       = args.action            ?: "";
		var known_as     = args.known_as          ?: "";
		var userLink     = args.userLink          ?: "";
		var record_id    = args.record_id         ?: "";
		var objectName   = args.detail.objectName ?: "";
		var labelField   = objectName.len() ? presideObjectService.getObjectAttribute( objectName, "labelField" ) : "";
		var userLink     = '<a href="#args.userLink#">#args.known_as#</a>';
		var objectTitle  = translateResource( uri="preside-objects.#objectName#:title.singular" );
		var objectUrl    = event.buildAdminLink( linkTo="datamanager.object", queryString="id=" & objectName );
		var objectLink   = '<a href="#objectUrl#">#objectTitle#</a>';
		var recordLabel  = args.detail[ labelField ] ?: "unknown";
		var recordUrl    = event.buildAdminLink( linkTo="datamanager.viewRecord", queryString="object=#objectName#&id=#args.record_id#" );
		var recordLink   = '<a href="#recordUrl#">#recordLabel#</a>';

		switch( action ) {
			case "datamanager_translate_record":
				var language = renderLabel( "multilingual_language", args.detail.languageId ?: "" );
				return translateResource( uri="auditlog.datamanager:#args.action#.message", data=[ userLink, objectLink, recordLink, language ] );
			break;
		}


		return translateResource( uri="auditlog.datamanager:#args.action#.message", data=[ userLink, objectLink, recordLink ] );
	}

	private string function userManager( event, rc, prc, args={} ) {
		var action     = args.action            ?: "";
		var known_as   = args.known_as          ?: "";
		var userLink   = '<a href="#args.userLink#">#args.known_as#</a>';
		var recordId   = args.record_id         ?: "";
		var type       = action.find( "_group" ) ? "group" : "user";
		var labelField = type == "group" ? "label" : "known_as";
		var label      = args.detail[ labelField ] ?: "unknown";
		var recordUrl  = event.buildAdminLink( linkTo="usermanager.#( type == 'group' ? 'editGroup' : 'editUser' )#", queryString="id=" & recordId );
		var recordLink = '<a href="#recordUrl#">#label#</a>';

		return translateResource( uri="auditlog.usermanager:#action#.message", data=[ userLink, recordLink ] );
	}

	private string function sysconfig( event, rc, prc ) {
		var action       = args.action    ?: "";
		var known_as     = args.known_as  ?: "";
		var userLink     = '<a href="#args.userLink#">#args.known_as#</a>';
		var category     = translateResource( systemConfigurationService.getConfigCategory( args.record_id ?: "" ).getName() );
		var categoryUrl  = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=" & ( args.record_id ?: "" ) )
		var categoryLink = '<a href="#categoryUrl#">#category#</a>';

		return translateResource( uri="auditlog.sysconfig:#action#.message", data=[ userLink, categoryLink ] );
	}

	private string function sitemanager( event, rc, prc ) {
		var action   = args.action    ?: "";
		var known_as = args.known_as  ?: "";
		var userLink = '<a href="#args.userLink#">#args.known_as#</a>';
		var siteId   = args.record_id;
		var siteName = args.detail.name ?: "unknown";
		var siteUrl  = event.buildAdminLink( linkTo="sites.editSite", queryString="id=" & ( args.record_id ?: "" ) )
		var siteLink = '<a href="#siteUrl#">#siteName#</a>';

		return translateResource( uri="auditlog.sitemanager:#action#.message", data=[ userLink, siteLink ] );
	}

}
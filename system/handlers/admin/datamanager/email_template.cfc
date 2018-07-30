component {

	private array function getCloneRecordActionButtons( event, rc, prc, args={} ) {
		var actions = [{
			  type      = "link"
			, href      = event.buildAdminLink( linkto="emailcenter.customTemplates" )
			, class     = "btn-default"
			, globalKey = "c"
			, iconClass = "fa-reply"
			, label     = translateResource( uri="cms:cancel.btn" )
		}];

		actions.append({
			  type      = "button"
			, class     = "btn-info"
			, iconClass = "fa-save"
			, name      = "_saveAction"
			, value     = "savedraft"
			, label     = translateResource( uri="cms:emailcenter.customTemplates.clone.record.btn" )
		} );

		return actions;
	}

}
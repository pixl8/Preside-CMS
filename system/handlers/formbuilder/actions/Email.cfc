component {

	private string function renderAdminPlaceholder( event, rc, prc, args={} ) {
		var placeholder = '<i class="fa fa-fw fa-envelope"></i> ';
		var toAddress   = args.configuration.recipients ?: "";
		var fromAddress = args.configuration.send_from  ?: "";

		if ( Len( Trim( fromAddress ) ) ) {
			placeholder &= translateResource(
				  uri  = "formbuilder.actions.email:admin.placeholder.with.from.address"
				, data = [ "<strong>#toAddress#</strong>", "<strong>#fromAddress#</strong>" ]
			);
		} else {
			placeholder &= translateResource(
				  uri  = "formbuilder.actions.email:admin.placeholder.no.from.address"
				, data = [ "<strong>#toAddress#</strong>" ]
			);
		}

		return placeholder;
	}
}
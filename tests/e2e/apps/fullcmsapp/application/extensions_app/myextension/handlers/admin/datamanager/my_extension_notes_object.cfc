component {

	private any function renderFooterForGridListing( event, rc, prc, args={} ) {
		return {
			  labelField = "label"
			, label      = "E2E column totals"
			, cells      = {
				  status   = "e2e-status-footer"
				, category = "e2e-category-footer"
				, notes    = "e2e-notes-footer"
			  }
		};
	}

}

component {

	public string function adminView( event, rc, prc, args={} ){
		return renderViewlet( event="admin.dataHelpers.relatedRecordsDatatable", args=args );
	}

}
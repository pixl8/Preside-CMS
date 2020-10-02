component {

	public string function adminView( event, rc, prc, args={} ){
		return renderView( view="/admin/datamanager/formbuilder_question/_formDataTable", args=args );
	}

}
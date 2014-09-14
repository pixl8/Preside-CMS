component output=false {

	public string function index( event, rc, prc, args={} ) output=false {
		args.control   = "objectPicker";
		args.object    = "link";
		args.quickAdd  = args.quickAdd ?: true;
		args.quickEdit = args.quickEdit ?: true;

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}

}
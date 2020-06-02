component {
	public string function index( event, rc, prc, args={} ) {
		args.currentValue = args.savedData[ args.name ] ?: "";

		return renderView( view="/formcontrols/cropHintPicker/index", args=args );
	}
}
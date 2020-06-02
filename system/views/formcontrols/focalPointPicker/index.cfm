<cfscript>
	inputName      = args.name            ?: "";
	inputId        = args.id              ?: "";
	inputClass     = args.class           ?: "";
	defaultValue   = args.currentValue    ?: "";
	extraClasses   = args.extraClasses    ?: "";
	assetId        = args.savedData.id    ?: "";
	showInput      = IsTrue( args.showInput ?: "" );
	rawValue       = IsTrue( args.rawValue  ?: "" );
	controlId      = createUUID();

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
	value = HtmlEditFormat( value );

	event.include( "/css/admin/specific/focalPointPicker/" );
	event.include( "/js/admin/specific/focalPointPicker/" );
</cfscript>


<cfoutput>
	<div class="focal-point-picker clearfix" id="focal-point-picker-#controlId#">
		<div class="focal-point-image-container">
			#renderAsset( assetId=assetId, args={ derivative="adminCropping", class="focal-point-image" } )#
			<span class="focal-point-crosshair"></span>
		</div>
		<div>
			<button type="button" class="btn btn-danger btn-sm focal-point-clear">
				<i class="fa fa-ban"></i>
				#translateResource( uri="formcontrols.focalPointPicker:clear" )#
			</button>
			<input type="hidden" class="#inputClass# focal-point-input #extraClasses#" name="#inputName#" id="#inputId#" value="#value#">
		</div>
	</div>
</cfoutput>

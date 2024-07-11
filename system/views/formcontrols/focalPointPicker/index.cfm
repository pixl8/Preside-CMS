<!---@feature presideForms and assetManager--->
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
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}
	value = HtmlEditFormat( value );

	event.include( "/css/admin/specific/focalPointPicker/" );
	event.include( "/js/admin/specific/focalPointPicker/" );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
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
			<input type="hidden" class="#inputClass# focal-point-input #extraClasses#" name="#inputName#" id="#inputId#" value="#value#" #htmlAttributes# />
		</div>
	</div>
</cfoutput>

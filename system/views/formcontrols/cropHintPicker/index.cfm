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

	event.include( "/css/admin/specific/cropHintPicker/" );
	event.include( "/js/admin/specific/cropHintPicker/" );

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>


<cfoutput>
	<div class="crop-hint-picker clearfix" id="crop-hint-picker-#controlId#">
		<div class="crop-hint-image-container">
			#renderAsset( assetId=assetId, args={ derivative="adminCropping", class="crop-hint-image" } )#
		</div>
		<div>
			<button type="button" class="btn btn-danger btn-sm crop-hint-clear">
				<i class="fa fa-ban"></i>
				#translateResource( uri="formcontrols.cropHintPicker:clear" )#
			</button>
			<input type="hidden" class="#inputClass# crop-hint-input #extraClasses#" name="#inputName#" id="#inputId#" value="#value#" #htmlAttributes# />
		</div>
	</div>
</cfoutput>

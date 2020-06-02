<cfscript>
	inputName      = args.name            ?: "";
	inputId        = args.id              ?: "";
	inputClass     = args.class           ?: "";
	defaultValue   = args.currentValue    ?: "";
	extraClasses   = args.extraClasses    ?: "";
	colours        = args.colours         ?: [];
	colourFormat   = args.colourFormat    ?: "";
	rowLength      = args.rowLength       ?: 16;
	paletteWidth   = ( rowLength * 27 ) + 30;
	showInput      = IsTrue( args.showInput ?: "" );
	rawValue       = IsTrue( args.rawValue  ?: "" );
	controlId      = createUUID();

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
	value = HtmlEditFormat( value );

	function formatCssColour(
		  required string  colour
		, required string  colourFormat
		,          boolean raw = false
	) {
		var rawColour = "";

		if ( colourFormat == "hex" ) {
			rawColour = replace( colour, "##", "", "all" );
			return raw ? rawColour : "###rawColour#";
		} else if ( colourFormat == "rgb" ) {
			rawColour = reReplace( colour, "^rgb\(([,0-9]+)\)$", "\1" );
			return raw ? rawColour : "rgb(#rawColour#)";
		}

		return "";
	}

	event.include( "/css/admin/specific/simpleColourPicker/" );
	event.include( "/js/admin/specific/simpleColourPicker/" );
</cfscript>



<cfoutput>
	<style type="text/css">
		##simple-colour-picker-#controlId# .popover {
			max-width : #paletteWidth#px;
		}
		##simple-colour-picker-#controlId# .popover .popover-content {
			padding : 14px;
		}
	</style>

	<div class="simple-colour-picker clearfix" data-colour-format="#colourFormat#" data-raw-values="#rawValue#" id="simple-colour-picker-#controlId#">
		<div class="selected-colour<cfif showInput> show-selected-colour-input</cfif>">
			<span class="selected-colour-swatch<cfif !len( value )> unselected</cfif>"<cfif len( value )> style="background-color:#formatCssColour( value, colourFormat )#;"</cfif>>
			</span>
			<input <cfif showInput>type="text" readonly<cfelse>type="hidden"</cfif> class="#inputClass# selected-colour-input" name="#inputName#" id="#inputId#" value="#value#">
		</div>
		<div class="available-colours hidden">
			<cfloop array="#colours#" index="i" item="colour">
				<cfset selected = ( value == colour ) />
				<span class="available-colour<cfif selected> selected</cfif>" data-value="#formatCssColour( colour, colourFormat, rawValue )#" title="#formatCssColour( colour, colourFormat, rawValue )#" style="background-color:#formatCssColour( colour, colourFormat )#;"></span>
			</cfloop>
			<a class="clear-selected-colour">#translateResource( uri="formcontrols.simpleColourPicker:clear" )#</a>
		</div>
	</div>
</cfoutput>
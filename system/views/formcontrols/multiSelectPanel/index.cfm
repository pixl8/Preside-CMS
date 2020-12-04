<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "form-control";
	extraClasses = args.extraClasses ?: "";
	sortable     = args.sortable     ?: false;
	selectSize   = args.selectSize   ?: "";
	defaultValue = args.defaultValue ?: "";
	values       = args.values       ?: "";
	labels       = ( structKeyExists( args, "labels") && len( args.labels ) ) ? args.labels : args.values;

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	event.include( "/css/admin/specific/multiSelectPanel/" )
	     .include( "/js/admin/specific/multiSelectPanel/"  );
</cfscript>

<cfoutput>
	<cfif !isEmpty( values )>
		<div class="row multi-select-panel" id="#inputId#">
			<div class="col-xs-4">
				#renderView( view="/formcontrols/multiSelectPanel/_availableOptions", args=args )#
			</div>

			<div class="col-xs-3 action-buttons">
				#renderView( view="/formcontrols/multiSelectPanel/_actionButtons", args=args )#
			</div>

			<div class="col-xs-<cfif isTrue( sortable )>4<cfelse>5</cfif>">
				#renderView( view="/formcontrols/multiSelectPanel/_selectedOptions", args=args )#
			</div>

			<cfif isTrue( sortable )>
				<div class="col-xs-1 sorting-buttons">
					#renderView( view="/formcontrols/multiSelectPanel/_sortingPanel", args=args )#
				</div>
			</cfif>
		</div>

		<input type="hidden" id="#inputId#" name="#inputName#" value="#value#" />
	</cfif>
</cfoutput>
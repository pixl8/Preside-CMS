<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	exporters    = args.exporters    ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( value == "" ) {
		value = exporters[ 1 ].id;
	}
</cfscript>

<cfoutput>
	<cfloop array="#exporters#" index="exporter">
		<div class="radio">
			<label>
				<input class="#inputClass# radio" name="#inputName#" id="#inputId#-#exporter.id#" type="radio"  value="#HtmlEditFormat( exporter.id )#"<cfif ListFindNoCase( value, exporter.id )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="title bigger">
						<i class="fa fa-fw #exporter.iconClass#"></i>
						<strong>#exporter.title#</strong>
					</span><br />
					<span class="desc grey">
						<em>#exporter.description#</em>
					</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>
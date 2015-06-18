<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue	  ;

	if(isEmpty(defaultValue)) {
		defaultValue = now();
	}

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( IsDate( value ) ) {
		valueDateTime 	= DateTimeFormat( value, "yyyy-mm-dd HH:nn" )
		valueDate 		= DateFormat( value, "yyyy-mm-dd" );
		valueHour 		= Hour(value);
		valueMin  		= Minute(value);
	}

</cfscript>


<cfoutput>
	<div class="row">
		<input name="#inputName#" id="#inputId#" hidden class="#inputId# date-time-picker" value="#HtmlEditFormat( valueDateTime )#" />

		<div class="col-md-3">
			<input name="#inputName#_date" placeholder="#placeholder#" class="date-picker" id="#inputId#_date" type="text" data-date-format="yyyy-mm-dd" value="#HtmlEditFormat( valueDate )#" tabindex="#getNextTabIndex()#" style="width:100%"/>
		</div>
		<div class="col-md-5">
			<select id="#inputId#_hour" name="#inputName#_hour" class="time-picker-hour">
				<cfloop from = "0" to = "23" index="hour">
					<cfset hour = NumberFormat(hour,"00" )/>
					<option value="#hour#" <cfif hour EQ valueHour>selected</cfif> >#hour#</option>
				</cfloop>
			</select>
			:
			<select id="#inputId#_min" name="#inputName#_min" class="time-picker-min">
				<cfloop from = "0" to = "59" index="min">
					<cfset min = NumberFormat(min,"00" )/>
					<option value="#min#" <cfif min EQ valueMin>selected</cfif> >#min#</option>
				</cfloop>
			</select>
			&nbsp <i class="fa fa-clock-o"></i>
		</div>
	</div>
</cfoutput>
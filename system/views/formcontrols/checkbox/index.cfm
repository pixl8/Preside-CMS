<cfscript>
	inputName    = args.name          ?: "";
	inputId      = args.id            ?: "";
	inputClass   = args.class         ?: "";
	defaultValue = args.defaultValue  ?: "";
	labels       = !isEmptyString( args.checkboxLabel ?: "" ) ? translateResource( args.checkboxLabel ?: "", args.checkboxLabel ?: "" ) : ( args.label ?: "" );
	value        = event.getValue( name=inputName, defaultValue=defaultValue );
	checked      = isTrue( value );
</cfscript>

<cfoutput>
	<div class="checkbox">
		<label>
			<input type="checkbox" id="#inputId#" name="#inputName#" value="1" class="#inputClass#" tabindex="#getNextTabIndex()#" <cfif checked>checked</cfif> >
			#labels#
		</label>
	</div>
</cfoutput>
<!---
	Core String helper methods that will be available to handlers and views
--->

<cffunction name="abbreviate" returntype="string" output="false">
	<cfargument name="string"          type="string"  required="true" />
	<cfargument name="len"             type="numeric" required="true" />
	<cfargument name="allowWordCutoff" type="boolean" required="false" default="false" />
	<cfargument name="addTitleSpan"    type="boolean" required="false" default="false" />

	<cfscript>
		var newString = Trim( ReReplace(string, "<[^>]*>", " ", "ALL") );
		var lastSpace = 0;

		newString = ReReplace(newString, " \s*", " ", "ALL");

		if ( len( newString ) gt len ) {
			len = len - 3; // to compensate for the elipses space
			if ( allowWordCutoff ) {
				newString = Trim( Left( newString, len ) );
			} else {
				newString = Left( newString, len-2 );
				lastSpace = Find( " ", Reverse( newString ) );
				lastSpace = Len( newString ) - lastSpace;
				newString = Left( newString, lastSpace );
			}

			newString = newString & "  &##8230;";

			if ( addTitleSpan ) {
				newString = '<span title="#string#">#newString#</span>';
			}
		}

		return newString;
	</cfscript>
</cffunction>

<cffunction name="fileSizeFormat" access="public" returntype="string" output="false">
	<cfargument name="fileSizeInBytes" type="numeric" required="true" />
	<cfargument name="locale"          type="string"  required="false" default="#getController().getWireBox().getInstance( "i18n" ).getfwLocale()#" />

	<cfscript>
		var units   = [ "bytes", "KB", "MB", "GB", "TB", "PB" ];
		var size    = arguments.fileSizeInBytes;
		var index   = 1;
		var mask    = "_,.0";

		while( size > 1024 && index lt units.len() ) {
			index++;
			size = size / 1024;
		}
		if ( size gt 10 ) {
			mask = "_,";
		}

		return LSNumberFormat( size, mask, arguments.locale  ) & " " & units[index];
	</cfscript>

</cffunction>

<cffunction name="isEmptyString" access="public" returntype="boolean" output="false">
	<cfargument name="stringValue" type="string" required="true" />
	<cfreturn !Len( Trim( arguments.stringValue ) ) />
</cffunction>

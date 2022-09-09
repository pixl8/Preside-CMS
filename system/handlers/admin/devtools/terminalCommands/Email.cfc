component hint="Manage Preside email templates" extends="preside.system.base.Command" {

	property name="jsonRpc2"                   inject="JsonRpc2";
	property name="templates"                  inject="coldbox:setting:email.templates";
	property name="systemEmailTemplateService" inject="SystemEmailTemplateService";
	property name="emailTemplateService"       inject="EmailTemplateService";

	private function index( event, rc, prc ) {
		var params          = jsonRpc2.getRequestParams();
		var validOperations = [ "list", "reset" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !ArrayLen( params ) || !ArrayFindNoCase( validOperations, params[ 1 ] ) ) {
			var message = newLine();

			message &= writeText( text="Usage: ", type="info", bold=true );
			message &= writeText( "email [operation]" );
			message &= newLine();

			message &= writeText( "Valid operations:" );
			message &= newLine();

			message &= writeText( text="    list [template\]", type="info", bold=true );
			message &= writeText( text=": Lists system email template.", newLine=true );

			message &= writeText( text="    reset template", type="info", bold=true );
			message &= writeText( text=": Reset system email template to default content.", newLine=true );

			return message;
		}

		return runEvent(
			  event          = "admin.devtools.terminalCommands.email.#params[ 1 ]#"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				args = {
					params = params
				}
			  }
		);
	}

	private any function list( event, rc, prc, args ) {
		var message = newLine();
		var titles  = "";

		var idWidth    = 2;
		var titleWdith = 5;

		var systemTemplates   = systemEmailTemplateService.listTemplates();
		var filteredTemplates = StructNew();
		var filter            = args.params[ 2 ] ?: "";

		if ( Len( Trim( filter ) ) ) {
			for ( var template in systemTemplates ) {
				if ( ArrayLen( ReMatchNoCase( filter, template.id ) ) > 0 ) {
					filteredTemplates[ template.id ] = template;
				}
			}
		} else {
			for ( var template in systemTemplates ) {
				filteredTemplates[ template.id ] = template;
			}
		}

		if ( StructCount( filteredTemplates ) > 0 ) {
			for ( var id in filteredTemplates ) {
				if ( Len( id ) > idWidth ) {
					idWidth = Len( id );
				}

				if ( Len( filteredTemplates[ id ].title ) > titleWdith ) {
					titleWdith = Len( filteredTemplates[ id ].title );
				}
			}

			titles &= "  ID " & RepeatString( " ", idWidth-2 );
			titles &= "  Title " & RepeatString( " ", titleWdith-5 );

			message &= writeText( text=titles, newLine=true );
			message &= writeLine( length=Len( titles ), character="=" );

			var sortedTemplates = StructSort( filteredTemplates, "textnocase", "asc", "id" );

			for ( var id in sortedTemplates ) {
				message &= writeText( text="  #id# " & RepeatString( " ", idWidth-Len( id ) ), type="info", bold=true );

				message &= writeText( text="  " & filteredTemplates[ id ].title, newLine=true );
			}

			message &= writeLine( Len( titles ) );
		} else {
			message &= writeText( text="No system email templates found.", newLine=true );
		}

		return message;
	}

	private any function reset( event, rc, prc, args ) {
		var message = newLine();

		var template = args.params[ 2 ] ?: "";

		if ( Len( Trim( template ) ) ) {
			if ( systemEmailTemplateService.templateExists( template=template ) ) {
				systemEmailTemplateService.resetTemplate( template=template );

				message &= writeText( text="System email template '#template#' content has been reset.", newLine=true, type="info" );
			} else {
				message &= writeText( text="System email template '#template#' not found.", newLine=true, type="warn" );
			}
		} else {
			message &= writeText( text="Please specify the system email template.", newLine=true );
		}

		return message;
	}

}
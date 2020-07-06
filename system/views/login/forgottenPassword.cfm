<cfparam name="args.title"                                    field="page.title" editable="true" />
<cfparam name="args.loginId_not_found"                        field="forgotten_password.loginId_not_found"                       default="Sorry, your email address is not found in the system." />
<cfparam name="args.invalid_reset_token"                      field="forgotten_password.invalid_reset_token"                     default="Invalid reset token." />
<cfparam name="args.password_reset_instructions_sent"         field="forgotten_password.password_reset_instructions_sent"        default="Instructions for setting your password have been sent to your registered email account." />
<cfparam name="args.newer_token_was_generated_error_message"  field="forgotten_password.newer_token_was_generated_error_message"        default="Your reset password link has expired because a new one was generated at ${latestTokenDate}" />
<cfparam name="args.last_password_updated_error_message"      field="forgotten_password.last_password_updated_error_message"            default="Your reset password link is no longer valid as you successfully set your password at ${lastPasswordUpdated}" />
<cfparam name="args.next_reset_password_allowed_error_message"field="forgotten_password.next_reset_password_allowed_error_message"      default="You have not allow to reset password again within next ${nextResetPasswordAllowedXMinutes} minute(s)" />

<cfparam name="rc.loginId" default="" />
<cfparam name="rc.message" default="" />

<cfoutput>
    <h1>#args.title#</h1>

    <cfswitch expression="#rc.message#">
        <cfcase value="LOGINID_NOT_FOUND">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.loginId_not_found ) )>
                    #args.loginId_not_found#
                <cfelse>
                    #translateResource( 'cms:forgottenpassword.loginid.notfound.error' )#
                </cfif>
            </div>
        </cfcase>
        <cfcase value="INVALID_RESET_TOKEN">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.invalid_reset_token ) )>
                    #args.invalid_reset_token#
                <cfelse>
                    #translateResource( 'cms:forgottenpassword.invalid.reset.token.error' )#
                </cfif>
            </div>
        </cfcase>
        <cfcase value="NEWER_TOKEN_WAS_GENERATED">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.newer_token_was_generated_error_message ) )>
                    <cfset errorMessage = args.newer_token_was_generated_error_message>
                <cfelse>
                    <cfset errorMessage = translateResource( 'cms:forgottenpassword.newer_token_was_generated.error' )>
                </cfif>
                #Replace( errorMessage, "${latestTokenDate}", rc.latestTokenDate )#
            </div>
        </cfcase>

        <cfcase value="LAST_PASSWORD_UPDATED">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.last_password_updated_error_message ) )>
                    <cfset errorMessage = args.last_password_updated_error_message>
                <cfelse>
                    <cfset errorMessage = translateResource( 'cms:forgottenpassword.last_password_updated.error' )>
                </cfif>
                #Replace( errorMessage, "${lastPasswordUpdated}", rc.lastPasswordUpdated )#
            </div>
        </cfcase>
        <cfcase value="NEXT_RESET_AFTER_X_MINUTES">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.next_reset_password_allowed_error_message ) )>
                    <cfset errorMessage = args.next_reset_password_allowed_error_message>
                <cfelse>
                    <cfset errorMessage = translateResource( 'cms:forgottenpassword.next_reset_password_allowed.error' )>
                </cfif>
                #Replace( errorMessage, "${nextResetPasswordAllowedXMinutes}", rc.nextResetPasswordAllowedXMinutes )#
            </div>
        </cfcase>
    </cfswitch>

    <form action="#event.buildLink( linkTo='login.sendResetInstructions' )#" method="post">
        <div class="form-group">
            <label for="loginIdField">#translateResource( uri="page-types.forgotten_password:emailaddress.label" )#</label>
            <input type="email" class="form-control" name="loginId" id="loginIdField">
        </div>

        <div class="form-group">
            <p><a href="#event.buildLink( page="login" )#">#translateResource( uri="page-types.forgotten_password:returnToLoginLink.title" )#</a></p>
            <button type="submit" class="btn btn-danger">#translateResource( uri="page-types.forgotten_password:submitButton.title" )#</button>
        </div>
    </form>
</cfoutput>
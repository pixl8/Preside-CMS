<cfparam name="args.title"                            field="page.title" editable="true" />
<cfparam name="args.loginId_not_found"                field="forgotten_password.loginId_not_found" default="Sorry, your email address is not found in the system." />
<cfparam name="args.invalid_reset_token"              field="forgotten_password.invalid_reset_token" default="Invalid reset token." />
<cfparam name="args.password_reset_instructions_sent" field="forgotten_password.password_reset_instructions_sent" default="Instructions for setting your password have been sent to your registered email account." />

<cfparam name="rc.loginId" default="" />
<cfparam name="rc.message" default="" />

<cfoutput>
    <h1>#args.title#</h1>

    <cfswitch expression="#rc.message#">
        <cfcase value="LOGINID_NOT_FOUND">
            <div class="alert alert-danger" role="alert">#args.loginId_not_found#</div>
        </cfcase>
        <cfcase value="INVALID_RESET_TOKEN">
            <div class="alert alert-danger" role="alert">#args.invalid_reset_token#</div>
        </cfcase>
        <cfcase value="PASSWORD_RESET_INSTRUCTIONS_SENT">
            <div class="alert alert-success" role="alert">#args.password_reset_instructions_sent#</div>
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
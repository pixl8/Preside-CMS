<!---
	The direct /login/ 'page' is just a proxy to the 'login.loginPage' viewlet.
	This seems absurd; however, this allows us to render the login/loginPage viewlet from
	secured pages by using renderViewlet() and passing specific arguments, such as "notification message"
 --->
<cfoutput>#renderViewlet( "login.loginPage" )#</cfoutput>
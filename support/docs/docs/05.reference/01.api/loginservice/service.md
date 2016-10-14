---
id: "api-loginservice"
title: "Admin login service"
---


## Overview




Service class to provide API methods related to
CMS admin login and user sessions. See [[cmspermissioning]]
for a full guide to CMS admin users.<div class="table-responsive"><table class="table table-condensed"><tr><th>Full path</th><td>preside.system.services.admin.LoginService</td></tr><tr><th>Wirebox ref</th><td>LoginService</td></tr><tr><th>Singleton</th><td>Yes</td></tr></table></div>

## Public API Methods

* [[loginservice-login]]
* [[loginservice-ispasswordcorrect]]
* [[loginservice-logout]]
* [[loginservice-isloggedin]]
* [[loginservice-getloggedinuserdetails]]
* [[loginservice-getloggedinuserid]]
* [[loginservice-issystemuser]]
* [[loginservice-sendpasswordresetinstructions]]
* [[loginservice-sendwelcomeemail]]
* [[loginservice-createloginresettoken]]
* [[loginservice-validateresetpasswordtoken]]
* [[loginservice-resetpassword]]
* [[loginservice-recordlogin]]
* [[loginservice-recordlogout]]
* [[loginservice-recordvisit]]
* [[loginservice-twofactorauthenticationrequired]]
* [[loginservice-istwofactorauthenticated]]
* [[loginservice-gettwofactorauthenticationkey]]
* [[loginservice-istwofactorauthenticationsetupforuser]]
* [[loginservice-istwofactorauthenticationenabled]]
* [[loginservice-istwofactorauthenticationenabledforuser]]
* [[loginservice-generatetwofactorauthenticationkey]]
* [[loginservice-attempttwofactorauthentication]]
* [[loginservice-enabletwofactorauthenticationforuser]]
* [[loginservice-disabletwofactorauthenticationforuser]]
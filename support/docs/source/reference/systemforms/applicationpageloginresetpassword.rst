Application Page: Login > Reset Password
========================================

*/forms/application-pages/login.resetPassword.xml*

\n
This form is used as the default configuration for a reset password page. Right now, all it does is remove the 'Access control' tab so that users cannot accidentally restrict access to the login page!

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="access" deleted="true" />
    </form>


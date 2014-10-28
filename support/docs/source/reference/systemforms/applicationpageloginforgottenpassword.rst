Application Page: Login > Forgotten password
============================================

*/forms/application-pages/login.forgottenPassword.xml*

\n
This form is used as the default configuration for a forgotten password page. Right now, all it does is remove the 'Access control' tab so that users cannot accidentally restrict access to the login page!

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="access" deleted="true" />
    </form>


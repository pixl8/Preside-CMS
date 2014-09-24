Email service
=============

Overview
--------

**Full path:** *preside.system.services.email.EmailService*

The email service takes care of sending emails through the PresideCMS's email templating system (see :doc:`/devguides/emailtemplates`).

Public API Methods
------------------

.. _emailservice-send:

Send()
~~~~~~

.. code-block:: java

    public boolean function send( string template="", struct args, array to, string from="", string subject="", array cc, array bcc, string htmlBody="", string textBody="", struct params )

Sends an email. If a template is supplied, first runs the template handler which can return a struct that will override any arguments
passed directly to the function

Arguments
.........

========  ======  ===============  ==============================================================================
Name      Type    Required         Description                                                                   
========  ======  ===============  ==============================================================================
template  string  No (default="")  Name of the template who's handler will do the rendering, etc.                
args      struct  No               Structure of arbitrary arguments to forward on to the template handler        
to        array   No               Array of email addresses to send the email to                                 
from      string  No (default="")  Optional from email address                                                   
subject   string  No (default="")  Optional email subject. If not supplied, the template handler should supply it
cc        array   No               Optional array of CC addresses                                                
bcc       array   No               Optional array of BCC addresses                                               
htmlBody  string  No (default="")  Optional HTML body                                                            
textBody  string  No (default="")  Optional plain text body                                                      
params    struct  No               Optional struct of cfmail params (headers, attachments, etc.)                 
========  ======  ===============  ==============================================================================


.. _emailservice-listtemplates:

ListTemplates()
~~~~~~~~~~~~~~~

.. code-block:: java

    public array function listTemplates( )

Returns an array of email templates that have been dicovered from the /handlers/emailTemplates
directory

Arguments
.........

*This method does not accept any arguments.*
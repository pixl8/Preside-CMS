---
id: "emailservice-send"
title: "send()"
---


## Overview




```luceescript
public boolean function send(
      string template = ""
    , struct args    
    , array  to      
    , string from     = ""
    , string subject  = ""
    , array  cc      
    , array  bcc     
    , string htmlBody = ""
    , string textBody = ""
    , struct params  
)
```

Sends an email. If a template is supplied, first runs the template handler which can return a struct that will override any arguments
passed directly to the function

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>template</td><td>string</td><td>No (default="")</td><td>Name of the template who's handler will do the rendering, etc.</td></tr><tr><td>args</td><td>struct</td><td>No</td><td>Structure of arbitrary arguments to forward on to the template handler</td></tr><tr><td>to</td><td>array</td><td>No</td><td>Array of email addresses to send the email to</td></tr><tr><td>from</td><td>string</td><td>No (default="")</td><td>Optional from email address</td></tr><tr><td>subject</td><td>string</td><td>No (default="")</td><td>Optional email subject. If not supplied, the template handler should supply it</td></tr><tr><td>cc</td><td>array</td><td>No</td><td>Optional array of CC addresses</td></tr><tr><td>bcc</td><td>array</td><td>No</td><td>Optional array of BCC addresses</td></tr><tr><td>htmlBody</td><td>string</td><td>No (default="")</td><td>Optional HTML body</td></tr><tr><td>textBody</td><td>string</td><td>No (default="")</td><td>Optional plain text body</td></tr><tr><td>params</td><td>struct</td><td>No</td><td>Optional struct of cfmail params (headers, attachments, etc.)</td></tr></tbody></table></div>
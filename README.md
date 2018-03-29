# Remove information to manually 'code sign' from Xcode Project.

Rewrite information for 'manual signing' included in Xcode Project into information suitable for 'automatic signing'.

This script can be used when you want to take a project set for 'manual signing' located in githib etc and compile with 'automatic signing' forcibly with CI tool etc.

It was a very dirty code as I quickly wrote it up in a hurry.
Also carefully that Xcode Project will be converted to XML format regardless of input format.

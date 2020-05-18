
# values.yaml file pre-install validation 

## Introduction

We allow PSO users to provide their version of values.yaml, then merging the provided key-value pairs with the default values.yaml under pure-csi directory.
One imrpovement that was identified from past experience is that by adding a validation before installation, some of the common errors users have encountered
can be eliminated. For example, FlashArrays and FlashBlades property are completely provided by users, without validations, it was possible for users to inject
unwanted charcters in their endpoint or token, or provid a different object type than intended. With Helm 3 now becoming the standard, we leverage the JSON 
validation functionality and added validation based on need of our backend, while at the same time, making it easier for our users to identify some issues 
early on. 

## Restrictions
JSON validation is by default case-sensitive, so we kindly ask users to be mindful when writing their own values.yaml files. We recommend copy directly from our
default file and change only the values, but not the keys. Otherwise, users will likely see validation errors at runtime. 

## How does it work? 
There is no extra tasks that users need to perform. Both 
```bash
helm update
helm upgrade
```
will trigger the validation, and validation will not continue if errors are thrown. 

It is also possible that the eixsting values.yaml users have been using will complain for the first time if cases of keys do not match. For example, "NFSEndPoint"
is a required property under "FlashBlades", but providing the key as "nfsEndPoint" or "NfsEndPoint" will not pass the validation. 

If running into problems installing due to failing validation you you believe you have provided valid inputs, please reach out to PSO team. 
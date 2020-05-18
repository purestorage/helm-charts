
# values.yaml file pre-install validation 

## Introduction

We allow PSO users to provide their version of values.yaml, then merging the provided key-value pairs with the default values.yaml under pure-csi directory. One improvement that was identified from past experience is that by adding a validation before installation, some of the common errors users have encountered can be eliminated. For example, We rely on users to provide FlashArrays and FlashBlades properties, without validations, it was possible for users to inject unwanted characters in their endpoint or APItoken, or even provide a different object type than intended. With Helm 3 now becoming the standard, we leverage the JSON validation functionality and added validation based on need of our backend, while at the same time, making it easier for our users to identify some issues early on. 

## Restrictions
JSON validation is by default case-sensitive, so we kindly ask users to be mindful when writing their own values.yaml files. We recommend copy directly from our default file and change only the values, but not the keys. Otherwise, users will likely see validation errors at runtime. 

## How does it work? 
Under normal curcumstances, there are no extra tasks that users need to perform. Both 
```bash
helm install
helm upgrade
```
will trigger the validation, and installation will not continue if errors are thrown. 

It is also possible that the existing values.yaml users have been using will complain for the first time if cases of keys do not match. For example, "NFSEndPoint" is a required property under FlashBlades, but providing the key as "nfsEndPoint" or "NfsEndPoint" will not pass the validation. 

If running into problems installing due to failing validation and you believe valid inputs have been provided, please reach out to the PSO team. 


 
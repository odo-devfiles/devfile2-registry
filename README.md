# DEPRECATED
All Devfiles in this repository were moved to a new repository https://github.com/devfile/registry.
https://github.com/devfile/registry is now an official Devfile v2 registry.
Odo was updated to use the official Devfile registry as a default registry.
If you want to submit new Devfile or update existing one please do it in https://github.com/devfile/registry.



## devfiles registry


A repository for storing sample devfiles using devfile 2.0 specifications for odo and others

### regenerate index.json

```
cd tools
go run cmd/index/index.go -devfiles-dir ../devfiles -index ../devfiles/index.json
```

### Reporting any issue

- Use the [openshift/odo](https://github.com/openshift/odo) repository's issue tracker for opening issues related to registry. apply `area/registry` label for registry related issues for better visibility.

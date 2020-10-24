# devfiles registry

A repository for storing sample devfiles using devfile 2.0 specifications for odo and others

## regenerate index.json

```
cd tools
go run cmd/index/index.go -devfiles-dir ../devfiles -index ../devfiles/index.json
```


## Reporting any issue

- Use the [openshift/odo](https://github.com/openshift/odo) repository's issue tracker for opening issues related to registry. apply `area/registry` label for registry related issues for better visibility.

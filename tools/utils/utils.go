package utils

import (
	"io/ioutil"

	"github.com/ghodss/yaml"
	"github.com/odo-devfiles/registry/tools/types"
)

const (
	runGroup = "run"
)

// IsDevfileSupported checks if devfile v2 is supported
func IsDevfileSupported(devfile types.Devfile) bool {

	hasComponentContainer := false
	hasComponentContainerName := false
	hasRunGroupCommand := false

	for _, component := range devfile.Components {
		if hasComponentContainer && hasComponentContainerName {
			break
		}

		if !hasComponentContainer {
			hasComponentContainer = component.Container != nil
		}

		if hasComponentContainer && !hasComponentContainerName {
			hasComponentContainerName = len(component.Container.Name) > 0
		}
	}

	for _, command := range devfile.Commands {

		if !hasRunGroupCommand {
			hasRunGroupCommand = command.Exec != nil && command.Exec.Group != nil && command.Exec.Group.Kind == runGroup
		}
	}

	if hasComponentContainer && hasComponentContainerName && hasRunGroupCommand {
		return true
	}

	return false
}

// GetDevfile reads the devfile from the path and returns the devfile struct
func GetDevfile(devfilePath string) (types.Devfile, error) {
	var devfile types.Devfile
	devFilePath, err := ioutil.ReadFile(devfilePath)
	if err != nil {
		return types.Devfile{}, err
	}
	err = yaml.Unmarshal(devFilePath, &devfile)
	if err != nil {
		return types.Devfile{}, err
	}

	return devfile, nil
}

// GetMeta reads the meta.yaml and returns the meta struct
func GetMeta(metafilePath string) (types.Meta, error) {
	var meta types.Meta
	metaFilePath, err := ioutil.ReadFile(metafilePath)
	if err != nil {
		return types.Meta{}, err
	}
	err = yaml.Unmarshal(metaFilePath, &meta)
	if err != nil {
		return types.Meta{}, err
	}

	return meta, nil
}

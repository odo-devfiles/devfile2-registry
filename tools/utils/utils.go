package utils

import (
	"io/ioutil"

	"github.com/odo-devfiles/registry/tools/types"
	"gopkg.in/yaml.v2"
)

const (
	runGroup = "run"
)

// isContainerPresent checks if the devfile has a supported container component
func isContainerPresent(devfile types.Devfile) bool {
	hasSupportedContainer := false

	for _, component := range devfile.Components {
		if component.Container != nil && component.Container.Name != "" {
			hasSupportedContainer = true
			break
		}
	}

	return hasSupportedContainer
}

// isRunGroupPresent checks if the devfile has a run group command
func isRunGroupCommandPresent(devfile types.Devfile) bool {
	hasRunGroupCommand := false

	for _, command := range devfile.Commands {
		if command.Exec != nil && command.Exec.Group != nil && command.Exec.Group.Kind == runGroup {
			hasRunGroupCommand = true
			break
		}
	}

	return hasRunGroupCommand
}

// IsDevfileSupported checks if devfile v2 is supported
func IsDevfileSupported(devfile types.Devfile) bool {

	hasSupportedContainer := isContainerPresent(devfile)
	hasRunGroupCommand := isRunGroupCommandPresent(devfile)

	return hasSupportedContainer && hasRunGroupCommand
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

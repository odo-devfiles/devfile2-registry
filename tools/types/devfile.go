package types

// Metadata holds the meta information in the devfile
type Metadata struct {
	Name string `yaml:"name"`
}

// Container holds the container information of a component in the devfile
type Container struct {
	Name string `yaml:"name"`
}

// Component holds the component information in the devfile
type Component struct {
	Container *Container `yaml:"container"`
}

// Group holds the command group information in the devfile
type Group struct {
	Kind string `yaml:"kind"`
}

// Exec holds the command exec type information in the devfile
type Exec struct {
	Group *Group `yaml:"group"`
}

// Command holds the command information in the devfile
type Command struct {
	Exec *Exec `yaml:"exec"`
}

// Devfile is the necessary structure of devfile for checking if devfile is supported
type Devfile struct {
	APIVersion string      `yaml:"apiVersion"`
	MetaData   Metadata    `yaml:"metadata"`
	Components []Component `yaml:"components"`
	Commands   []Command   `yaml:"commands"`
}

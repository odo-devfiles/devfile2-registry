package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"

	"github.com/odo-devfiles/registry/tools/types"
	"github.com/odo-devfiles/registry/tools/utils"
)

const (
	metafileName = "meta.yaml"
	devfileName  = "devfile.yaml"
)

// genIndex generate new index from meta.yaml files in dir.
// meta.yaml file is expected to be in dir/<devfiledir>/meta.yaml
func genIndex(dir string) ([]types.MetaIndex, error) {

	var index []types.MetaIndex

	dirs, err := ioutil.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	for _, file := range dirs {
		if file.IsDir() {
			// Read the meta.yaml
			meta, err := utils.GetMeta(filepath.Join(dir, file.Name(), metafileName))
			if err != nil {
				return nil, err
			}

			// Read the devfile.yaml
			devfile, err := utils.GetDevfile(filepath.Join(dir, file.Name(), devfileName))
			if err != nil {
				return nil, err
			}

			isSupported := utils.IsDevfileSupported(devfile)

			self := fmt.Sprintf("/%s/%s/%s", filepath.Base(dir), file.Name(), devfileName)
			metaIndex := types.MetaIndex{
				Meta:      meta,
				Supported: isSupported,
				Links: types.Links{
					Self: self,
				},
			}
			index = append(index, metaIndex)
		}
	}
	return index, nil
}

func main() {
	devfiles := flag.String("devfiles-dir", "", "Directory containing devfiles.")
	output := flag.String("index", "", "Index filename. This is where the index in JSON format will be saved.")

	flag.Parse()

	if *devfiles == "" {
		log.Fatal("Provide devfile directory.")
	}

	if *output == "" {
		log.Fatal("Provide index file.")
	}

	index, err := genIndex(*devfiles)
	if err != nil {
		log.Fatal(err)
	}
	b, err := json.MarshalIndent(index, "", "  ")
	if err != nil {
		log.Fatal(err)

	}
	err = ioutil.WriteFile(*output, b, 0644)
	if err != nil {
		log.Fatal(err)

	}
}

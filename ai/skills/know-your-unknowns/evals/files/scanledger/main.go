package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	tags := flag.String("tags", "TODO,FIXME,HACK", "comma-separated marker tags to scan for")
	flag.Parse()

	root := "."
	if flag.NArg() > 0 {
		root = flag.Arg(0)
	}

	findings, err := Scan(root, splitTags(*tags))
	if err != nil {
		fmt.Fprintf(os.Stderr, "scanledger: %v\n", err)
		os.Exit(1)
	}

	PrintReport(os.Stdout, root, findings)
}

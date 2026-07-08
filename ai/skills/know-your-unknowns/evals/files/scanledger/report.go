package main

import (
	"fmt"
	"io"
	"text/tabwriter"
)

// TODO: support sorting findings by tag severity
// PrintReport writes a human-readable table of findings to w.
func PrintReport(w io.Writer, root string, findings []Finding) {
	if len(findings) == 0 {
		fmt.Fprintf(w, "scanledger: no markers found under %s\n", root)
		return
	}

	tw := tabwriter.NewWriter(w, 0, 4, 2, ' ', 0)
	fmt.Fprintln(tw, "TAG\tLOCATION\tTEXT")
	for _, f := range findings {
		fmt.Fprintf(tw, "%s\t%s:%d\t%s\n", f.Tag, f.File, f.Line, f.Text)
	}
	tw.Flush()

	fmt.Fprintf(w, "\n%d markers found under %s\n", len(findings), root)
}

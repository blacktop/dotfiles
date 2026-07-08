package main

import (
	"bufio"
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Finding is one marker comment located in the scanned tree.
type Finding struct {
	File string
	Line int
	Tag  string
	Text string
}

func splitTags(s string) []string {
	var tags []string
	for t := range strings.SplitSeq(s, ",") {
		t = strings.TrimSpace(t)
		if t != "" {
			tags = append(tags, t)
		}
	}
	return tags
}

// FIXME: tag matching is case-sensitive; "todo:" comments are missed
// Scan walks root and collects marker comments matching the given tags.
func Scan(root string, tags []string) ([]Finding, error) {
	re := regexp.MustCompile(`(?://|#|/\*)\s*(` + strings.Join(tags, "|") + `)[:\s](.*)`)

	var findings []Finding
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			name := d.Name()
			if name == ".git" || name == "node_modules" || name == "vendor" {
				return filepath.SkipDir
			}
			return nil
		}
		return scanFile(path, re, &findings)
	})
	return findings, err
}

func scanFile(path string, re *regexp.Regexp, findings *[]Finding) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	lineNo := 0
	for scanner.Scan() {
		lineNo++
		m := re.FindStringSubmatch(scanner.Text())
		if m == nil {
			continue
		}
		*findings = append(*findings, Finding{
			File: path,
			Line: lineNo,
			Tag:  m[1],
			Text: strings.TrimSpace(m[2]),
		})
	}
	if err := scanner.Err(); err != nil {
		if errors.Is(err, bufio.ErrTooLong) {
			return nil // likely a binary file; skip it
		}
		return err
	}
	return nil
}

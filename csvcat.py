#!/usr/bin/env python3
#
# Concatenate multiple .CSV files into a single CSV
#
# Intelligently look at headers that may vary from one file to another
# and insert empty cells where appropriate.
#
# Nate Case
#

import sys
import csv
import argparse

def main(args):

    all_rows = []
    row_set = set([])
    colnames = []
    for f in args.csvfile:
        with f as csv_file:
            vitalreader = csv.DictReader(csv_file, delimiter=',')
            #colnames.update(set(vitalreader.fieldnames))
            for field in vitalreader.fieldnames:
                if not field in colnames:
                    colnames.append(field)
            for row in vitalreader:
                r = repr(row)
                is_dupe = r in row_set
                if (not is_dupe) or args.keep_dupes:
                    all_rows.append(row)
                    row_set.add(r)

    for i, col in enumerate(colnames):
        end = "\n" if (i == len(colnames) - 1) else ","
        print(col, end=end)

    for y, row in enumerate(all_rows):
        for x, col in enumerate(colnames):
            end = "\n" if (x == len(colnames) - 1) else ","
            print(row[col], end=end)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-k", "--keep-dupes", help="Keep duplicate rows",
                        action="store_true")
    parser.add_argument('csvfile', type=argparse.FileType('r'), nargs='+',
                        help=".CSV input filename")

    args = parser.parse_args()

    main(args)

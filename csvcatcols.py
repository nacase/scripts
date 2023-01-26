#!/usr/bin/env python3
#
# WARNING: KINDA BROKEN FOR CASES WHERE ALL FILES DON'T HAVE IDENTICAL
# COLUMN 1 INDICES
#
# Concatenate multiple .CSV files into a single CSV by column
#
# Index by the first column, keeping all input files together on
# a single row in the output file when their first column values match.
#
# No duplicate index values allowed within an input file
#
# Example:
#
#   File1.csv:
#       Date,Value1,Value2
#       1/1/2000,"dead","beef"
#       5/5/2000,"feed","f00f"
#
#   File2.csv:
#       Date,Value1,Value2
#       1/1/2000,"foo","bar"
#       2/2/2000,"aaa","zzz"
#       5/5/2000,"abc","123"
#
#   Output:
#       Date,Value1,Value2,Value1,Value2
#       1/1/2000,"dead","beef","foo","bar"
#       2/2/2000,"","","aaa","zzz"
#       5/5/2000,"feed","f00f","abc","123"
#
# Nate Case
#

import sys
import csv
import argparse
from collections import OrderedDict

def main(args):

    all_rows = []
    rows_out = OrderedDict()
    colnames = []
    num_input_files = 0
    for f in args.csvfile:
        row_set = set([])
        n = 0
        with f as csv_file:
            num_input_files += 1
            vitalreader = csv.reader(csv_file, delimiter=',')
            #colnames.update(set(vitalreader.fieldnames))
            #for field in vitalreader.fieldnames:
            #    if not field in colnames:
            #        colnames.append(field)
            for row in vitalreader:
                n += 1
                if (n == 1):
                    if (num_input_files == 1):
                        cells = row[0:]
                    else:
                        cells = row[1:]
                    for col in cells:
                        colnames.append(col)
                    continue

                r = repr(row)
                is_dupe = r in row_set
                if (not is_dupe):
                    if not row[0] in rows_out:
                        rows_out[row[0]] = row[1:]
                    else:
                        rows_out[row[0]].extend(row[1:])
                    row_set.add(r)

    for i, col in enumerate(colnames):
        end = "\n" if (i == len(colnames) - 1) else ","
        print(col, end=end)

    for y, idx in enumerate(rows_out):
        print("{}".format(str(idx)),end=",") 
        for x, colval in enumerate(rows_out[idx]):
            end = "\n" if (x == (len(colnames)*num_input_files) - 1) else ","
            print(colval, end=end)
        print("")
        
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('csvfile', type=argparse.FileType('r'), nargs='+',
                        help=".CSV input filename")

    args = parser.parse_args()

    main(args)

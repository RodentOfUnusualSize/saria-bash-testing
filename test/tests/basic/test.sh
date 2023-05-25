#!/bin/bash

########################################################################
#                                                                      #
# This file is part of Saria’s BASH testing library.                   #
#                                                                      #
# Saria’s BASH testing library is free software: you can redistribute  #
# it and/or modify it under the terms of the GNU General Public        #
# License as published by the Free Software Foundation, either         #
# version 3 of the License, or (at your option) any later version.     #
#                                                                      #
# Saria’s BASH testing library is distributed in the hope that it will #
# be useful, but WITHOUT ANY WARRANTY; without even the implied        #
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.     #
# See the GNU General Public License for more details.                 #
#                                                                      #
# You should have received a copy of the GNU General Public License    #
# along with Saria’s BASH testing library.                             #
# If not, see <https://www.gnu.org/licenses/>.                         #
#                                                                      #
########################################################################

set -e
set -u
set -o pipefail


# Set up files to store output.

stdout=$(mktemp)
stderr=$(mktemp)

readonly stdout
readonly stderr


# Run the test script.

passed=true

if ! ./script.sh >"${stdout}" 2>"${stderr}" ; then
	passed=false
fi


# Check the output.

output=$(mktemp)
readonly output

if ! diff expected-stdout.txt "${stdout}" >"${output}" ; then
	printf 'stdout diff:\n'
	cat "${output}"
	passed=false
fi
if ! diff expected-stderr.txt "${stderr}" >"${output}" ; then
	printf 'stderr diff:\n'
	cat "${output}"
	passed=false
fi


# Report.

${passed}

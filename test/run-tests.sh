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

########################################################################
#                                                                      #
# For (I hope) obvious reasons, this testing script cannot itself use  #
# the testing library it is testing to do its tests.                   #
#                                                                      #
# So we have to implement a rudimentary testing library right here in  #
# this testing script, to run all the testing library tests.           #
#                                                                      #
# Did I say "testing" enough yet? Testing, testing, testing!           #
#                                                                      #
########################################################################


########################################################################
#                                                                      #
# This script runs all valid tests in the tests directory, reporting   #
# whether they pass or fail.                                           #
#                                                                      #
# Valid tests are:                                                     #
#  *  named 'test.sh'                                                  #
#  *  executable                                                       #
#  *  in a sub-directory of the tests directory                        #
#     *  which has a name that                                         #
#        >  starts with a lowercase letter                             #
#        >  contains only lowercase letters, digits, and hyphen/minus  #
#        >  does not contain consecutive hyphens/minuses               #
#        >  does not end with a hyphen/minus                           #
#                                                                      #
# Tests should use their exit status to signal pass/fail.              #
#                                                                      #
# Output of successful tests is suppressed.                            #
#                                                                      #
# Output of failed tests is reported, with each line prefixed.         #
#                                                                      #
########################################################################


########################################################################
# Configuration ########################################################
########################################################################

# Path to testing library.
#
# By default, this script is meant to be run from the project root.
readonly libpath=${libpath:-saria-testing.sh}

# Directory where tests are found.
#
# By default, this script is meant to be run from the project root.
# Thus, the tests directory is configured from that perspective. If
# you want to run from another directory (or run tests somewhere else),
# set an environment variable `testsdir`.
readonly testsdir=${testsdir:-test/tests}

# Prefix prepended to failed text output.
readonly failed_test_output_prefix='  > '


########################################################################
# Sanity checks ########################################################
########################################################################

# Verify tests directory.
#
# Yes, this is subject to TOCTOU issues, but it's just a sanity check.
if [[ ! -d "${testsdir}" ]] ; then
	printf 'tests directory not found: %s\n' "${testsdir}" >&2
	exit 1
fi

# Verify the testing library file.
if [[ ! -f "${libpath}" ]] ; then
	printf 'testing library not found: %s\n' "${libpath}" >&2
	exit 1
fi


########################################################################
# Setup ################################################################
########################################################################

# The absolute path to the testing library is exported, so tests in
# subshells can use it.
SARIA_TESTING_LIB__PATH=$(realpath "${libpath}")
readonly SARIA_TESTING_LIB__PATH
export SARIA_TESTING_LIB__PATH


########################################################################
# Run tests ############################################################
########################################################################

# Set up the test counters.
declare -i pass=0
declare -i fail=0

# Create a temporary file to hold output.
output=$(mktemp)
readonly output

# Select all valid tests.
while IFS= read -r -d $'\0' test ; do
	printf 'Running test %s... ' "${test}"
	pushd "${testsdir}/${test}" >/dev/null
	if ./test.sh >"${output}" 2>&1 ; then
		(( ++pass ))
		printf '[PASS]\n'
	else
		(( ++fail ))
		printf '[FAIL]\n'
		while IFS= read -r -d $'\n' line ; do
			printf '%s%s\n' "${failed_test_output_prefix}" "${line}"
		done <"${output}"
	fi
	popd >/dev/null
done < <(find "${testsdir}" -mindepth 2 -maxdepth 2 -type f -executable -regex '.*/[a-z][a-z0-9]*\(-[a-z0-9][a-z0-9]*\)*/test.sh' -print0 | sed -z 's|^.*/\([^/]*\)/test\.sh$|\1|')


########################################################################
# Print result #########################################################
########################################################################

if (( fail == 0 )) ; then
	printf 'All tests pass (%d/%d).\n' ${pass} ${pass}
else
	printf 'Some tests failed (passed: %d; failed: %d).\n' ${pass} ${fail}
	false
fi

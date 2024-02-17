#!/bin/sh
set -e -u

: "${AWK:=awk}"
: "${YGPP:=$(cd "${0%/*}/.." && pwd -P)/ygpp}"

tests_dir=${0%/*}

command -v diff >/dev/null 2>&1 || {
	echo 'Missing diff(1) on this system.' >&2
	exit 1
}

if command -v cmp >/dev/null 2>&1
then
	check_same() { cmp -s "$1" "$2"; }
else
	check_same() { diff -q "$1" "$2" >/dev/null; }
fi

case ${NOCOLOR+0}
in
	(0) coloured_output=false ;;
	(*) coloured_output=true ;;
esac

if test -t 1
then
	STDOUT_ISATTY=true
else
	STDOUT_ISATTY=false
fi

dodiff() {
	diff -u "$1" "$2" | sed '1,2{/^[+-]\{3\} /d;}'
}

prefix_ifoutput() {
	if read -r __first_line
	then
		printf '%s\n%s\n' "${1-}" "${__first_line}"
		unset __first_line
		cat
	fi
}

if ${coloured_output?} && command -v colordiff >/dev/null 2>&1
then
	showdiff() { dodiff "$@" | colordiff; }
else
	showdiff() { dodiff "$@"; }
fi

tmpdir=$(mktemp -d)
test -d "${tmpdir-}" || exit 1
trap 'rm -R -f "${tmpdir}"' EXIT

failed_tests=0

for testdir in "${tests_dir}"/*
do
	test -d "${testdir}" || continue

	if test -e "${testdir}/skip"
	then
		if ${coloured_output?}
		then
			printf '[\033[1;37mSKIP\033[0m]'
		else
			printf '[SKIP]'
		fi
		printf ' %s\n' "${testdir##*/}"

		continue
	fi

	${STDOUT_ISATTY?} && printf '[....] %s' "${testdir##*/}"

	test_out="${tmpdir:?}/${testdir##*/}.stdout"
	test_err="${tmpdir:?}/${testdir##*/}.stderr"

	test_rc=0
	{
		set -a
		#shellcheck source=/dev/null
		test -e "${testdir:?}/env" && . "${testdir:?}/env"
		NOCOLOR=1 ${AWK} -f "${YGPP:?}" "${testdir:?}/input"
	} >"${test_out:?}" 2>"${test_err:?}" || test_rc=$?


	if test -e "${testdir:?}/expect.out"
	then
		expect_out="${testdir:?}/expect.out"
	else
		expect_out=/dev/null
	fi

	if test -e "${testdir:?}/expect.err"
	then
		expect_err="${testdir:?}/expect.err"
	else
		expect_err=/dev/null
	fi

	if test -s "${testdir:?}/expect.status"
	then
		read -r expect_status <"${testdir:?}/expect.status"
	else
		expect_status=0
	fi

	if
		test $((test_rc)) -eq $((expect_status)) \
		&& check_same "${expect_out}" "${test_out}" \
		&& check_same "${expect_err}" "${test_err}"
	then
		${STDOUT_ISATTY?} && printf '\r'
		if ${coloured_output?}
		then
			printf '[\033[32m OK \033[0m]'
		else
			printf '[ OK ]'
		fi
		printf ' %s\n' "${testdir##*/}"
	else
		: $((failed_tests+=1))

		${STDOUT_ISATTY?} && printf '\r'
		if ${coloured_output?}
		then
			printf '[\033[1;91mFAIL\033[0m]'
		else
			printf '[FAIL]'
		fi
		printf ' %s\n' "${testdir##*/}"

		showdiff "${expect_out:?}" "${test_out:?}" \
		| prefix_ifoutput 'stdout:'
		showdiff "${expect_err:?}" "${test_err:?}" \
		| prefix_ifoutput 'stderr:'
	fi
done

# exit 0 if all tests succeeded
test $((failed_tests)) -eq 0

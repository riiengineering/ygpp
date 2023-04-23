#!/bin/sh
set -e -u

: "${AWK:=awk}"
: "${YGPP:=$(cd "${0%/*}/.." && pwd -P)/ygpp}"

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

if ${coloured_output?} && command -v colordiff >/dev/null 2>&1
then
	showdiff() { dodiff "$@" | colordiff; }
else
	showdiff() { dodiff "$@"; }
fi

tests_dir=${0%/*}

tmpdir=$(mktemp -d)
test -d "${tmpdir-}" || exit 1
trap 'rm -R -f "${tmpdir}"' EXIT

failed_tests=0

for testdir in "${tests_dir}"/*
do
	test -d "${testdir}" || continue

	${STDOUT_ISATTY?} && printf '[....] %s' "${testdir##*/}"

	test_out="${tmpdir:?}/${testdir##*/}.stdout"
	test_err="${tmpdir:?}/${testdir##*/}.stderr"

	test_rc=0
	{
		set -a
		#shellcheck source=/dev/null
		test -e "${testdir:?}/env" && . "${testdir:?}/env"
		${AWK} -f "${YGPP:?}" "${testdir:?}/input"
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
		&& cmp -s "${expect_out}" "${test_out}" \
		&& cmp -s "${expect_err}" "${test_err}"
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
		| {
			if read -r _first_line
			then
				printf 'stdout:\n%s\n' "${_first_line}"
				unset _first_line
				cat
			fi
		}

		showdiff "${expect_err:?}" "${test_err:?}" \
		| {
			if read -r _first_line
			then
				printf 'stderr:\n%s\n' "${_first_line}"
				unset _first_line
				cat
			fi
		}
	fi
done

# exit 0 if all tests succeeded
test $((failed_tests)) -eq 0

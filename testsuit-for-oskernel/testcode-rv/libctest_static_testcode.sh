#!/glibc/busybox sh

echo "------ LIBCTEST STATIC TEST START ------"

set -ex

./entry-static.exe argv
./entry-static.exe basename
./entry-static.exe clocale_mbfuncs
./entry-static.exe clock_gettime
./entry-static.exe dirname
./entry-static.exe env
./entry-static.exe fdopen
./entry-static.exe fnmatch
./entry-static.exe fscanf
./entry-static.exe fwscanf
./entry-static.exe iconv_open
./entry-static.exe inet_pton
./entry-static.exe mbc
./entry-static.exe memstream
# ./entry-static.exe pthread_cancel_points
./entry-static.exe pthread_cancel
./entry-static.exe pthread_cond
./entry-static.exe pthread_tsd
./entry-static.exe qsort
./entry-static.exe random
./entry-static.exe search_hsearch
./entry-static.exe search_insque
./entry-static.exe search_lsearch
./entry-static.exe search_tsearch
./entry-static.exe setjmp
./entry-static.exe snprintf

# ./entry-static.exe socket

./entry-static.exe sscanf
./entry-static.exe sscanf_long
./entry-static.exe stat
./entry-static.exe strftime
./entry-static.exe string
./entry-static.exe string_memcpy
./entry-static.exe string_memmem
./entry-static.exe string_memset
./entry-static.exe string_strchr
./entry-static.exe string_strcspn
./entry-static.exe string_strstr
./entry-static.exe strptime
./entry-static.exe strtod
./entry-static.exe strtod_simple
./entry-static.exe strtof
./entry-static.exe strtol
./entry-static.exe strtold
./entry-static.exe swprintf
./entry-static.exe tgmath
./entry-static.exe time
./entry-static.exe tls_align
./entry-static.exe udiv
./entry-static.exe ungetc
./entry-static.exe utime
./entry-static.exe wcsstr
./entry-static.exe wcstol
./entry-static.exe daemon_failure
./entry-static.exe dn_expand_empty
./entry-static.exe dn_expand_ptr_0
./entry-static.exe fflush_exit
./entry-static.exe fgets_eof
./entry-static.exe fgetwc_buffering
./entry-static.exe fpclassify_invalid_ld80
./entry-static.exe ftello_unflushed_append
./entry-static.exe getpwnam_r_crash
./entry-static.exe getpwnam_r_errno
./entry-static.exe iconv_roundtrips
./entry-static.exe inet_ntop_v4mapped
./entry-static.exe inet_pton_empty_last_field
./entry-static.exe iswspace_null
./entry-static.exe lrand48_signextend
./entry-static.exe lseek_large
./entry-static.exe malloc_0
./entry-static.exe mbsrtowcs_overflow
./entry-static.exe memmem_oob_read
./entry-static.exe memmem_oob
./entry-static.exe mkdtemp_failure
./entry-static.exe mkstemp_failure
./entry-static.exe printf_1e9_oob
./entry-static.exe printf_fmt_g_round
./entry-static.exe printf_fmt_g_zeros
./entry-static.exe printf_fmt_n

./entry-static.exe pthread_robust_detach
# ./entry-static.exe pthread_cancel_sem_wait
./entry-static.exe pthread_cond_smasher
./entry-static.exe pthread_condattr_setclock
./entry-static.exe pthread_exit_cancel
./entry-static.exe pthread_once_deadlock
./entry-static.exe pthread_rwlock_ebusy

./entry-static.exe putenv_doublefree
./entry-static.exe regex_backref_0
./entry-static.exe regex_bracket_icase
./entry-static.exe regex_ere_backref
./entry-static.exe regex_escaped_high_byte
./entry-static.exe regex_negated_range
./entry-static.exe regexec_nosub
./entry-static.exe rewind_clear_error
./entry-static.exe rlimit_open_files
./entry-static.exe scanf_bytes_consumed
./entry-static.exe scanf_match_literal_eof
./entry-static.exe scanf_nullbyte_char
./entry-static.exe setvbuf_unget
./entry-static.exe sigprocmask_internal
./entry-static.exe sscanf_eof
./entry-static.exe statvfs
./entry-static.exe strverscmp
./entry-static.exe syscall_sign_extend
./entry-static.exe uselocale_0
./entry-static.exe wcsncpy_read_overflow
./entry-static.exe wcsstr_false_negative

set +ex

echo "------ LIBCTEST STATIC TEST END ------"

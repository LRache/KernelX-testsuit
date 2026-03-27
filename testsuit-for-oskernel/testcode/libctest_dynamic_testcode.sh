#!/glibc/busybox sh

set -ex

./entry-dynamic.exe argv
./entry-dynamic.exe basename
./entry-dynamic.exe clocale_mbfuncs
./entry-dynamic.exe clock_gettime
./entry-dynamic.exe dirname
./entry-dynamic.exe dlopen
./entry-dynamic.exe env
./entry-dynamic.exe fdopen
./entry-dynamic.exe fnmatch
./entry-dynamic.exe fscanf
./entry-dynamic.exe fwscanf
./entry-dynamic.exe iconv_open
./entry-dynamic.exe inet_pton
./entry-dynamic.exe mbc
./entry-dynamic.exe memstream

# ./entry-dynamic.exe pthread_cancel_points
# ./entry-dynamic.exe pthread_cancel
# ./entry-dynamic.exe pthread_cond
# ./entry-dynamic.exe pthread_tsd

./entry-dynamic.exe qsort
./entry-dynamic.exe random
./entry-dynamic.exe search_hsearch
./entry-dynamic.exe search_insque
./entry-dynamic.exe search_lsearch
./entry-dynamic.exe search_tsearch

# ./entry-dynamic.exe sem_init

./entry-dynamic.exe setjmp
./entry-dynamic.exe snprintf

# ./entry-dynamic.exe socket

./entry-dynamic.exe sscanf
./entry-dynamic.exe sscanf_long
./entry-dynamic.exe stat
./entry-dynamic.exe strftime
./entry-dynamic.exe string
./entry-dynamic.exe string_memcpy
./entry-dynamic.exe string_memmem
./entry-dynamic.exe string_memset
./entry-dynamic.exe string_strchr
./entry-dynamic.exe string_strcspn
./entry-dynamic.exe string_strstr
./entry-dynamic.exe strptime
./entry-dynamic.exe strtod
./entry-dynamic.exe strtod_simple
./entry-dynamic.exe strtof
./entry-dynamic.exe strtol
./entry-dynamic.exe strtold
./entry-dynamic.exe swprintf
./entry-dynamic.exe tgmath
./entry-dynamic.exe time

# ./entry-dynamic.exe tls_init

./entry-dynamic.exe tls_local_exec
./entry-dynamic.exe udiv
./entry-dynamic.exe ungetc
./entry-dynamic.exe utime
./entry-dynamic.exe wcsstr
./entry-dynamic.exe wcstol
./entry-dynamic.exe daemon_failure
./entry-dynamic.exe dn_expand_empty
./entry-dynamic.exe dn_expand_ptr_0
./entry-dynamic.exe fflush_exit
./entry-dynamic.exe fgets_eof
./entry-dynamic.exe fgetwc_buffering
./entry-dynamic.exe fpclassify_invalid_ld80
./entry-dynamic.exe ftello_unflushed_append
./entry-dynamic.exe getpwnam_r_crash
./entry-dynamic.exe getpwnam_r_errno
./entry-dynamic.exe iconv_roundtrips
./entry-dynamic.exe inet_ntop_v4mapped
./entry-dynamic.exe inet_pton_empty_last_field
./entry-dynamic.exe iswspace_null
./entry-dynamic.exe lrand48_signextend
./entry-dynamic.exe lseek_large
./entry-dynamic.exe malloc_0
./entry-dynamic.exe mbsrtowcs_overflow
./entry-dynamic.exe memmem_oob_read
./entry-dynamic.exe memmem_oob
./entry-dynamic.exe mkdtemp_failure
./entry-dynamic.exe mkstemp_failure
./entry-dynamic.exe printf_1e9_oob
./entry-dynamic.exe printf_fmt_g_round
./entry-dynamic.exe printf_fmt_g_zeros
./entry-dynamic.exe printf_fmt_n

# ./entry-dynamic.exe pthread_robust_detach
# ./entry-dynamic.exe pthread_cond_smasher
# ./entry-dynamic.exe pthread_condattr_setclock
# ./entry-dynamic.exe pthread_exit_cancel
# ./entry-dynamic.exe pthread_once_deadlock
# ./entry-dynamic.exe pthread_rwlock_ebusy

./entry-dynamic.exe putenv_doublefree
./entry-dynamic.exe regex_backref_0
./entry-dynamic.exe regex_bracket_icase
./entry-dynamic.exe regex_ere_backref
./entry-dynamic.exe regex_escaped_high_byte
./entry-dynamic.exe regex_negated_range
./entry-dynamic.exe regexec_nosub
./entry-dynamic.exe rewind_clear_error
./entry-dynamic.exe rlimit_open_files
./entry-dynamic.exe scanf_bytes_consumed
./entry-dynamic.exe scanf_match_literal_eof
./entry-dynamic.exe scanf_nullbyte_char
./entry-dynamic.exe setvbuf_unget
./entry-dynamic.exe sigprocmask_internal
./entry-dynamic.exe sscanf_eof
./entry-dynamic.exe statvfs
./entry-dynamic.exe strverscmp
./entry-dynamic.exe syscall_sign_extend

# ./entry-dynamic.exe tls_get_new_dtv

./entry-dynamic.exe uselocale_0
./entry-dynamic.exe wcsncpy_read_overflow
./entry-dynamic.exe wcsstr_false_negative